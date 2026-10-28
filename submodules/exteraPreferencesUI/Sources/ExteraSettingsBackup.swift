import Foundation
import UIKit
import SwiftSignalKit
import Display
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext
import AlertUI
import UndoUI
import PresentationDataUtils
import LegacyMediaPickerUI
import exteraSettingsCore

private enum ExteraBackupAction {
    static let export: Int = 0
    static let apply: Int = 1
    static let reset: Int = 2
}

func exteraBackupController(context: AccountContext) -> ViewController {
    return exteraScreen(
        context: context,
        title: { strings in strings.value("extera_BackupAndRestore") },
        entries: { strings, _ in
            let section: Int32 = 0
            let managementSection: Int32 = 1
            return [
                .disclosure(id: Int32(ExteraBackupAction.export), sectionId: section, title: strings.value("extera_ExportSettings")),
                .disclosure(id: Int32(ExteraBackupAction.apply), sectionId: section, title: strings.value("extera_ApplySettings")),
                .action(id: Int32(ExteraBackupAction.reset), sectionId: managementSection, title: strings.value("extera_ResetSettings")),
                .footer(id: 10, sectionId: managementSection, text: strings.value("extera_ResetPreferencesInfo"))
            ]
        },
        performAction: { actionId, arguments, presentationData in
            switch actionId {
            case ExteraBackupAction.export:
                exteraExportSettings(context: context, presentationData: presentationData, present: arguments.presentController)
            case ExteraBackupAction.apply:
                exteraPickSettingsFile(context: context, presentationData: presentationData, present: arguments.presentController)
            case ExteraBackupAction.reset:
                exteraConfirmReset(context: context, presentationData: presentationData, present: arguments.presentController)
            default:
                break
            }
        }
    )
}

private func exteraCurrentSettings(context: AccountContext) -> Signal<ExteraSettings, NoError> {
    return context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSettings])
    |> map { sharedData in
        sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSettings]?.get(ExteraSettings.self) ?? ExteraSettings.defaultSettings
    }
}

private struct ExteraSettingsFile: Codable {
    let version: Int32
    let settings: ExteraSettings
}

private func exteraEncodeSettingsFile(_ settings: ExteraSettings) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(ExteraSettingsFile(version: 1, settings: settings))
}

private func exteraDecodeSettingsFile(_ data: Data) -> ExteraSettings? {
    if let file = try? JSONDecoder().decode(ExteraSettingsFile.self, from: data) {
        return file.settings
    }
    return try? JSONDecoder().decode(ExteraSettings.self, from: data)
}

public func exteraDecodeSettingsPayload(_ payload: String) -> ExteraSettings? {
    guard let percentDecoded = payload.removingPercentEncoding else {
        return nil
    }
    if let jsonData = percentDecoded.data(using: .utf8), let raw = try? JSONDecoder().decode(ExteraSettings.self, from: jsonData) {
        return raw
    }

    var base64 = percentDecoded.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    while base64.count % 4 != 0 {
        base64 += "="
    }
    if let data = Data(base64Encoded: base64) {
        return exteraDecodeSettingsFile(data)
    }
    return nil
}

private func exteraToast(presentationData: PresentationData, text: String, present: @escaping (ViewController) -> Void) {
    present(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: text, timeout: nil, customUndoText: nil), elevatedLayout: true, animateInAsReplacement: false, action: { _ in return true }))
}

private func exteraExportSettings(context: AccountContext, presentationData: PresentationData, present: @escaping (ViewController) -> Void) {
    let _ = (exteraCurrentSettings(context: context)
    |> take(1)
    |> deliverOnMainQueue).startStandalone(next: { settings in
        guard let data = try? exteraEncodeSettingsFile(settings) else {
            return
        }
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("exteraGram-settings.json")
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return
        }

        let picker = legacyICloudFilePicker(
            theme: presentationData.theme,
            mode: .export,
            url: url,
            documentTypes: [],
            forceDarkTheme: false,
            dismissed: {},
            completion: { _ in
                Queue.mainQueue().async {
                    exteraToast(presentationData: presentationData, text: exteraLocalizedStrings(presentationData).value("extera_SettingsSaved"), present: present)
                }
            }
        )
        present(picker)
    })
}

private func exteraPickSettingsFile(context: AccountContext, presentationData: PresentationData, present: @escaping (ViewController) -> Void) {
    let picker = legacyICloudFilePicker(
        theme: presentationData.theme,
        mode: .import,
        hasMultiselection: false,
        url: nil,
        documentTypes: ["public.json"],
        forceDarkTheme: false,
        dismissed: {},
        completion: { urls in
            guard let url = urls.first, let data = try? Data(contentsOf: url), let imported = exteraDecodeSettingsFile(data) else {
                Queue.mainQueue().async {
                    exteraToast(presentationData: presentationData, text: exteraLocalizedStrings(presentationData).value("extera_ImportFailed"), present: present)
                }
                return
            }
            Queue.mainQueue().async {
                exteraRequestApplyImportedSettings(context: context, presentationData: presentationData, imported: imported, present: present)
            }
        }
    )
    present(picker)
}

private func exteraPluralKey(_ base: String, count: Int) -> String {
    let mod10 = count % 10
    let mod100 = count % 100
    if mod10 == 1 && mod100 != 11 {
        return base + "_one"
    } else if mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14) {
        return base + "_few"
    } else if mod10 == 0 || mod10 >= 5 || (mod100 >= 12 && mod100 <= 14) {
        return base + "_many"
    }
    return base + "_other"
}

func exteraRequestApplyImportedSettings(
    context: AccountContext,
    presentationData: PresentationData,
    imported: ExteraSettings,
    present: @escaping (ViewController) -> Void,
    completion: (() -> Void)? = nil
) {
    let strings = exteraLocalizedStrings(presentationData)
    let _ = (exteraCurrentSettings(context: context)
    |> take(1)
    |> deliverOnMainQueue).startStandalone(next: { current in
        let changedCount = current.changedKeyCount(comparedTo: imported)
        let summary: String
        if changedCount == 0 {
            summary = strings.value("extera_SameSettings")
        } else {
            summary = strings.formatted(exteraPluralKey("extera_ImportChanges", count: changedCount), changedCount)
        }

        let alertController = textAlertController(
            context: context,
            updatedPresentationData: (initial: presentationData, signal: .single(presentationData)),
            title: strings.value("extera_ImportTitle"),
            text: summary,
            actions: [
                TextAlertAction(type: .genericAction, title: strings.value("extera_CancelConfirm"), action: {}),
                TextAlertAction(type: .defaultAction, title: strings.value("extera_ImportConfirm"), action: {
                    let editor = ExteraSettingsEditor(accountManager: context.sharedContext.accountManager)
                    editor.apply(imported)
                    completion?()
                    exteraToast(presentationData: presentationData, text: strings.value("extera_SettingsImported"), present: present)
                })
            ]
        )
        present(alertController)
    })
}

func exteraConfirmReset(context: AccountContext, presentationData: PresentationData, present: @escaping (ViewController) -> Void) {
    let strings = exteraLocalizedStrings(presentationData)
    let alertController = textAlertController(
        context: context,
        updatedPresentationData: (initial: presentationData, signal: .single(presentationData)),
        title: nil,
        text: strings.value("extera_ResetPreferencesInfo"),
        actions: [
            TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {}),
            TextAlertAction(type: .destructiveAction, title: strings.value("extera_ResetSettings"), action: {
                let editor = ExteraSettingsEditor(accountManager: context.sharedContext.accountManager)
                editor.reset()
                exteraToast(presentationData: presentationData, text: strings.value("extera_ResetPreferences"), present: present)
            })
        ]
    )
    present(alertController)
}
