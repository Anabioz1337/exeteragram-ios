import Foundation

public struct ExteraAIServiceConfig: Equatable, Codable, Identifiable {
    public var id: String
    public var name: String
    public var url: String
    public var model: String
    public var apiKey: String

    public init(id: String = UUID().uuidString, name: String, url: String, model: String, apiKey: String) {
        self.id = id
        self.name = name
        self.url = url
        self.model = model
        self.apiKey = apiKey
    }

    public var identity: String {
        return "\(url)|\(model)|\(apiKey)"
    }
}

public struct ExteraAIRoleConfig: Equatable, Codable, Identifiable {
    public var id: String
    public var name: String
    public var prompt: String

    public init(id: String = UUID().uuidString, name: String, prompt: String) {
        self.id = id
        self.name = name
        self.prompt = prompt
    }
}

public enum ExteraAIResponseDisplay: Equatable, Codable {
    case showResponseOnly
    case insertAsQuote
}

public struct ExteraAIGenerationSettings: Equatable, Codable {
    public var temperature: Double?
    public var showReasoningTokens: Bool
    public var responseStreaming: Bool
    public var responseDisplay: ExteraAIResponseDisplay

    public static let defaultValue = ExteraAIGenerationSettings(
        temperature: 0.7,
        showReasoningTokens: false,
        responseStreaming: true,
        responseDisplay: .insertAsQuote
    )

    public init(temperature: Double?, showReasoningTokens: Bool, responseStreaming: Bool, responseDisplay: ExteraAIResponseDisplay) {
        self.temperature = temperature
        self.showReasoningTokens = showReasoningTokens
        self.responseStreaming = responseStreaming
        self.responseDisplay = responseDisplay
    }
}

public enum ExteraAIActionKind: Equatable {
    case translate(languageName: String)
    case restyle
    case proofread
    case summarize
    case correctPunctuation

    func systemInstruction() -> String {
        switch self {
        case let .translate(languageName):
            return "Translate the following text into \(languageName). Reply with ONLY the translated text, preserving line breaks."
        case .restyle:
            return "Rewrite the following text so that it follows the tone described above. Reply with ONLY the rewritten text, preserving line breaks."
        case .proofread:
            return "Fix spelling, grammar and punctuation mistakes in the following text without changing its meaning or wording more than necessary. Reply with ONLY the corrected text, preserving line breaks."
        case .summarize:
            return "Summarize the following text concisely, keeping every important fact. Reply with ONLY the summary."
        case .correctPunctuation:
            return "Correct punctuation of this transcript, reply only with the fixed text"
        }
    }
}

func exteraAISystemPrompt(role: ExteraAIRoleConfig?, action: ExteraAIActionKind) -> String {
    if let role, !role.prompt.isEmpty {
        return role.prompt + "\n\n" + action.systemInstruction()
    } else {
        return action.systemInstruction()
    }
}

func exteraAIQuoteText(_ text: String) -> String {
    return text.components(separatedBy: "\n").map { "> \($0)" }.joined(separator: "\n")
}
