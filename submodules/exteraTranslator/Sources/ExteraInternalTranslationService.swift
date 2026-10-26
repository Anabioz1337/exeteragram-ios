import Foundation
import SwiftSignalKit
import TelegramCore

/// Serves the existing local-translation pipeline (`enableLocalIfPossible`) from
/// the extera translator, so chat translation works without a premium
/// subscription whenever the extera mode is enabled.
public final class ExteraInternalTranslationService: ExperimentalInternalTranslationService {
    public func translate(texts: [AnyHashable: String], fromLang: String, toLang: String) -> Signal<[AnyHashable: String]?, NoError> {
        guard !texts.isEmpty else {
            return .single([:])
        }

        let provider = ExteraTranslatorSettings.shared.current.provider
        let fromLanguage = fromLang == "auto" ? nil : exteraProviderLanguageCode(fromLang)
        let toLanguage = exteraProviderLanguageCode(toLang)

        let perMessageSignals: [Signal<(AnyHashable, ExteraTranslationResult?), NoError>] = texts.map { messageId, messageText in
            exteraTranslateText(
                text: messageText,
                provider: provider,
                fromLanguage: fromLanguage,
                toLanguage: toLanguage
            )
            |> map { result -> (AnyHashable, ExteraTranslationResult?) in
                return (messageId, result)
            }
            |> `catch` { _ -> Signal<(AnyHashable, ExteraTranslationResult?), NoError> in
                return .single((messageId, nil))
            }
        }

        return combineLatest(perMessageSignals)
        |> map { pairs -> [AnyHashable: String]? in
            var resultTexts: [AnyHashable: String] = [:]
            for (messageId, result) in pairs {
                if let result {
                    resultTexts[messageId] = result.text
                }
            }
            return resultTexts
        }
    }
}

/// Installed when the extera free-translation mode is on; `nil` otherwise.
public func exteraInternalTranslationServiceIfEnabled() -> ExperimentalInternalTranslationService? {
    if ExteraTranslatorSettings.shared.current.enabled {
        return ExteraInternalTranslationService()
    }
    return nil
}
