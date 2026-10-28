import Foundation
import TelegramCore
import SwiftSignalKit
import TelegramUIPreferences

public typealias ExteraSettings = TelegramUIPreferences.ExteraSettings

public func updateExteraSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraSettings) -> ExteraSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraSettings, { entry in
            let currentSettings: ExteraSettings
            if let entry = entry?.get(ExteraSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = ExteraSettings()
            }
            return EnginePreferencesEntry(f(currentSettings))
        })
    }
}
