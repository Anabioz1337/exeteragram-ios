import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext
import TextFormat
import TelegramStringFormatting

private enum ExteraUpdaterStatus: Equatable {
    case idle
    case checking
    case upToDate
    case available(ExteraRelease)
    case failed
}

private enum ExteraSettingsSection: Int32 {
    case speed = 0
    case storage = 1
    case interface = 2
    case analytics = 3
    case updates = 4
    case messages = 5
    case groups = 6
}

private enum ExteraSettingsEntry: ItemListNodeEntry {
    case speedHeader(PresentationTheme, String)
    case downloadBoost(PresentationTheme, String, String)
    case ultraWarning(PresentationTheme, String)
    case uploadBoost(PresentationTheme, String, Bool)
    case storageHeader(PresentationTheme, String)
    case customSaveFolderInput(PresentationTheme, String, String)
    case customSaveFolderHint(PresentationTheme, String)
    case interfaceHeader(PresentationTheme, String)
    case disableNumberRounding(PresentationTheme, String, Bool)
    case formatTimeWithSeconds(PresentationTheme, String, Bool)
    case pluginsRow(PresentationTheme, String)
    case tabCounter(PresentationTheme, String, Bool)
    case hideAllChats(PresentationTheme, String, Bool)
    case tabIcons(PresentationTheme, String, Bool)
    case stickerShape(PresentationTheme, String, Bool)
    case hideStickerTime(PresentationTheme, String, Bool)
    case hideCategories(PresentationTheme, String, Bool)
    case hidePhotoCounter(PresentationTheme, String, Bool)
    case disablePlayback(PresentationTheme, String, Bool)
    case longDoubleTapSeek(PresentationTheme, String, Bool)
    case analyticsHeader(PresentationTheme, String)
    case useGoogleAnalytics(PresentationTheme, String, Bool)
    case useGoogleCrashlytics(PresentationTheme, String, Bool)
    case analyticsInfo(PresentationTheme, String)
    case updatesHeader(PresentationTheme, String)
    case checkForUpdates(PresentationTheme, String, String)
    case checkOnLaunch(PresentationTheme, String, Bool)
    case lastCheck(PresentationTheme, String, String)
    case currentVersion(PresentationTheme, String, String)
    case latestVersion(PresentationTheme, String, String)
    case changelog(PresentationTheme, String)
    case downloadOnGitHub(PresentationTheme, String, String)
    case messagesHeader(PresentationTheme, String)
    case blockAds(PresentationTheme, String, Bool)
    case hideShareButtonEntry(PresentationTheme, String, Bool)
    case showCopyPhotoButton(PresentationTheme, String, Bool)
    case showClearButton(PresentationTheme, String, Bool)
    case showSaveMessageButton(PresentationTheme, String, Bool)
    case showReportButton(PresentationTheme, String, Bool)
    case showHistoryButton(PresentationTheme, String, Bool)
    case groupsHeader(PresentationTheme, String)
    case permissionsShortcut(PresentationTheme, String, Bool)
    case administratorsShortcut(PresentationTheme, String, Bool)
    case membersShortcut(PresentationTheme, String, Bool)
    case recentActionsShortcut(PresentationTheme, String, Bool)

    var section: ItemListSectionId {
        switch self {
            case .speedHeader, .downloadBoost, .ultraWarning, .uploadBoost:
                return ExteraSettingsSection.speed.rawValue
            case .storageHeader, .customSaveFolderInput, .customSaveFolderHint:
                return ExteraSettingsSection.storage.rawValue
            case .interfaceHeader, .disableNumberRounding, .formatTimeWithSeconds, .pluginsRow,
                 .tabCounter, .hideAllChats, .tabIcons, .stickerShape, .hideStickerTime, .hideCategories,
                 .hidePhotoCounter, .disablePlayback, .longDoubleTapSeek:
                return ExteraSettingsSection.interface.rawValue
            case .analyticsHeader, .useGoogleAnalytics, .useGoogleCrashlytics, .analyticsInfo:
                return ExteraSettingsSection.analytics.rawValue
            case .updatesHeader, .checkForUpdates, .checkOnLaunch, .lastCheck, .currentVersion, .latestVersion, .changelog, .downloadOnGitHub:
                return ExteraSettingsSection.updates.rawValue
            case .messagesHeader, .blockAds, .hideShareButtonEntry, .showCopyPhotoButton, .showClearButton, .showSaveMessageButton, .showReportButton, .showHistoryButton:
                return ExteraSettingsSection.messages.rawValue
            case .groupsHeader, .permissionsShortcut, .administratorsShortcut, .membersShortcut, .recentActionsShortcut:
                return ExteraSettingsSection.groups.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
            case .speedHeader: return 0
            case .downloadBoost: return 1
            case .ultraWarning: return 2
            case .uploadBoost: return 3
            case .storageHeader: return 4
            case .customSaveFolderInput: return 5
            case .customSaveFolderHint: return 6
            case .interfaceHeader: return 7
            case .disableNumberRounding: return 8
            case .formatTimeWithSeconds: return 9
            case .pluginsRow: return 22
            case .tabCounter: return 23
            case .hideAllChats: return 24
            case .tabIcons: return 25
            case .stickerShape: return 26
            case .hideStickerTime: return 27
            case .hideCategories: return 28
            case .hidePhotoCounter: return 29
            case .disablePlayback: return 30
            case .longDoubleTapSeek: return 31
            case .messagesHeader: return 32
            case .blockAds: return 33
            case .hideShareButtonEntry: return 34
            case .showCopyPhotoButton: return 35
            case .showClearButton: return 36
            case .showSaveMessageButton: return 37
            case .showReportButton: return 38
            case .showHistoryButton: return 39
            case .groupsHeader: return 40
            case .permissionsShortcut: return 41
            case .administratorsShortcut: return 42
            case .membersShortcut: return 43
            case .recentActionsShortcut: return 44
            case .analyticsHeader: return 10
            case .useGoogleAnalytics: return 11
            case .useGoogleCrashlytics: return 12
            case .analyticsInfo: return 13
            case .updatesHeader: return 14
            case .checkForUpdates: return 15
            case .checkOnLaunch: return 16
            case .lastCheck: return 17
            case .currentVersion: return 18
            case .latestVersion: return 19
            case .changelog: return 20
            case .downloadOnGitHub: return 21
        }
    }

    static func ==(lhs: ExteraSettingsEntry, rhs: ExteraSettingsEntry) -> Bool {
        switch lhs {
            case let .speedHeader(lhsTheme, lhsText):
                if case let .speedHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .downloadBoost(lhsTheme, lhsText, lhsValue):
                if case let .downloadBoost(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .ultraWarning(lhsTheme, lhsText):
                if case let .ultraWarning(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .uploadBoost(lhsTheme, lhsText, lhsValue):
                if case let .uploadBoost(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .storageHeader(lhsTheme, lhsText):
                if case let .storageHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .customSaveFolderInput(lhsTheme, lhsTitle, lhsText):
                if case let .customSaveFolderInput(rhsTheme, rhsTitle, rhsText) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .customSaveFolderHint(lhsTheme, lhsText):
                if case let .customSaveFolderHint(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .interfaceHeader(lhsTheme, lhsText):
                if case let .interfaceHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .disableNumberRounding(lhsTheme, lhsText, lhsValue):
                if case let .disableNumberRounding(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .formatTimeWithSeconds(lhsTheme, lhsText, lhsValue):
                if case let .formatTimeWithSeconds(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .pluginsRow(lhsTheme, lhsText):
                if case let .pluginsRow(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .analyticsHeader(lhsTheme, lhsText):
                if case let .analyticsHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .useGoogleAnalytics(lhsTheme, lhsText, lhsValue):
                if case let .useGoogleAnalytics(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .useGoogleCrashlytics(lhsTheme, lhsText, lhsValue):
                if case let .useGoogleCrashlytics(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .analyticsInfo(lhsTheme, lhsText):
                if case let .analyticsInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .updatesHeader(lhsTheme, lhsText):
                if case let .updatesHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .checkForUpdates(lhsTheme, lhsText, lhsValue):
                if case let .checkForUpdates(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .checkOnLaunch(lhsTheme, lhsText, lhsValue):
                if case let .checkOnLaunch(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .lastCheck(lhsTheme, lhsText, lhsValue):
                if case let .lastCheck(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .currentVersion(lhsTheme, lhsText, lhsValue):
                if case let .currentVersion(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .latestVersion(lhsTheme, lhsText, lhsValue):
                if case let .latestVersion(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .changelog(lhsTheme, lhsText):
                if case let .changelog(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .downloadOnGitHub(lhsTheme, lhsText, lhsUrl):
                if case let .downloadOnGitHub(rhsTheme, rhsText, rhsUrl) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsUrl == rhsUrl {
                    return true
                } else {
                    return false
                }
            case let .tabCounter(lhsTheme, lhsText, lhsValue):
                if case let .tabCounter(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .hideAllChats(lhsTheme, lhsText, lhsValue):
                if case let .hideAllChats(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .tabIcons(lhsTheme, lhsText, lhsValue):
                if case let .tabIcons(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .stickerShape(lhsTheme, lhsText, lhsValue):
                if case let .stickerShape(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .hideStickerTime(lhsTheme, lhsText, lhsValue):
                if case let .hideStickerTime(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .hideCategories(lhsTheme, lhsText, lhsValue):
                if case let .hideCategories(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .hidePhotoCounter(lhsTheme, lhsText, lhsValue):
                if case let .hidePhotoCounter(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .disablePlayback(lhsTheme, lhsText, lhsValue):
                if case let .disablePlayback(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .longDoubleTapSeek(lhsTheme, lhsText, lhsValue):
                if case let .longDoubleTapSeek(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .blockAds(lhsTheme, lhsText, lhsValue):
                if case let .blockAds(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .hideShareButtonEntry(lhsTheme, lhsText, lhsValue):
                if case let .hideShareButtonEntry(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .showCopyPhotoButton(lhsTheme, lhsText, lhsValue):
                if case let .showCopyPhotoButton(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .showClearButton(lhsTheme, lhsText, lhsValue):
                if case let .showClearButton(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .showSaveMessageButton(lhsTheme, lhsText, lhsValue):
                if case let .showSaveMessageButton(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .showReportButton(lhsTheme, lhsText, lhsValue):
                if case let .showReportButton(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .showHistoryButton(lhsTheme, lhsText, lhsValue):
                if case let .showHistoryButton(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .permissionsShortcut(lhsTheme, lhsText, lhsValue):
                if case let .permissionsShortcut(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .administratorsShortcut(lhsTheme, lhsText, lhsValue):
                if case let .administratorsShortcut(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .membersShortcut(lhsTheme, lhsText, lhsValue):
                if case let .membersShortcut(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .recentActionsShortcut(lhsTheme, lhsText, lhsValue):
                if case let .recentActionsShortcut(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .messagesHeader(lhsTheme, lhsText):
                if case let .messagesHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .groupsHeader(lhsTheme, lhsText):
                if case let .groupsHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
        }
    }

    static func <(lhs: ExteraSettingsEntry, rhs: ExteraSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraSettingsArguments
        switch self {
            case let .speedHeader(_, text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .downloadBoost(_, text, value):
                return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.storageUsage, title: text, label: value, sectionId: self.section, style: .blocks, action: {
                    arguments.chooseDownloadBoost()
                })
            case let .ultraWarning(_, text):
                return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
            case let .uploadBoost(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleUploadBoost(value)
                })
            case let .storageHeader(_, text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .customSaveFolderInput(_, title, text):
                return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(string: title), text: text, placeholder: "", type: .regular(capitalization: true, autocorrection: false), spacing: 10.0, clearType: .always, enabled: true, tag: nil, sectionId: self.section, textUpdated: { updatedText in
                    arguments.setCustomSaveFolderName(updatedText)
                }, action: {})
            case let .customSaveFolderHint(_, text):
                return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
            case let .interfaceHeader(_, text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .disableNumberRounding(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleDisableNumberRounding(value)
                })
            case let .formatTimeWithSeconds(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleFormatTimeWithSeconds(value)
                })
            case let .pluginsRow(_, text):
                return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", sectionId: self.section, style: .blocks, action: {
                    arguments.openPlugins()
                })
            case let .tabCounter(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleTabCounter(value)
                })
            case let .hideAllChats(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleHideAllChats(value)
                })
            case let .tabIcons(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleTabIcons(value)
                })
            case let .stickerShape(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleStickerShape(value)
                })
            case let .hideStickerTime(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleHideStickerTime(value)
                })
            case let .hideCategories(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleHideCategories(value)
                })
            case let .hidePhotoCounter(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleHidePhotoCounter(value)
                })
            case let .disablePlayback(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleDisablePlayback(value)
                })
            case let .longDoubleTapSeek(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleLongDoubleTapSeek(value)
                })
            case let .analyticsHeader(_, text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .useGoogleAnalytics(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleUseGoogleAnalytics(value)
                })
            case let .useGoogleCrashlytics(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleUseGoogleCrashlytics(value)
                })
            case let .analyticsInfo(_, text):
                return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
            case let .messagesHeader(_, text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .hideShareButtonEntry(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleHideShareButton(value)
                })
            case let .blockAds(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleBlockAds(value)
                })
            case let .showCopyPhotoButton(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleShowCopyPhotoButton(value)
                })
            case let .showClearButton(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleShowClearButton(value)
                })
            case let .showSaveMessageButton(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleShowSaveMessageButton(value)
                })
            case let .showReportButton(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleShowReportButton(value)
                })
            case let .showHistoryButton(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleShowHistoryButton(value)
                })
            case let .groupsHeader(_, text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .permissionsShortcut(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.togglePermissionsShortcut(value)
                })
            case let .administratorsShortcut(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleAdministratorsShortcut(value)
                })
            case let .membersShortcut(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleMembersShortcut(value)
                })
            case let .recentActionsShortcut(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleRecentActionsShortcut(value)
                })
            case let .updatesHeader(_, text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .checkForUpdates(_, text, value):
                return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.storageUsage, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, action: {
                    arguments.checkForUpdates()
                })
            case let .checkOnLaunch(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleCheckOnLaunch(value)
                })
            case let .lastCheck(_, text, value):
                return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .detailText, sectionId: self.section, style: .blocks, action: {})
            case let .currentVersion(_, text, value):
                return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .detailText, sectionId: self.section, style: .blocks, action: {})
            case let .latestVersion(_, text, value):
                return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .detailText, sectionId: self.section, style: .blocks, action: {})
            case let .changelog(_, text):
                return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
            case let .downloadOnGitHub(_, text, url):
                return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", sectionId: self.section, style: .blocks, action: {
                    arguments.openReleasePage(url)
                })
        }
    }
}

private final class ExteraSettingsArguments {
    let chooseDownloadBoost: () -> Void
    let toggleUploadBoost: (Bool) -> Void
    let setCustomSaveFolderName: (String) -> Void
    let toggleDisableNumberRounding: (Bool) -> Void
    let toggleFormatTimeWithSeconds: (Bool) -> Void
    let toggleUseGoogleAnalytics: (Bool) -> Void
    let toggleUseGoogleCrashlytics: (Bool) -> Void
    let checkForUpdates: () -> Void
    let toggleCheckOnLaunch: (Bool) -> Void
    let openReleasePage: (String) -> Void
    let openPlugins: () -> Void
    let toggleBlockAds: (Bool) -> Void
    let toggleHideShareButton: (Bool) -> Void
    let toggleShowCopyPhotoButton: (Bool) -> Void
    let toggleShowClearButton: (Bool) -> Void
    let toggleShowSaveMessageButton: (Bool) -> Void
    let toggleShowReportButton: (Bool) -> Void
    let toggleShowHistoryButton: (Bool) -> Void
    let togglePermissionsShortcut: (Bool) -> Void
    let toggleAdministratorsShortcut: (Bool) -> Void
    let toggleMembersShortcut: (Bool) -> Void
    let toggleRecentActionsShortcut: (Bool) -> Void
    let toggleTabCounter: (Bool) -> Void
    let toggleHideAllChats: (Bool) -> Void
    let toggleTabIcons: (Bool) -> Void
    let toggleStickerShape: (Bool) -> Void
    let toggleHideStickerTime: (Bool) -> Void
    let toggleHideCategories: (Bool) -> Void
    let toggleHidePhotoCounter: (Bool) -> Void
    let toggleDisablePlayback: (Bool) -> Void
    let toggleLongDoubleTapSeek: (Bool) -> Void

    init(
        chooseDownloadBoost: @escaping () -> Void,
        toggleUploadBoost: @escaping (Bool) -> Void,
        setCustomSaveFolderName: @escaping (String) -> Void,
        toggleDisableNumberRounding: @escaping (Bool) -> Void,
        toggleFormatTimeWithSeconds: @escaping (Bool) -> Void,
        toggleUseGoogleAnalytics: @escaping (Bool) -> Void,
        toggleUseGoogleCrashlytics: @escaping (Bool) -> Void,
        checkForUpdates: @escaping () -> Void,
        toggleCheckOnLaunch: @escaping (Bool) -> Void,
        openReleasePage: @escaping (String) -> Void,
        openPlugins: @escaping () -> Void,
        toggleBlockAds: @escaping (Bool) -> Void,
        toggleHideShareButton: @escaping (Bool) -> Void,
        toggleShowCopyPhotoButton: @escaping (Bool) -> Void,
        toggleShowClearButton: @escaping (Bool) -> Void,
        toggleShowSaveMessageButton: @escaping (Bool) -> Void,
        toggleShowReportButton: @escaping (Bool) -> Void,
        toggleShowHistoryButton: @escaping (Bool) -> Void,
        togglePermissionsShortcut: @escaping (Bool) -> Void,
        toggleAdministratorsShortcut: @escaping (Bool) -> Void,
        toggleMembersShortcut: @escaping (Bool) -> Void,
        toggleRecentActionsShortcut: @escaping (Bool) -> Void,
        toggleTabCounter: @escaping (Bool) -> Void,
        toggleHideAllChats: @escaping (Bool) -> Void,
        toggleTabIcons: @escaping (Bool) -> Void,
        toggleStickerShape: @escaping (Bool) -> Void,
        toggleHideStickerTime: @escaping (Bool) -> Void,
        toggleHideCategories: @escaping (Bool) -> Void,
        toggleHidePhotoCounter: @escaping (Bool) -> Void,
        toggleDisablePlayback: @escaping (Bool) -> Void,
        toggleLongDoubleTapSeek: @escaping (Bool) -> Void
    ) {
        self.chooseDownloadBoost = chooseDownloadBoost
        self.toggleUploadBoost = toggleUploadBoost
        self.setCustomSaveFolderName = setCustomSaveFolderName
        self.toggleDisableNumberRounding = toggleDisableNumberRounding
        self.toggleFormatTimeWithSeconds = toggleFormatTimeWithSeconds
        self.toggleUseGoogleAnalytics = toggleUseGoogleAnalytics
        self.toggleUseGoogleCrashlytics = toggleUseGoogleCrashlytics
        self.checkForUpdates = checkForUpdates
        self.toggleCheckOnLaunch = toggleCheckOnLaunch
        self.openReleasePage = openReleasePage
        self.openPlugins = openPlugins
        self.toggleBlockAds = toggleBlockAds
        self.toggleHideShareButton = toggleHideShareButton
        self.toggleShowCopyPhotoButton = toggleShowCopyPhotoButton
        self.toggleShowClearButton = toggleShowClearButton
        self.toggleShowSaveMessageButton = toggleShowSaveMessageButton
        self.toggleShowReportButton = toggleShowReportButton
        self.toggleShowHistoryButton = toggleShowHistoryButton
        self.togglePermissionsShortcut = togglePermissionsShortcut
        self.toggleAdministratorsShortcut = toggleAdministratorsShortcut
        self.toggleMembersShortcut = toggleMembersShortcut
        self.toggleRecentActionsShortcut = toggleRecentActionsShortcut
        self.toggleTabCounter = toggleTabCounter
        self.toggleHideAllChats = toggleHideAllChats
        self.toggleTabIcons = toggleTabIcons
        self.toggleStickerShape = toggleStickerShape
        self.toggleHideStickerTime = toggleHideStickerTime
        self.toggleHideCategories = toggleHideCategories
        self.toggleHidePhotoCounter = toggleHidePhotoCounter
        self.toggleDisablePlayback = toggleDisablePlayback
        self.toggleLongDoubleTapSeek = toggleLongDoubleTapSeek
    }
}

private func exteraBoostLevelTitle(_ level: Int32, strings: ExteraStringsTable) -> String {
    switch level {
        case 1: return strings.boostFast
        case 2: return strings.boostUltra
        default: return strings.boostOff
    }
}

private func exteraLastCheckString(_ timestamp: Int64, presentationData: PresentationData) -> String {
    guard timestamp > 0 else {
        return exteraStrings(presentationData: presentationData).never
    }
    let intTimestamp = Int32(timestamp)
    return stringForShortDate(timestamp: intTimestamp, strings: presentationData.strings, dateTimeFormat: presentationData.dateTimeFormat) + " " + stringForMessageTimestamp(timestamp: intTimestamp, dateTimeFormat: presentationData.dateTimeFormat)
}

private func exteraUpdateStatusLabel(_ status: ExteraUpdaterStatus, strings: ExteraStringsTable) -> String {
    switch status {
        case .idle: return strings.checkForUpdates
        case .checking: return strings.checkingForUpdates
        case .upToDate: return strings.upToDate
        case .failed: return strings.checkFailed
        case let .available(release): return release.version
    }
}

private func exteraSettingsEntries(presentationData: PresentationData, settings: ExteraSettings, status: ExteraUpdaterStatus) -> [ExteraSettingsEntry] {
    let strings = exteraStrings(presentationData: presentationData)
    var entries: [ExteraSettingsEntry] = []

    entries.append(.speedHeader(presentationData.theme, strings.speedHeader.uppercased()))
    entries.append(.downloadBoost(presentationData.theme, strings.downloadBoost, exteraBoostLevelTitle(settings.downloadSpeedBoostLevel, strings: strings)))
    if settings.downloadSpeedBoostLevel == 2 || settings.uploadSpeedBoost {
        entries.append(.ultraWarning(presentationData.theme, strings.ultraWarning))
    }
    entries.append(.uploadBoost(presentationData.theme, strings.uploadBoost, settings.uploadSpeedBoost))

    entries.append(.storageHeader(presentationData.theme, strings.storageHeader.uppercased()))
    entries.append(.customSaveFolderInput(presentationData.theme, strings.customSaveFolder, settings.customSaveFolderName))
    if !settings.customSaveFolderName.isEmpty {
        entries.append(.customSaveFolderHint(presentationData.theme, strings.customSaveFolderHint))
    }

    entries.append(.interfaceHeader(presentationData.theme, strings.interfaceHeader.uppercased()))
    entries.append(.disableNumberRounding(presentationData.theme, strings.disableNumberRounding, settings.disableNumberRounding))
    entries.append(.formatTimeWithSeconds(presentationData.theme, strings.formatTimeWithSeconds, settings.formatTimeWithSeconds))
    entries.append(.pluginsRow(presentationData.theme, strings.pluginsRow))
    entries.append(.tabCounter(presentationData.theme, strings.tabCounter, settings.tabCounter))
    entries.append(.hideAllChats(presentationData.theme, strings.hideAllChats, settings.hideAllChats))
    entries.append(.tabIcons(presentationData.theme, strings.tabIcons, settings.tabIcons))
    entries.append(.stickerShape(presentationData.theme, strings.stickerShape, settings.stickerShape))
    entries.append(.hideStickerTime(presentationData.theme, strings.hideStickerTime, settings.hideStickerTime))
    entries.append(.hideCategories(presentationData.theme, strings.hideCategories, settings.hideCategories))
    entries.append(.hidePhotoCounter(presentationData.theme, strings.hidePhotoCounter, settings.hidePhotoCounter))
    entries.append(.disablePlayback(presentationData.theme, strings.disablePlayback, settings.disablePlayback))
    entries.append(.longDoubleTapSeek(presentationData.theme, strings.longDoubleTapSeek, settings.doubleTapSeekDuration))
    entries.append(.messagesHeader(presentationData.theme, strings.messagesHeader.uppercased()))
    entries.append(.blockAds(presentationData.theme, strings.blockAds, settings.adBlockEnabled))
    entries.append(.hideShareButtonEntry(presentationData.theme, strings.hideShareButton, settings.hideShareButton))
    entries.append(.showCopyPhotoButton(presentationData.theme, strings.showCopyPhotoButton, settings.showCopyPhotoButton))
    entries.append(.showClearButton(presentationData.theme, strings.showClearButton, settings.showClearButton))
    entries.append(.showSaveMessageButton(presentationData.theme, strings.showSaveMessageButton, settings.showSaveMessageButton))
    entries.append(.showReportButton(presentationData.theme, strings.showReportButton, settings.showReportButton))
    entries.append(.showHistoryButton(presentationData.theme, strings.showHistoryButton, settings.showHistoryButton))
    entries.append(.groupsHeader(presentationData.theme, strings.groupsHeader.uppercased()))
    entries.append(.permissionsShortcut(presentationData.theme, strings.permissionsShortcut, settings.permissionsShortcut))
    entries.append(.administratorsShortcut(presentationData.theme, strings.administratorsShortcut, settings.administratorsShortcut))
    entries.append(.membersShortcut(presentationData.theme, strings.membersShortcut, settings.membersShortcut))
    entries.append(.recentActionsShortcut(presentationData.theme, strings.recentActionsShortcut, settings.recentActionsShortcut))

    entries.append(.analyticsHeader(presentationData.theme, strings.analyticsHeader.uppercased()))
    entries.append(.useGoogleAnalytics(presentationData.theme, strings.useGoogleAnalytics, settings.useGoogleAnalytics))
    entries.append(.useGoogleCrashlytics(presentationData.theme, strings.useGoogleCrashlytics, settings.useGoogleCrashlytics))
    entries.append(.analyticsInfo(presentationData.theme, strings.analyticsInfo))

    entries.append(.updatesHeader(presentationData.theme, strings.updatesHeader.uppercased()))
    entries.append(.checkForUpdates(presentationData.theme, strings.checkForUpdates, exteraUpdateStatusLabel(status, strings: strings)))
    entries.append(.checkOnLaunch(presentationData.theme, strings.checkOnLaunch, settings.checkUpdatesOnLaunch))
    entries.append(.lastCheck(presentationData.theme, strings.lastCheck, exteraLastCheckString(settings.lastUpdateCheckTime, presentationData: presentationData)))
    if let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
        entries.append(.currentVersion(presentationData.theme, strings.currentVersion, currentVersion))
    }
    if case let .available(release) = status {
        entries.append(.latestVersion(presentationData.theme, strings.latestVersion, release.version))
        if !release.changelog.isEmpty {
            entries.append(.changelog(presentationData.theme, release.changelog))
        }
        entries.append(.downloadOnGitHub(presentationData.theme, strings.downloadOnGitHub, release.pageUrl))
    }

    return entries
}

public func exteraSettingsScreen(context: AccountContext) -> ViewController {
    let statusPromise = ValuePromise<ExteraUpdaterStatus>(ignoreRepeated: true)
    let updateStatusDisposable = MetaDisposable()
    let pushControllerImpl = Atomic<((ViewController) -> Void)?>(value: nil)

    let arguments = ExteraSettingsArguments(
        chooseDownloadBoost: { [weak context] in
            guard let context = context else {
                return
            }
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let strings = exteraStrings(presentationData: presentationData)
            let levels: [(Int32, String)] = [
                (0, strings.boostOff),
                (1, strings.boostFast),
                (2, strings.boostUltra)
            ]
            let alertController = textAlertController(context: context, title: strings.downloadBoost, text: "", actions: levels.map { level, title in
                TextAlertAction(type: .genericAction, title: title, action: {
                    exteraApplyDownloadBoostLevel(context: context, level: level)
                    exteraPresentRestartRequired(sharedContext: context.sharedContext)
                })
            })
            context.sharedContext.presentGlobalController(alertController, nil)
        },
        toggleUploadBoost: { [weak context] value in
            guard let context = context else {
                return
            }
            exteraApplyUploadBoost(context: context, enabled: value)
            exteraPresentRestartRequired(sharedContext: context.sharedContext)
        },
        setCustomSaveFolderName: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.customSaveFolderName = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return settings
            }.start()
        },
        toggleDisableNumberRounding: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.disableNumberRounding = value
                return settings
            }.start()
        },
        toggleFormatTimeWithSeconds: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.formatTimeWithSeconds = value
                return settings
            }.start()
        },
        toggleUseGoogleAnalytics: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.useGoogleAnalytics = value
                return settings
            }.start()
            exteraPresentRestartRequired(sharedContext: context.sharedContext)
        },
        toggleUseGoogleCrashlytics: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.useGoogleCrashlytics = value
                return settings
            }.start()
            exteraPresentRestartRequired(sharedContext: context.sharedContext)
        },
        checkForUpdates: { [weak context] in
            guard let context = context else {
                return
            }
            statusPromise.set(.checking)
            updateStatusDisposable.set(ExteraUpdater.checkForUpdate(sharedContext: context.sharedContext, completion: { release in
                if let release = release {
                    statusPromise.set(.available(release))
                } else {
                    statusPromise.set(.failed)
                }
            }))
        },
        toggleCheckOnLaunch: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.checkUpdatesOnLaunch = value
                return settings
            }.start()
        },
        openReleasePage: { url in
            guard let url = URL(string: url) else {
                return
            }
            UIApplication.shared.open(url)
        },
        openPlugins: { [weak context] in
            guard let context else {
                return
            }
            let screen = exteraPluginsScreen(context: context)
            (pushControllerImpl.with { $0 })?(screen)
        },
        toggleBlockAds: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                return settings.withUpdatedAdBlockEnabled(value)
            }.start()
        },
        toggleHideShareButton: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.hideShareButton = value
                return settings
            }.start()
        },
        toggleShowCopyPhotoButton: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.showCopyPhotoButton = value
                return settings
            }.start()
        },
        toggleShowClearButton: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.showClearButton = value
                return settings
            }.start()
        },
        toggleShowSaveMessageButton: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.showSaveMessageButton = value
                return settings
            }.start()
        },
        toggleShowReportButton: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.showReportButton = value
                return settings
            }.start()
        },
        toggleShowHistoryButton: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.showHistoryButton = value
                return settings
            }.start()
        },
        togglePermissionsShortcut: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.permissionsShortcut = value
                return settings
            }.start()
        },
        toggleAdministratorsShortcut: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.administratorsShortcut = value
                return settings
            }.start()
        },
        toggleMembersShortcut: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.membersShortcut = value
                return settings
            }.start()
        },
        toggleRecentActionsShortcut: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.recentActionsShortcut = value
                return settings
            }.start()
        },
        toggleTabCounter: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.tabCounter = value
                return settings
            }.start()
        },
        toggleHideAllChats: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.hideAllChats = value
                return settings
            }.start()
        },
        toggleTabIcons: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.tabIcons = value
                return settings
            }.start()
        },
        toggleStickerShape: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.stickerShape = value
                return settings
            }.start()
        },
        toggleHideStickerTime: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.hideStickerTime = value
                return settings
            }.start()
        },
        toggleHideCategories: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.hideCategories = value
                return settings
            }.start()
        },
        toggleHidePhotoCounter: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.hidePhotoCounter = value
                return settings
            }.start()
        },
        toggleDisablePlayback: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.disablePlayback = value
                return settings
            }.start()
        },
        toggleLongDoubleTapSeek: { [weak context] value in
            guard let context = context else {
                return
            }
            let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.doubleTapSeekDuration = value
                return settings
            }.start()
        },
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        exteraSettings(accountManager: context.sharedContext.accountManager),
        statusPromise.get()
    )
    |> map { presentationData, settings, status -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let strings = exteraStrings(presentationData: presentationData)
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(strings.settingsTitle), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraSettingsEntries(presentationData: presentationData, settings: settings, status: status), style: .blocks, ensureVisibleItemTag: nil, emptyStateItem: nil, animateChanges: false)

        return (controllerState, (listState, arguments))
    }
    |> afterDisposed {
        updateStatusDisposable.dispose()
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    let _ = pushControllerImpl.swap({ [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    })
    return controller
}

private func exteraApplyDownloadBoostLevel(context: AccountContext, level: Int32) {
    let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
        var settings = settings
        settings.downloadSpeedBoostLevel = level
        return settings
    }.start()
    let _ = updateNetworkSettingsInteractively(postbox: context.account.postbox, network: context.account.network) { networkSettings in
        var networkSettings = networkSettings
        networkSettings.downloadSpeedBoostLevel = Int(level)
        return networkSettings
    }.start()
}

private func exteraApplyUploadBoost(context: AccountContext, enabled: Bool) {
    let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
        var settings = settings
        settings.uploadSpeedBoost = enabled
        return settings
    }.start()
    let _ = updateNetworkSettingsInteractively(postbox: context.account.postbox, network: context.account.network) { networkSettings in
        var networkSettings = networkSettings
        networkSettings.uploadSpeedBoost = enabled
        return networkSettings
    }.start()
}
