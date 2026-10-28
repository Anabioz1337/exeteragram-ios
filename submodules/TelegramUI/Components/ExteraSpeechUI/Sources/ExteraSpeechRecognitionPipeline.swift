import Foundation
import SwiftSignalKit
import TelegramCore
import AccountContext
import TelegramUIPreferences
import ConvertOpusToAAC
import ExteraSpeech

public enum ExteraVoiceMessageTranscriptionOutcome: Equatable {
    case transcript(String)
    case failure
}

/// Full transcription path for one voice message: local resource fetch, Opus decode,
/// offline recognition in the configured language, and optional AI text refinement.
///
/// Nothing is stored or presented here — the calling bubble keeps its own state machine.
public func exteraVoiceMessageTranscriptionSignal(
    context: AccountContext,
    mediaFile: TelegramMediaFile,
    settings: ExteraSpeechSettings,
    deviceLanguageCode: String
) -> Signal<ExteraVoiceMessageTranscriptionOutcome, NoError> {
    let resourceData = context.engine.resources.data(id: EngineMediaResource.Id(mediaFile.resource.id))
        |> take(1)

    return resourceData
    |> mapToSignal { data -> Signal<ExteraVoiceMessageTranscriptionOutcome, NoError> in
        guard data.isComplete else {
            return .single(.failure)
        }
        return convertOpusToAAC(sourcePath: data.path, allocateTempFile: {
            return EngineTempBox.shared.tempFile(fileName: "audio.m4a").path
        })
    }
    |> mapToSignal { convertedPath -> Signal<ExteraVoiceMessageTranscriptionOutcome, NoError> in
        guard let convertedPath = convertedPath else {
            return .single(.failure)
        }
        let localeIdentifier = resolveSpeechLocaleIdentifier(
            languageIdentifier: settings.languageIdentifier,
            deviceLanguageCode: deviceLanguageCode
        )
        return transcribeAudioFileOffline(path: convertedPath, localeIdentifier: localeIdentifier)
        |> mapToSignal { transcription -> Signal<ExteraVoiceMessageTranscriptionOutcome, NoError> in
            guard let transcription = transcription else {
                return .single(.failure)
            }
            let trimmedText = transcription.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else {
                return .single(.failure)
            }
            if settings.useTextCorrection, let correctionService = registeredTranscriptCorrectionService() {
                let primaryLanguageCode = String(localeIdentifier.prefix(while: { $0 != "-" }))
                return correctionService.correctedTranscript(text: trimmedText, sourceLanguageCode: primaryLanguageCode)
                |> map { correctedText -> ExteraVoiceMessageTranscriptionOutcome in
                    if let correctedText = correctedText, !correctedText.isEmpty {
                        return .transcript(correctedText)
                    } else {
                        return .transcript(trimmedText)
                    }
                }
            } else {
                return .single(.transcript(trimmedText))
            }
        }
    }
}
