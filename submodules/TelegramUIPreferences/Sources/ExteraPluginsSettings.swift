import Foundation
import TelegramCore
import SwiftSignalKit

public struct InstalledExteraPlugin: Codable, Equatable {
    public let id: String
    public let name: String
    public let version: String
    public let author: String
    public let sourceCode: String
    public var enabled: Bool

    public init(id: String, name: String, version: String, author: String, sourceCode: String, enabled: Bool) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.sourceCode = sourceCode
        self.enabled = enabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.id = try container.decode(String.self, forKey: "id")
        self.name = try container.decodeIfPresent(String.self, forKey: "name") ?? ""
        self.version = try container.decodeIfPresent(String.self, forKey: "version") ?? "1.0"
        self.author = try container.decodeIfPresent(String.self, forKey: "author") ?? ""
        self.sourceCode = try container.decodeIfPresent(String.self, forKey: "sourceCode") ?? ""
        self.enabled = (try container.decodeIfPresent(Int32.self, forKey: "enabled") ?? 1) != 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(self.id, forKey: "id")
        try container.encode(self.name, forKey: "name")
        try container.encode(self.version, forKey: "version")
        try container.encode(self.author, forKey: "author")
        try container.encode(self.sourceCode, forKey: "sourceCode")
        try container.encode((self.enabled ? 1 : 0) as Int32, forKey: "enabled")
    }

    public static func ==(lhs: InstalledExteraPlugin, rhs: InstalledExteraPlugin) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.version == rhs.version && lhs.author == rhs.author && lhs.sourceCode == rhs.sourceCode && lhs.enabled == rhs.enabled
    }
}

public struct ExteraPluginsSettings: Codable, Equatable {
    public let plugins: [InstalledExteraPlugin]

    public static var defaultSettings: ExteraPluginsSettings {
        return ExteraPluginsSettings(plugins: [])
    }

    public init(plugins: [InstalledExteraPlugin]) {
        self.plugins = plugins
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.plugins = try container.decodeIfPresent([InstalledExteraPlugin].self, forKey: "plugins") ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(self.plugins, forKey: "plugins")
    }

    public static func ==(lhs: ExteraPluginsSettings, rhs: ExteraPluginsSettings) -> Bool {
        return lhs.plugins == rhs.plugins
    }

    public func withUpdatedEnabled(_ pluginId: String, _ enabled: Bool) -> ExteraPluginsSettings {
        return ExteraPluginsSettings(plugins: self.plugins.map { plugin in
            return plugin.id == pluginId ? InstalledExteraPlugin(id: plugin.id, name: plugin.name, version: plugin.version, author: plugin.author, sourceCode: plugin.sourceCode, enabled: enabled) : plugin
        })
    }

    public func withAdded(_ plugin: InstalledExteraPlugin) -> ExteraPluginsSettings {
        guard !self.plugins.contains(where: { $0.id == plugin.id }) else {
            return self
        }
        return ExteraPluginsSettings(plugins: self.plugins + [plugin])
    }

    public func withReplaced(_ plugin: InstalledExteraPlugin) -> ExteraPluginsSettings {
        guard self.plugins.contains(where: { $0.id == plugin.id }) else {
            return self.withAdded(plugin)
        }
        return ExteraPluginsSettings(plugins: self.plugins.map { $0.id == plugin.id ? plugin : $0 })
    }

    public func withRemoved(_ pluginId: String) -> ExteraPluginsSettings {
        return ExteraPluginsSettings(plugins: self.plugins.filter { $0.id != pluginId })
    }

    public func enabledPlugins() -> [InstalledExteraPlugin] {
        return self.plugins.filter { $0.enabled }
    }
}

public func updateExteraPluginsSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraPluginsSettings) -> ExteraPluginsSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraPluginsSettings, { entry in
            let currentSettings: ExteraPluginsSettings
            if let entry = entry?.get(ExteraPluginsSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = .defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}

public func exteraPluginsSettings(accountManager: AccountManager<TelegramAccountManagerTypes>) -> Signal<ExteraPluginsSettings, NoError> {
    return accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraPluginsSettings])
    |> map { sharedData -> ExteraPluginsSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.exteraPluginsSettings]?.get(ExteraPluginsSettings.self) ?? .defaultSettings
    }
}
