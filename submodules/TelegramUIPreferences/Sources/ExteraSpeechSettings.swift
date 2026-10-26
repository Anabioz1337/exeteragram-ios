import Foundation
import TelegramCore
import SwiftSignalKit

private let autoLanguageIdentifier = "auto"

public struct ExteraSpeechSettings: Codable, Equatable {
    public let isEnabled: Bool
    public let languageIdentifier: String
    public let useTextCorrection: Bool

    public static var defaultSettings: ExteraSpeechSettings {
        return ExteraSpeechSettings(isEnabled: true, languageIdentifier: autoLanguageIdentifier, useTextCorrection: false)
    }

    public init(isEnabled: Bool, languageIdentifier: String, useTextCorrection: Bool) {
        self.isEnabled = isEnabled
        self.languageIdentifier = languageIdentifier
        self.useTextCorrection = useTextCorrection
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.isEnabled = (try container.decodeIfPresent(Int32.self, forKey: "isEnabled") ?? 1) != 0
        self.languageIdentifier = try container.decodeIfPresent(String.self, forKey: "languageIdentifier") ?? autoLanguageIdentifier
        self.useTextCorrection = (try container.decodeIfPresent(Int32.self, forKey: "useTextCorrection") ?? 0) != 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode((self.isEnabled ? 1 : 0) as Int32, forKey: "isEnabled")
        try container.encode(self.languageIdentifier, forKey: "languageIdentifier")
        try container.encode((self.useTextCorrection ? 1 : 0) as Int32, forKey: "useTextCorrection")
    }

    public static func ==(lhs: ExteraSpeechSettings, rhs: ExteraSpeechSettings) -> Bool {
        return lhs.isEnabled == rhs.isEnabled && lhs.languageIdentifier == rhs.languageIdentifier && lhs.useTextCorrection == rhs.useTextCorrection
    }

    public func withUpdatedIsEnabled(_ isEnabled: Bool) -> ExteraSpeechSettings {
        return ExteraSpeechSettings(isEnabled: isEnabled, languageIdentifier: self.languageIdentifier, useTextCorrection: self.useTextCorrection)
    }

    public func withUpdatedLanguageIdentifier(_ languageIdentifier: String) -> ExteraSpeechSettings {
        return ExteraSpeechSettings(isEnabled: self.isEnabled, languageIdentifier: languageIdentifier, useTextCorrection: self.useTextCorrection)
    }

    public func withUpdatedUseTextCorrection(_ useTextCorrection: Bool) -> ExteraSpeechSettings {
        return ExteraSpeechSettings(isEnabled: self.isEnabled, languageIdentifier: self.languageIdentifier, useTextCorrection: useTextCorrection)
    }
}

public func updateExteraSpeechSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraSpeechSettings) -> ExteraSpeechSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraSpeechSettings, { entry in
            let currentSettings: ExteraSpeechSettings
            if let entry = entry?.get(ExteraSpeechSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = ExteraSpeechSettings.defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}
