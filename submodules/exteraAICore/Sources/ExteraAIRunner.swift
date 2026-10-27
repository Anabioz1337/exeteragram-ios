import Foundation

public enum ExteraAIBackend: Equatable {
    case service(ExteraAIServiceConfig)
    case onDevice
}

public enum ExteraAIResolution {
    case resolved(ExteraAIBackend)
    case nothingConfigured
}

public func exteraAIResolveBackend(store: ExteraAIStore = .shared) -> ExteraAIResolution {
    let selectedId = store.selectedServiceId
    if selectedId == exteraAIOnDeviceServiceId || store.services.isEmpty {
        if exteraAIOnDeviceStatus() == .ready {
            return .resolved(.onDevice)
        }
        if let service = store.services.first {
            return .resolved(.service(service))
        }
        return .nothingConfigured
    }
    if let service = store.services.first(where: { $0.id == selectedId }) {
        return .resolved(.service(service))
    }
    if exteraAIOnDeviceStatus() == .ready {
        return .resolved(.onDevice)
    }
    return .nothingConfigured
}

public enum ExteraAIGenerationFailure: Error, Equatable {
    case request(ExteraAIRequestFailure)
    case onDeviceUnavailable
}

public func exteraAIGenerate(
    backend: ExteraAIBackend,
    settings: ExteraAIGenerationSettings,
    role: ExteraAIRoleConfig?,
    action: ExteraAIActionKind,
    input: String,
    onEvent: @escaping (ExteraAIStreamEvent) -> Void
) async throws -> String {
    let system = exteraAISystemPrompt(role: role, action: action)
    switch backend {
    case .onDevice:
        do {
            return try await ExteraAIOnDeviceModel.respond(system: system, user: input, temperature: settings.temperature) { delta in
                onEvent(.content(delta))
            }
        } catch {
            throw ExteraAIGenerationFailure.onDeviceUnavailable
        }
    case let .service(service):
        let client = ExteraAIChatClient()
        do {
            var produced = ""
            for try await event in client.stream(service: service, system: system, user: input, settings: settings) {
                switch event {
                case .reasoning(let reasoning):
                    onEvent(.reasoning(reasoning))
                case .content(let content):
                    produced += content
                    onEvent(.content(content))
                }
            }
            return produced
        } catch let failure as ExteraAIRequestFailure {
            throw ExteraAIGenerationFailure.request(failure)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw ExteraAIGenerationFailure.request(.network)
        }
    }
}
