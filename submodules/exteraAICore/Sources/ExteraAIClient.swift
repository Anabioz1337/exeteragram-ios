import Foundation

public enum ExteraAIRequestFailure: Error, Equatable {
    case http(status: Int)
    case network
    case parse
    case emptyResponse
}

public enum ExteraAIStreamEvent {
    case reasoning(String)
    case content(String)
}

public struct ExteraAIChatMessage: Equatable {
    let role: String
    let content: String

    init(role: String, content: String) {
        self.role = role
        self.content = content
    }

    public static func system(_ content: String) -> ExteraAIChatMessage {
        return ExteraAIChatMessage(role: "system", content: content)
    }

    public static func user(_ content: String) -> ExteraAIChatMessage {
        return ExteraAIChatMessage(role: "user", content: content)
    }

    public static func assistant(_ content: String) -> ExteraAIChatMessage {
        return ExteraAIChatMessage(role: "assistant", content: content)
    }
}

struct ExteraAIChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let stream: Bool
    let temperature: Double?
    let reasoningEffort: String?

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case stream
        case temperature
        case reasoningEffort = "reasoning_effort"
    }
}

struct ExteraAIChatResponse: Decodable {
    struct Delta: Decodable {
        let content: String?
        let reasoning: String?

        enum CodingKeys: String, CodingKey {
            case content
            case reasoning
            case reasoningContent = "reasoning_content"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.content = try container.decodeIfPresent(String.self, forKey: .content)
            self.reasoning = try container.decodeIfPresent(String.self, forKey: .reasoning)
                ?? container.decodeIfPresent(String.self, forKey: .reasoningContent)
        }
    }

    struct MessagePayload: Decodable {
        let content: String?
    }

    struct Choice: Decodable {
        let delta: Delta?
        let message: MessagePayload?
    }

    let choices: [Choice]
}

final class ExteraAIChatClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    static func endpoint(for service: ExteraAIServiceConfig) -> URL? {
        let trimmed = service.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed), components.host != nil else {
            return nil
        }
        let path = components.path
        if !path.hasSuffix("/chat/completions") {
            components.path = (path.hasSuffix("/") ? path : path + "/") + "chat/completions"
        }
        return components.url
    }

    private static func requestBody(service: ExteraAIServiceConfig, messages: [ExteraAIChatMessage], settings: ExteraAIGenerationSettings, stream: Bool) throws -> Data {
        let request = ExteraAIChatRequest(
            model: service.model,
            messages: messages.map { ExteraAIChatRequest.Message(role: $0.role, content: $0.content) },
            stream: stream,
            temperature: settings.temperature,
            reasoningEffort: settings.showReasoningTokens ? "medium" : nil
        )
        return try JSONEncoder().encode(request)
    }

    private static func urlRequest(service: ExteraAIServiceConfig, body: Data) throws -> URLRequest {
        guard let endpoint = Self.endpoint(for: service) else {
            throw ExteraAIRequestFailure.parse
        }
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !service.apiKey.isEmpty {
            urlRequest.setValue("Bearer \(service.apiKey)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.timeoutInterval = 60.0
        return urlRequest
    }

    /// Full OpenAI-compatible chat turn: a system message plus alternating history.
    func chatStream(service: ExteraAIServiceConfig, messages: [ExteraAIChatMessage], settings: ExteraAIGenerationSettings) -> AsyncThrowingStream<ExteraAIStreamEvent, Error> {
        let session = self.session
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let body = try Self.requestBody(service: service, messages: messages, settings: settings, stream: settings.responseStreaming)
                    let urlRequest = try Self.urlRequest(service: service, body: body)
                    if settings.responseStreaming {
                        try await Self.stream(urlRequest: urlRequest, session: session, continuation: continuation)
                    } else {
                        try await Self.complete(urlRequest: urlRequest, session: session, continuation: continuation)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func stream(service: ExteraAIServiceConfig, system: String, user: String, settings: ExteraAIGenerationSettings) -> AsyncThrowingStream<ExteraAIStreamEvent, Error> {
        var messages: [ExteraAIChatMessage] = []
        if !system.isEmpty {
            messages.append(.system(system))
        }
        messages.append(.user(user))
        return chatStream(service: service, messages: messages, settings: settings)
    }

    private static func complete(urlRequest: URLRequest, session: URLSession, continuation: AsyncThrowingStream<ExteraAIStreamEvent, Error>.Continuation) async throws {
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw ExteraAIRequestFailure.network
        }
        guard http.statusCode == 200 else {
            throw ExteraAIRequestFailure.http(status: http.statusCode)
        }
        guard let decoded = try? JSONDecoder().decode(ExteraAIChatResponse.self, from: data) else {
            throw ExteraAIRequestFailure.parse
        }
        let content = decoded.choices.compactMap { $0.message?.content }.joined()
        if content.isEmpty {
            throw ExteraAIRequestFailure.emptyResponse
        }
        continuation.yield(.content(content))
    }

    private static func stream(urlRequest: URLRequest, session: URLSession, continuation: AsyncThrowingStream<ExteraAIStreamEvent, Error>.Continuation) async throws {
        let (bytes, response) = try await session.bytes(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw ExteraAIRequestFailure.network
        }
        if http.statusCode != 200 {
            var body = Data()
            for try await byte in bytes {
                body.append(byte)
                if body.count > 4096 {
                    break
                }
            }
            throw ExteraAIRequestFailure.http(status: http.statusCode)
        }

        var buffer = Data()
        var producedContent = false

        for try await byte in bytes {
            buffer.append(byte)
            while let newlineIndex = buffer.firstIndex(of: 0x0A) {
                let lineData = buffer[buffer.startIndex..<newlineIndex]
                buffer.removeSubrange(buffer.startIndex...newlineIndex)
                guard let line = String(data: lineData, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\r")) else {
                    continue
                }
                guard line.hasPrefix("data:") else {
                    continue
                }
                let payload = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
                if payload == "[DONE]" {
                    if !producedContent {
                        throw ExteraAIRequestFailure.emptyResponse
                    }
                    return
                }
                guard let payloadData = payload.data(using: .utf8),
                      let decoded = try? JSONDecoder().decode(ExteraAIChatResponse.self, from: payloadData),
                      let choice = decoded.choices.first else {
                    continue
                }
                guard let delta = choice.delta else {
                    continue
                }
                if let reasoning = delta.reasoning, !reasoning.isEmpty {
                    continuation.yield(.reasoning(reasoning))
                }
                if let content = delta.content, !content.isEmpty {
                    producedContent = true
                    continuation.yield(.content(content))
                }
        }

        if !producedContent {
            throw ExteraAIRequestFailure.emptyResponse
        }
    }
}
