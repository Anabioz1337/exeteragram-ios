import Foundation
import SwiftSignalKit

/// Configuration of the external AI text service. Declared here so the speech pipeline
/// can hand transcripts over without knowing how the concrete provider stores it.
public struct ProviderConfig: Codable, Equatable {
    public var url: String
    public var model: String
    public var apiKey: String

    public init(url: String, model: String, apiKey: String) {
        self.url = url
        self.model = model
        self.apiKey = apiKey
    }
}

/// Post-processing seam for recognized transcripts.
///
/// The real AI-service module registers itself at startup through
/// `registerTranscriptCorrectionService(_:)`. Until something registers a working
/// implementation the pipeline keeps the raw transcript untouched, so this protocol stays
/// the single integration point between the two features.
public protocol TranscriptCorrectionService: AnyObject {
    /// Returns the refined text, or `nil` to keep the original transcript unchanged.
    func correctedTranscript(text: String, sourceLanguageCode: String) -> Signal<String?, NoError>
}

private let correctionServiceRegistry = Atomic<TranscriptCorrectionService?>(value: nil)

public func registerTranscriptCorrectionService(_ service: TranscriptCorrectionService?) {
    let _ = correctionServiceRegistry.swap(service)
}

public func registeredTranscriptCorrectionService() -> TranscriptCorrectionService? {
    return correctionServiceRegistry.with({ $0 })
}

/// Placeholder implementation for the AI module to replace with a real
/// `ProviderConfig`-backed one. It deliberately performs no work at all.
public final class PassthroughTranscriptCorrectionService: TranscriptCorrectionService {
    private let config: ProviderConfig?

    public init(config: ProviderConfig? = nil) {
        self.config = config
    }

    public func correctedTranscript(text: String, sourceLanguageCode: String) -> Signal<String?, NoError> {
        return .single(nil)
    }
}
