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
import exteraSettingsCore

func exteraScreen(
    context: AccountContext,
    title: @escaping (ExteraStrings) -> String,
    entries: @escaping (ExteraStrings, ExteraSettings) -> [ExteraSettingsEntry],
    performAction: ((Int, ExteraSettingsArguments, PresentationData) -> Void)? = nil
) -> ViewController {
    return exteraSettingsScreen(
        context: context,
        title: { presentationData in title(exteraLocalizedStrings(presentationData)) },
        performAction: { actionId, arguments, presentationData in
            performAction?(actionId, arguments, presentationData)
        },
        entries: { presentationData, settings in
            entries(exteraLocalizedStrings(presentationData), settings)
        }
    )
}

private enum ExteraRootAction {
    static let appearance: Int = 0
    static let chats: Int = 1
    static let advanced: Int = 2
    static let details: Int = 3
    static let storage: Int = 4
    static let backup: Int = 5
}

public func exteraRootController(context: AccountContext) -> ViewController {
    return exteraScreen(
        context: context,
        title: { strings in strings.value("extera_Preferences") },
        entries: { strings, _ in
            var entries: [ExteraSettingsEntry] = []
            let section: Int32 = 0
            entries.append(.disclosure(id: Int32(ExteraRootAction.appearance), sectionId: section, title: strings.value("extera_Appearance")))
            entries.append(.disclosure(id: Int32(ExteraRootAction.chats), sectionId: section, title: strings.value("extera_Chats")))
            entries.append(.disclosure(id: Int32(ExteraRootAction.advanced), sectionId: section, title: strings.value("extera_Advanced")))
            entries.append(.disclosure(id: Int32(ExteraRootAction.details), sectionId: section, title: strings.value("extera_Details")))
            entries.append(.disclosure(id: Int32(ExteraRootAction.storage), sectionId: section, title: strings.value("extera_StorageSettings")))
            entries.append(.disclosure(id: Int32(ExteraRootAction.backup), sectionId: section, title: strings.value("extera_BackupAndRestore")))
            entries.append(.footer(id: 10, sectionId: section, text: strings.value("extera_ChatSettingsInfo")))
            return entries
        },
        performAction: { actionId, arguments, _ in
            switch actionId {
            case ExteraRootAction.appearance:
                arguments.pushController(exteraAppearanceController(context: context))
            case ExteraRootAction.chats:
                arguments.pushController(exteraChatsController(context: context))
            case ExteraRootAction.advanced:
                arguments.pushController(exteraAdvancedController(context: context))
            case ExteraRootAction.details:
                arguments.pushController(exteraDetailsController(context: context))
            case ExteraRootAction.storage:
                arguments.pushController(exteraStorageController(context: context))
            case ExteraRootAction.backup:
                arguments.pushController(exteraBackupController(context: context))
            default:
                break
            }
        }
    )
}

func exteraAppearanceController(context: AccountContext) -> ViewController {
    return exteraScreen(
        context: context,
        title: { strings in strings.value("extera_Appearance") },
        entries: { strings, _ in
            return [
                .footer(id: 0, sectionId: 0, text: strings.value("extera_ComingSoon"))
            ]
        }
    )
}

func exteraChatsController(context: AccountContext) -> ViewController {
    return exteraScreen(
        context: context,
        title: { strings in strings.value("extera_Chats") },
        entries: { strings, settings in
            let section: Int32 = 0
            return [
                .toggle(id: 0, sectionId: section, keyPath: \.disableNumberRounding, title: strings.value("extera_DisableNumberRounding"), value: settings.disableNumberRounding),
                .toggle(id: 1, sectionId: section, keyPath: \.formatTimeWithSeconds, title: strings.value("extera_FormatTimeWithSeconds"), value: settings.formatTimeWithSeconds),
                .toggle(id: 2, sectionId: section, keyPath: \.showActionTimestamps, title: strings.value("extera_ShowActionTimestamps"), value: settings.showActionTimestamps),
                .toggle(id: 3, sectionId: section, keyPath: \.addCommaAfterMention, title: strings.value("extera_AddCommaAfterMention"), value: settings.addCommaAfterMention),
                .toggle(id: 4, sectionId: section, keyPath: \.filterZalgo, title: strings.value("extera_FilterZalgo"), value: settings.filterZalgo),
                .toggle(id: 5, sectionId: section, keyPath: \.hideKeyboardOnScroll, title: strings.value("extera_HideKeyboardOnScroll"), value: settings.hideKeyboardOnScroll),
                .toggle(id: 6, sectionId: section, keyPath: \.disableJumpToNextChannel, title: strings.value("extera_DisableJumpToNextChannel"), value: settings.disableJumpToNextChannel),
                .footer(id: 7, sectionId: section, text: strings.formatted("extera_AddCommaAfterMentionInfo")),
                .footer(id: 8, sectionId: section, text: strings.formatted("extera_FilterZalgoInfo", "z̷a̶l̸g̵o̷"))
            ]
        }
    )
}

func exteraAdvancedController(context: AccountContext) -> ViewController {
    return exteraScreen(
        context: context,
        title: { strings in strings.value("extera_Advanced") },
        entries: { strings, settings in
            let speedSection: Int32 = 0
            let archiveSection: Int32 = 1
            let privacySection: Int32 = 2
            return [
                .option(id: 0, sectionId: speedSection, keyPath: \.downloadSpeedBoost, title: strings.value("extera_DownloadSpeedBoost"), value: settings.downloadSpeedBoost, optionValues: [0, 2, 4], optionTitles: [strings.value("extera_OptionOff"), strings.value("extera_Boost2x"), strings.value("extera_Boost4x")]),
                .toggle(id: 1, sectionId: speedSection, keyPath: \.uploadSpeedBoost, title: strings.value("extera_UploadSpeedBoost"), value: settings.uploadSpeedBoost),
                .footer(id: 2, sectionId: speedSection, text: strings.value("extera_SpeedBoostInfo")),
                .toggle(id: 3, sectionId: archiveSection, keyPath: \.archiveOnPull, title: strings.value("extera_ArchiveOnPull"), value: settings.archiveOnPull),
                .toggle(id: 4, sectionId: archiveSection, keyPath: \.disableUnarchiveSwipe, title: strings.value("extera_DisableUnarchiveSwipe"), value: settings.disableUnarchiveSwipe),
                .footer(id: 5, sectionId: archiveSection, text: strings.value("extera_DisableUnarchiveSwipeInfo")),
                .toggle(id: 6, sectionId: privacySection, keyPath: \.hidePhoneNumber, title: strings.value("extera_HidePhoneNumber"), value: settings.hidePhoneNumber),
                .option(id: 7, sectionId: privacySection, keyPath: \.showIdAndDc, title: strings.value("extera_ShowIdAndDc"), value: settings.showIdAndDc, optionValues: [0, 1, 2], optionTitles: [strings.value("extera_OptionDefault"), strings.value("extera_OptionApi"), strings.value("extera_OptionBotApi")]),
                .footer(id: 8, sectionId: privacySection, text: strings.value("extera_ShowIdAndDcInfo"))
            ]
        }
    )
}

func exteraDetailsController(context: AccountContext) -> ViewController {
    return exteraScreen(
        context: context,
        title: { strings in strings.value("extera_Details") },
        entries: { strings, settings in
            let section: Int32 = 0
            return [
                .toggle(id: 0, sectionId: section, keyPath: \.showDetailsButton, title: strings.value("extera_ShowDetailsButton"), value: settings.showDetailsButton),
                .footer(id: 1, sectionId: section, text: strings.value("extera_DetailsInfo"))
            ]
        }
    )
}

func exteraStorageController(context: AccountContext) -> ViewController {
    return exteraScreen(
        context: context,
        title: { strings in strings.value("extera_StorageSettings") },
        entries: { strings, settings in
            let section: Int32 = 0
            return [
                .option(id: 0, sectionId: section, keyPath: \.sendPhotosQuality, title: strings.value("extera_SendPhotosQuality"), value: settings.sendPhotosQuality, optionValues: [0, 1, 2], optionTitles: [
                    strings.formatted("extera_PixelsShort", 800),
                    strings.formatted("extera_PixelsShort", 1280),
                    strings.formatted("extera_PixelsShort", 2560)
                ]),
                .footer(id: 1, sectionId: section, text: strings.value("extera_ChatSettingsInfo"))
            ]
        }
    )
}
