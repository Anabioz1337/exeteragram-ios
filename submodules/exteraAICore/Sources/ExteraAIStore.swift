import Foundation

public let exteraAIOnDeviceServiceId = "exteraAI.on-device"

public final class ExteraAIStore {
    public static let shared = ExteraAIStore()

    private let defaults: UserDefaults
    private enum Key: String, CaseIterable {
        case services = "exteraAI.services"
        case roles = "exteraAI.roles"
        case generationSettings = "exteraAI.generation"
        case selectedServiceId = "exteraAI.selectedServiceId"
        case selectedRoleId = "exteraAI.selectedRoleId"
        case replaceTelegramAI = "exteraAI.replaceTelegramAI"
    }

    private init(defaults: UserDefaults? = UserDefaults(suiteName: "exteraAI")) {
        self.defaults = defaults ?? .standard
    }

    var services: [ExteraAIServiceConfig] {
        get { return self.decoded([ExteraAIServiceConfig].self, key: Key.services) ?? [] }
        set { self.encode(newValue, key: Key.services) }
    }

    public var roles: [ExteraAIRoleConfig] {
        get { return self.decoded([ExteraAIRoleConfig].self, key: Key.roles) ?? [] }
        set { self.encode(newValue, key: Key.roles) }
    }

    public var generationSettings: ExteraAIGenerationSettings {
        get {
            return self.decoded(ExteraAIGenerationSettings.self, key: Key.generationSettings) ?? .defaultValue
        }
        set { self.encode(newValue, key: Key.generationSettings) }
    }

    public var selectedServiceId: String? {
        get { return self.defaults.string(forKey: Key.selectedServiceId.rawValue) }
        set { self.defaults.set(newValue, forKey: Key.selectedServiceId.rawValue) }
    }

    public var selectedRoleId: String? {
        get { return self.defaults.string(forKey: Key.selectedRoleId.rawValue) }
        set { self.defaults.set(newValue, forKey: Key.selectedRoleId.rawValue) }
    }

    public var replaceTelegramAI: Bool {
        get {
            if self.defaults.object(forKey: Key.replaceTelegramAI.rawValue) == nil {
                return true
            }
            return self.defaults.bool(forKey: Key.replaceTelegramAI.rawValue)
        }
        set { self.defaults.set(newValue, forKey: Key.replaceTelegramAI.rawValue) }
    }

    public var selectedService: ExteraAIServiceConfig? {
        let selectedId = self.selectedServiceId
        if selectedId == exteraAIOnDeviceServiceId {
            return nil
        }
        return self.services.first(where: { $0.id == selectedId }) ?? self.services.first
    }

    public var selectedRole: ExteraAIRoleConfig? {
        return self.roles.first(where: { $0.id == self.selectedRoleId })
    }

    private func decoded<T: Decodable>(_ type: T.Type, key: Key) -> T? {
        guard let data = self.defaults.data(forKey: key.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T, key: Key) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }
        self.defaults.set(data, forKey: key.rawValue)
    }
}
