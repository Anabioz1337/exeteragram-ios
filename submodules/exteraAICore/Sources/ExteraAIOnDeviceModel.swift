import Foundation

public enum ExteraAIOnDeviceStatus: Equatable {
    case ready
    case downloading
    case loading
    case unavailable
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
private func exteraAIOnDeviceSystemModelStatus() -> ExteraAIOnDeviceStatus {
    switch SystemLanguageModel.default.availability {
    case .available:
        return .ready
    case let .unavailable(reason):
        switch reason {
        case .deviceNotEligible, .modelNotReady:
            return .unavailable
        case .appleIntelligenceNotEnabled:
            return .downloading
        @unknown default:
            return .unavailable
        }
    }
}
#endif

public func exteraAIOnDeviceStatus() -> ExteraAIOnDeviceStatus {
#if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
        return exteraAIOnDeviceSystemModelStatus()
    }
#endif
    return .unavailable
}

public enum ExteraAIOnDeviceGenerationError: Error {
    case unavailable
}

public enum ExteraAIOnDeviceModel {
    public static func respond(system: String, user: String, temperature: Double?, onContent: @escaping (String) -> Void) async throws -> String {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return try await Self.respondAvailable(system: system, user: user, temperature: temperature, onContent: onContent)
        }
#endif
        throw ExteraAIOnDeviceGenerationError.unavailable
    }

#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func respondAvailable(system: String, user: String, temperature: Double?, onContent: @escaping (String) -> Void) async throws -> String {
        guard SystemLanguageModel.default.availability == .available else {
            throw ExteraAIOnDeviceGenerationError.unavailable
        }
        let instructions: Instructions
        if let temperature {
            instructions = Instructions {
                """
                \(system)
                Sample with temperature \(String(format: "%.2f", temperature)).
                """
            }
        } else {
            instructions = Instructions {
                """
                \(system)
                """
            }
        }
        let session = LanguageModelSession(instructions: instructions)
        var produced = ""
        let stream = session.streamResponse(to: user, generating: String.self)
        for try await partial in stream {
            let partialText = partial.content
            guard partialText.count > produced.count else {
                continue
            }
            let delta = String(partialText.suffix(partialText.count - produced.count))
            produced = partialText
            onContent(delta)
        }
        if produced.isEmpty {
            throw ExteraAIOnDeviceGenerationError.unavailable
        }
        return produced
    }
#endif
}
