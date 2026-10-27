import Foundation
import SwiftSignalKit
import ExteraSpeech

private let exteraAICorrectionServiceRegistration: Void = {
    registerTranscriptCorrectionService(ExteraAITranscriptCorrectionService())
}()

/// Signs the AI module up once: after that the speech pipeline routes transcripts
/// through the configured service whenever its own "use text correction" flag is on.
public func exteraAIEnsureCorrectionServiceRegistered() {
    let _ = exteraAICorrectionServiceRegistration
}

public final class ExteraAITranscriptCorrectionService: TranscriptCorrectionService {
    public init() {
    }

    public func correctedTranscript(text: String, sourceLanguageCode: String) -> Signal<String?, NoError> {
        return Signal { subscriber in
            let store = ExteraAIStore.shared
            let settings = ExteraAIGenerationSettings(
                temperature: store.generationSettings.temperature,
                showReasoningTokens: false,
                responseStreaming: false,
                responseDisplay: .showResponseOnly
            )
            let task = Task {
                guard case .resolved(let backend) = exteraAIResolveBackend(store: store) else {
                    subscriber.putCompletion()
                    return
                }
                do {
                    let result = try await exteraAIGenerate(
                        backend: backend,
                        settings: settings,
                        role: nil,
                        action: .correctPunctuation,
                        input: text,
                        onEvent: { _ in }
                    )
                    let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        subscriber.putNext(trimmed)
                    }
                    subscriber.putCompletion()
                } catch {
                    subscriber.putCompletion()
                }
            }
            return ActionDisposable {
                task.cancel()
            }
        }
    }
}
