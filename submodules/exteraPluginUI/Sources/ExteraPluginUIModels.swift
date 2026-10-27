import Foundation

public enum ExteraPluginSource: Equatable {
    case verified
    case unknown
}

public enum ExteraCriticalPermission: String, CaseIterable {
    case payments
    case chatManagement
    case giftUpgrade

    public var title: String {
        switch self {
        case .payments:
            return exteraPluginsString("Extera.Plugins.Consent.Permission.Payments")
        case .chatManagement:
            return exteraPluginsString("Extera.Plugins.Consent.Permission.ChatManagement")
        case .giftUpgrade:
            return exteraPluginsString("Extera.Plugins.Consent.Permission.GiftUpgrade")
        }
    }

    public var explanation: String {
        switch self {
        case .payments:
            return exteraPluginsString("Extera.Plugins.Consent.Payments.Hint")
        case .chatManagement:
            return exteraPluginsString("Extera.Plugins.Consent.ChatManagement.Hint")
        case .giftUpgrade:
            return exteraPluginsString("Extera.Plugins.Consent.GiftUpgrade.Hint")
        }
    }
}

public struct ExteraPluginUIDescriptor: Equatable {
    public let id: String
    public let name: String
    public let version: String
    public let author: String
    public let source: ExteraPluginSource
    public let criticalPermissions: [ExteraCriticalPermission]
    public var enabled: Bool
    public var safeModeTriggered: Bool

    public init(id: String, name: String, version: String, author: String, source: ExteraPluginSource, criticalPermissions: [ExteraCriticalPermission], enabled: Bool, safeModeTriggered: Bool) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.source = source
        self.criticalPermissions = criticalPermissions
        self.enabled = enabled
        self.safeModeTriggered = safeModeTriggered
    }
}

public enum ExteraAnalyzerSeverity: String {
    case critical
    case dangerous
    case caution
}

public struct ExteraAnalyzerFinding {
    public let category: String
    public let level: ExteraAnalyzerSeverity
    public let notes: [String]

    public init(category: String, level: ExteraAnalyzerSeverity, notes: [String]) {
        self.category = category
        self.level = level
        self.notes = notes
    }
}

public struct ExteraAnalyzerReport {
    public let pluginName: String
    public let source: ExteraPluginSource
    public let findings: [ExteraAnalyzerFinding]
    public let blocking: Bool

    public init(pluginName: String, source: ExteraPluginSource, findings: [ExteraAnalyzerFinding], blocking: Bool) {
        self.pluginName = pluginName
        self.source = source
        self.findings = findings
        self.blocking = blocking
    }
}

public struct ExteraSensitiveRequest {
    public let pluginId: String
    public let pluginName: String
    public let permission: ExteraCriticalPermission

    public init(pluginId: String, pluginName: String, permission: ExteraCriticalPermission) {
        self.pluginId = pluginId
        self.pluginName = pluginName
        self.permission = permission
    }
}

public enum ExteraCatalogSorting: String, CaseIterable {
    case recentlyUpdated
    case mostViewed
    case newest
    case byName

    public var title: String {
        switch self {
        case .recentlyUpdated:
            return exteraPluginsString("Extera.Plugins.Catalog.Sorting.RecentlyUpdated")
        case .mostViewed:
            return exteraPluginsString("Extera.Plugins.Catalog.Sorting.MostViewed")
        case .newest:
            return exteraPluginsString("Extera.Plugins.Catalog.Sorting.Newest")
        case .byName:
            return exteraPluginsString("Extera.Plugins.Catalog.Sorting.ByName")
        }
    }
}

public struct ExteraCatalogEntry {
    public let name: String
    public let version: String
    public let author: String
    public let isNew: Bool
    public let isVerified: Bool

    public init(name: String, version: String, author: String, isNew: Bool, isVerified: Bool) {
        self.name = name
        self.version = version
        self.author = author
        self.isNew = isNew
        self.isVerified = isVerified
    }
}

public struct ExteraPluginLogEntry {
    public let timestamp: Date
    public let text: String

    public init(timestamp: Date, text: String) {
        self.timestamp = timestamp
        self.text = text
    }
}
