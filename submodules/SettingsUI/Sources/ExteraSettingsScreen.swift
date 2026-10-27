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

private enum ExteraUpdaterStatus: Equatable {
    case idle
    case checking
    case upToDate
    case available(ExteraRelease)
    case failed
}

private enum ExteraSettingsSection: Int32 {
    case speed = 0
    case interface = 1
    case updates = 2
}

private enum ExteraSettingsEntry: ItemListNodeEntry {
    case speedHeader(PresentationTheme, String)
    case downloadBoost(PresentationTheme, String, String)
    case uploadBoost(PresentationTheme, String, Bool)
    case interfaceHeader(PresentationTheme, String)
    case disableNumberRounding(PresentationTheme, String, Bool)
    case formatTimeWithSeconds(PresentationTheme, String, Bool)
    case updatesHeader(PresentationTheme, String)
    case checkForUpdates(PresentationTheme, String, String)
    case checkOnLaunch(PresentationTheme, String, Bool)
    case lastCheck(PresentationTheme, String, String)
    case currentVersion(PresentationTheme, String, String)
    case latestVersion(PresentationTheme, String, String)
    case changelog(PresentationTheme, String)
    case downloadOnGitHub(PresentationTheme, String, String)

    var section: ItemListSectionId {
        switch self {
            case .speedHeader, .downloadBoost, .uploadBoost:
                return ExteraSettingsSection.speed.rawValue
            case .interfaceHeader, .disableNumberRounding, .formatTimeWithSeconds:
                return ExteraSettingsSection.interface.rawValue
            case .updatesHeader, .checkForUpdates, .checkOnLaunch, .lastCheck, .currentVersion, .latestVersion, .changelog, .downloadOnGitHub:
                return ExteraSettingsSection.updates.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
            case .speedHeader: return 0
            case .downloadBoost: return 1
            case .uploadBoost: return 2
            case .interfaceHeader: return 3
            case .disableNumberRounding: return 4
            case .formatTimeWithSeconds: return 5
            case .updatesHeader: return 6
            case .checkForUpdates: return 7
            case .checkOnLaunch: return 8
            case .lastCheck: return 9
            case .currentVersion: return 10
            case .latestVersion: return 11
            case .changelog: return 12
            case .downloadOnGitHub: return 13
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
            case let .uploadBoost(lhsTheme, lhsText, lhsValue):
                if case let .uploadBoost(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
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
            case let .uploadBoost(_, text, value):
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleUploadBoost(value)
                })
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
    let toggleDisableNumberRounding: (Bool) -> Void
    let toggleFormatTimeWithSeconds: (Bool) -> Void
    let checkForUpdates: () -> Void
    let toggleCheckOnLaunch: (Bool) -> Void
    let openReleasePage: (String) -> Void

    init(
        chooseDownloadBoost: @escaping () -> Void,
        toggleUploadBoost: @escaping (Bool) -> Void,
        toggleDisableNumberRounding: @escaping (Bool) -> Void,
        toggleFormatTimeWithSeconds: @escaping (Bool) -> Void,
        checkForUpdates: @escaping () -> Void,
        toggleCheckOnLaunch: @escaping (Bool) -> Void,
        openReleasePage: @escaping (String) -> Void
    ) {
        self.chooseDownloadBoost = chooseDownloadBoost
        self.toggleUploadBoost = toggleUploadBoost
        self.toggleDisableNumberRounding = toggleDisableNumberRounding
        self.toggleFormatTimeWithSeconds = toggleFormatTimeWithSeconds
        self.checkForUpdates = checkForUpdates
        self.toggleCheckOnLaunch = toggleCheckOnLaunch
        self.openReleasePage = openReleasePage
    }
}

private func exteraBoostLevelTitle(_ level: Int, strings: ExteraStringsTable) -> String {
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
    entries.append(.uploadBoost(presentationData.theme, strings.uploadBoost, settings.uploadSpeedBoost))

    entries.append(.interfaceHeader(presentationData.theme, strings.interfaceHeader.uppercased()))
    entries.append(.disableNumberRounding(presentationData.theme, strings.disableNumberRounding, settings.disableNumberRounding))
    entries.append(.formatTimeWithSeconds(presentationData.theme, strings.formatTimeWithSeconds, settings.formatTimeWithSeconds))

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

    let arguments = ExteraSettingsArguments(
        chooseDownloadBoost: { [weak context] in
            guard let context = context else {
                return
            }
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let strings = exteraStrings(presentationData: presentationData)
            let levels: [(Int, String)] = [
                (0, strings.boostOff),
                (1, strings.boostFast),
                (2, strings.boostUltra)
            ]
            let alertController = textAlertController(context: context, title: strings.downloadBoost, text: "", actions: levels.map { level, title in
                TextAlertAction(type: .genericAction, title: title, action: {
                    exteraApplyDownloadBoostLevel(context: context, level: level)
                })
            })
            context.sharedContext.presentGlobalController(alertController, nil)
        },
        toggleUploadBoost: { [weak context] value in
            guard let context = context else {
                return
            }
            exteraApplyUploadBoost(context: context, enabled: value)
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
        openReleasePage: { [weak context] url in
            guard let context = context, let url = URL(string: url) else {
                return
            }
            UIApplication.shared.open(url)
        }
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

    return ItemListController(context: context, state: signal)
}

private func exteraApplyDownloadBoostLevel(context: AccountContext, level: Int) {
    let _ = updateExteraSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
        var settings = settings
        settings.downloadSpeedBoostLevel = level
        return settings
    }.start()
    let _ = updateNetworkSettingsInteractively(postbox: context.account.postbox, network: context.account.network) { networkSettings in
        var networkSettings = networkSettings
        networkSettings.downloadSpeedBoostLevel = level
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
