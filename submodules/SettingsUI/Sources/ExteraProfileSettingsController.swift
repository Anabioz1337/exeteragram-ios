import Foundation
import SwiftSignalKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import ItemListUI
import PresentationDataUtils
import ExteraProfile

private enum ExteraProfileSettingsSection: Int32 {
    case info
    case chatList
}

private final class ExteraProfileSettingsArguments {
    let update: (inout ExteraProfilePreferences) -> Void
    let openActionBarTitlePicker: () -> Void

    init(update: @escaping (inout ExteraProfilePreferences) -> Void, openActionBarTitlePicker: @escaping () -> Void) {
        self.update = update
        self.openActionBarTitlePicker = openActionBarTitlePicker
    }
}

private enum ExteraProfileSettingsEntryId: Int32 {
    case infoHeader = 0
    case hidePhoneNumber
    case showIdAndDc
    case showIdAndDcInfo
    case showCreationDate
    case showRegistrationDates
    case showOnlineIndicator
    case showForwardsCount
    case chatListHeader
    case hideArchiveFolder
    case archiveOnPull
    case disableUnarchiveSwipe
    case disableUnarchiveSwipeInfo
    case actionBarTitle
    case senderMiniAvatars
}

private enum ExteraProfileSettingsEntry: ItemListNodeEntry {
    case infoHeader(String)
    case hidePhoneNumber(Bool)
    case showIdAndDc(Bool)
    case showIdAndDcInfo(String)
    case showCreationDate(Bool)
    case showRegistrationDates(Bool)
    case showOnlineIndicator(Bool)
    case showForwardsCount(Bool)
    case chatListHeader(String)
    case hideArchiveFolder(Bool)
    case archiveOnPull(Bool)
    case disableUnarchiveSwipe(Bool)
    case disableUnarchiveSwipeInfo(String)
    case actionBarTitle(label: String)
    case senderMiniAvatars(Bool)

    var section: ItemListSectionId {
        switch self.id {
        case .infoHeader, .hidePhoneNumber, .showIdAndDc, .showIdAndDcInfo, .showCreationDate, .showRegistrationDates, .showOnlineIndicator, .showForwardsCount:
            return ExteraProfileSettingsSection.info.rawValue
        case .chatListHeader, .hideArchiveFolder, .archiveOnPull, .disableUnarchiveSwipe, .disableUnarchiveSwipeInfo, .actionBarTitle, .senderMiniAvatars:
            return ExteraProfileSettingsSection.chatList.rawValue
        }
    }

    var id: ExteraProfileSettingsEntryId {
        switch self {
        case .infoHeader: return .infoHeader
        case .hidePhoneNumber: return .hidePhoneNumber
        case .showIdAndDc: return .showIdAndDc
        case .showIdAndDcInfo: return .showIdAndDcInfo
        case .showCreationDate: return .showCreationDate
        case .showRegistrationDates: return .showRegistrationDates
        case .showOnlineIndicator: return .showOnlineIndicator
        case .showForwardsCount: return .showForwardsCount
        case .chatListHeader: return .chatListHeader
        case .hideArchiveFolder: return .hideArchiveFolder
        case .archiveOnPull: return .archiveOnPull
        case .disableUnarchiveSwipe: return .disableUnarchiveSwipe
        case .disableUnarchiveSwipeInfo: return .disableUnarchiveSwipeInfo
        case .actionBarTitle: return .actionBarTitle
        case .senderMiniAvatars: return .senderMiniAvatars
        }
    }

    var stableId: Int32 {
        return self.id.rawValue
    }

    static func <(lhs: ExteraProfileSettingsEntry, rhs: ExteraProfileSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraProfileSettingsArguments
        switch self {
        case let .infoHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .hidePhoneNumber(value):
            return exteraProfileSwitchItem(presentationData, title: exteraProfileString("Extera.Profile.HidePhoneNumber"), value: value, sectionId: self.section, updated: { value in
                arguments.update { $0.hidePhoneNumber = value }
            })
        case let .showIdAndDc(value):
            return exteraProfileSwitchItem(presentationData, title: exteraProfileString("Extera.Profile.ShowIdAndDc"), value: value, sectionId: self.section, updated: { value in
                arguments.update { $0.showIdAndDc = value }
            })
        case let .showIdAndDcInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .showCreationDate(value):
            return exteraProfileSwitchItem(presentationData, title: exteraProfileString("Extera.Profile.ShowCreationDate"), value: value, sectionId: self.section, updated: { value in
                arguments.update { $0.showCreationDate = value }
            })
        case let .showRegistrationDates(value):
            return exteraProfileSwitchItem(presentationData, title: exteraProfileString("Extera.Profile.ShowRegistrationDates"), value: value, sectionId: self.section, updated: { value in
                arguments.update { $0.showRegistrationDates = value }
            })
        case let .showOnlineIndicator(value):
            return exteraProfileSwitchItem(presentationData, title: exteraProfileString("Extera.Profile.ShowOnlineIndicator"), value: value, sectionId: self.section, updated: { value in
                arguments.update { $0.showOnlineIndicator = value }
            })
        case let .showForwardsCount(value):
            return exteraProfileSwitchItem(presentationData, title: exteraProfileString("Extera.Profile.ShowForwardsCount"), value: value, sectionId: self.section, updated: { value in
                arguments.update { $0.showForwardsCount = value }
            })
        case let .chatListHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .hideArchiveFolder(value):
            return exteraProfileSwitchItem(presentationData, title: exteraProfileString("Extera.Profile.HideArchiveFolder"), value: value, sectionId: self.section, updated: { value in
                arguments.update { $0.hideArchiveFolder = value }
            })
        case let .archiveOnPull(value):
            return exteraProfileSwitchItem(presentationData, title: exteraProfileString("Extera.Profile.ArchiveOnPull"), value: value, sectionId: self.section, updated: { value in
                arguments.update { $0.archiveOnPull = value }
            })
        case let .disableUnarchiveSwipe(value):
            return exteraProfileSwitchItem(presentationData, title: exteraProfileString("Extera.Profile.DisableUnarchiveSwipe"), value: value, sectionId: self.section, updated: { value in
                arguments.update { $0.disableUnarchiveSwipe = value }
            })
        case let .disableUnarchiveSwipeInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .actionBarTitle(label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: exteraProfileString("Extera.Profile.ActionBarTitle"), label: label, sectionId: self.section, style: .blocks, action: {
                arguments.openActionBarTitlePicker()
            })
        case let .senderMiniAvatars(value):
            return exteraProfileSwitchItem(presentationData, title: exteraProfileString("Extera.Profile.SenderMiniAvatars"), value: value, sectionId: self.section, updated: { value in
                arguments.update { $0.senderMiniAvatars = value }
            })
        }
    }
}

private func exteraProfileSwitchItem(_ presentationData: ItemListPresentationData, title: String, value: Bool, sectionId: ItemListSectionId, updated: @escaping (Bool) -> Void) -> ListViewItem {
    return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: sectionId, style: .blocks, updated: updated)
}

private func actionBarTitleLabel(value: ExteraChatListActionBarTitle) -> String {
    switch value {
    case .appName:
        return exteraProfileString("Extera.Profile.ActionBarTitleAppName")
    case .name:
        return exteraProfileString("Extera.Profile.ActionBarTitleName")
    case .username:
        return exteraProfileString("Extera.Profile.ActionBarTitleUsername")
    }
}

private func exteraProfileSettingsEntries(preferences: ExteraProfilePreferences) -> [ExteraProfileSettingsEntry] {
    return [
        .infoHeader(exteraProfileString("Extera.Profile.SectionInfo").uppercased()),
        .hidePhoneNumber(preferences.hidePhoneNumber),
        .showIdAndDc(preferences.showIdAndDc),
        .showIdAndDcInfo(exteraProfileString("Extera.Profile.ShowIdAndDcInfo")),
        .showCreationDate(preferences.showCreationDate),
        .showRegistrationDates(preferences.showRegistrationDates),
        .showOnlineIndicator(preferences.showOnlineIndicator),
        .showForwardsCount(preferences.showForwardsCount),
        .chatListHeader(exteraProfileString("Extera.Profile.SectionChatList").uppercased()),
        .hideArchiveFolder(preferences.hideArchiveFolder),
        .archiveOnPull(preferences.archiveOnPull),
        .disableUnarchiveSwipe(preferences.disableUnarchiveSwipe),
        .disableUnarchiveSwipeInfo(exteraProfileString("Extera.Profile.DisableUnarchiveSwipeInfo")),
        .actionBarTitle(label: actionBarTitleLabel(value: preferences.actionBarTitle)),
        .senderMiniAvatars(preferences.senderMiniAvatars)
    ]
}

private final class ExteraActionBarTitleArguments {
    let select: (ExteraChatListActionBarTitle) -> Void

    init(select: @escaping (ExteraChatListActionBarTitle) -> Void) {
        self.select = select
    }
}

private enum ExteraActionBarTitleEntry: ItemListNodeEntry {
    case appName(selected: Bool, String)
    case name(selected: Bool, String)
    case username(selected: Bool, String)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case .appName: return 0
        case .name: return 1
        case .username: return 2
        }
    }

    static func <(lhs: ExteraActionBarTitleEntry, rhs: ExteraActionBarTitleEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraActionBarTitleArguments
        let accentColor = presentationData.theme.list.itemAccentColor
        func row(_ value: ExteraChatListActionBarTitle, selected: Bool, label: String) -> ListViewItem {
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: label, label: selected ? "✓" : "", labelStyle: .coloredText(accentColor), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.select(value)
            })
        }
        switch self {
        case let .appName(selected, label):
            return row(.appName, selected: selected, label: label)
        case let .name(selected, label):
            return row(.name, selected: selected, label: label)
        case let .username(selected, label):
            return row(.username, selected: selected, label: label)
        }
    }
}

public func exteraProfileSettingsController(context: AccountContext) -> ViewController {
    let pushControllerImpl = Atomic<(ViewController) -> Void>(value: { _ in })

    let arguments = ExteraProfileSettingsArguments(
        update: { transform in
            var preferences = ExteraProfileSettings.shared.current
            transform(&preferences)
            ExteraProfileSettings.shared.update(preferences)
        },
        openActionBarTitlePicker: {
            pushControllerImpl.with { pushController in
                pushController(exteraActionBarTitlePickerController(context: context))
            }
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        ExteraProfileSettings.shared.preferencesSignal
    )
    |> deliverOnMainQueue
    |> map { presentationData, preferences -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(exteraProfileString("Extera.Profile.Title")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraProfileSettingsEntries(preferences: preferences), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal

    let _ = pushControllerImpl.swap({ [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    })
    return controller
}

private func exteraActionBarTitleEntries(preferences: ExteraProfilePreferences) -> [ExteraActionBarTitleEntry] {
    let currentValue = preferences.actionBarTitle
    return [
        .appName(selected: currentValue == .appName, exteraProfileString("Extera.Profile.ActionBarTitleAppName")),
        .name(selected: currentValue == .name, exteraProfileString("Extera.Profile.ActionBarTitleName")),
        .username(selected: currentValue == .username, exteraProfileString("Extera.Profile.ActionBarTitleUsername"))
    ]
}

private func exteraActionBarTitlePickerController(context: AccountContext) -> ViewController {
    let arguments = ExteraActionBarTitleArguments(select: { value in
        ExteraProfileSettings.shared.with { preferences -> ExteraProfilePreferences in
            var updated = preferences
            updated.actionBarTitle = value
            return updated
        }
    })

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        ExteraProfileSettings.shared.preferencesSignal
    )
    |> deliverOnMainQueue
    |> map { presentationData, currentValue -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(exteraProfileString("Extera.Profile.ActionBarTitle")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraActionBarTitleEntries(preferences: currentValue), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    return controller
}
