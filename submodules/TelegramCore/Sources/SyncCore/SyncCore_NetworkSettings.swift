import Postbox

public struct NetworkSettings: Codable {
    public var reducedBackupDiscoveryTimeout: Bool
    public var applicationUpdateUrlPrefix: String?
    public var backupHostOverride: String?
    public var useNetworkFramework: Bool?
    public var useExperimentalDownload: Bool?
    public var downloadSpeedBoostLevel: Int?
    public var uploadSpeedBoost: Bool?

    public static var defaultSettings: NetworkSettings {
        return NetworkSettings(reducedBackupDiscoveryTimeout: false, applicationUpdateUrlPrefix: nil, backupHostOverride: nil, useNetworkFramework: nil, useExperimentalDownload: nil, downloadSpeedBoostLevel: nil, uploadSpeedBoost: nil)
    }

    public init(reducedBackupDiscoveryTimeout: Bool, applicationUpdateUrlPrefix: String?, backupHostOverride: String?, useNetworkFramework: Bool?, useExperimentalDownload: Bool?, downloadSpeedBoostLevel: Int? = nil, uploadSpeedBoost: Bool? = nil) {
        self.reducedBackupDiscoveryTimeout = reducedBackupDiscoveryTimeout
        self.applicationUpdateUrlPrefix = applicationUpdateUrlPrefix
        self.backupHostOverride = backupHostOverride
        self.useNetworkFramework = useNetworkFramework
        self.useExperimentalDownload = useExperimentalDownload
        self.downloadSpeedBoostLevel = downloadSpeedBoostLevel
        self.uploadSpeedBoost = uploadSpeedBoost
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.reducedBackupDiscoveryTimeout = ((try? container.decode(Int32.self, forKey: "reducedBackupDiscoveryTimeout")) ?? 0) != 0
        self.applicationUpdateUrlPrefix = try? container.decodeIfPresent(String.self, forKey: "applicationUpdateUrlPrefix")
        self.backupHostOverride = try? container.decodeIfPresent(String.self, forKey: "backupHostOverride")
        self.useNetworkFramework = try container.decodeIfPresent(Bool.self, forKey: "useNetworkFramework_v2")
        self.useExperimentalDownload = try container.decodeIfPresent(Bool.self, forKey: "useExperimentalDownload_v2")
        self.downloadSpeedBoostLevel = try container.decodeIfPresent(Int.self, forKey: "downloadSpeedBoostLevel")
        self.uploadSpeedBoost = try container.decodeIfPresent(Bool.self, forKey: "uploadSpeedBoost")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode((self.reducedBackupDiscoveryTimeout ? 1 : 0) as Int32, forKey: "reducedBackupDiscoveryTimeout")
        try container.encodeIfPresent(self.applicationUpdateUrlPrefix, forKey: "applicationUpdateUrlPrefix")
        try container.encodeIfPresent(self.backupHostOverride, forKey: "backupHostOverride")
        try container.encodeIfPresent(self.useNetworkFramework, forKey: "useNetworkFramework_v2")
        try container.encodeIfPresent(self.useExperimentalDownload, forKey: "useExperimentalDownload_v2")
        try container.encodeIfPresent(self.downloadSpeedBoostLevel, forKey: "downloadSpeedBoostLevel")
        try container.encodeIfPresent(self.uploadSpeedBoost, forKey: "uploadSpeedBoost")
    }
}
