import Foundation
import SwiftSignalKit
import Display
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import AccountContext
import ItemListUI
import PresentationDataUtils

private enum ExteraSwipeSettingsSection: Int32 {
    case behavior
    case folders
    case animations
}

private func currentExteraSwipeSettings(_ accountManager: AccountManager<TelegramAccountManagerTypes>) -> Signal<ExteraSwipeSettings, NoError> {
    return accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSwipeSettings])
    |> map { sharedData -> ExteraSwipeSettings in
        if let entry = sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSwipeSettings], let settings = entry.get(ExteraSwipeSettings.self) {
            return settings
        }
        return .defaultSettings
    }
}

private let exteraQuickTransitionsOptions: [(value: Double, label: (PresentationStrings) -> String)] = [
    (1.0, { $0.Extera_Swipe_Settings_Speed_Normal }),
    (0.7, { $0.Extera_Swipe_Settings_Speed_Fast }),
    (0.5, { $0.Extera_Swipe_Settings_Speed_VeryFast })
]

private let exteraPredictiveBackIntensityOptions: [(value: Double, label: (PresentationStrings) -> String)] = [
    (0.75, { $0.Extera_Swipe_Settings_Intensity_Low }),
    (1.0, { $0.Extera_Swipe_Settings_Intensity_Default }),
    (1.25, { $0.Extera_Swipe_Settings_Intensity_High }),
    (1.5, { $0.Extera_Swipe_Settings_Intensity_VeryHigh })
]

private func exteraOptionLabel(for value: Double, options: [(value: Double, label: (PresentationStrings) -> String)], strings: PresentationStrings) -> String {
    for option in options where abs(option.value - value) < 0.001 {
        return option.label(strings)
    }
    return options.first?.label(strings) ?? ""
}

private final class ExteraSwipeSettingsArguments {
    let updateEnableActions: (Bool) -> Void
    let updateLoop: (Bool) -> Void
    let updateReverse: (Bool) -> Void
    let updateFolderNavigation: (Bool) -> Void
    let updateGooeyAvatars: (Bool) -> Void
    let openSpeedPicker: () -> Void
    let openIntensityPicker: () -> Void

    init(updateEnableActions: @escaping (Bool) -> Void, updateLoop: @escaping (Bool) -> Void, updateReverse: @escaping (Bool) -> Void, updateFolderNavigation: @escaping (Bool) -> Void, updateGooeyAvatars: @escaping (Bool) -> Void, openSpeedPicker: @escaping () -> Void, openIntensityPicker: @escaping () -> Void) {
        self.updateEnableActions = updateEnableActions
        self.updateLoop = updateLoop
        self.updateReverse = updateReverse
        self.updateFolderNavigation = updateFolderNavigation
        self.updateGooeyAvatars = updateGooeyAvatars
        self.openSpeedPicker = openSpeedPicker
        self.openIntensityPicker = openIntensityPicker
    }
}

private enum ExteraSwipeSettingsEntry: ItemListNodeEntry {
    case behaviorHeader(String)
    case enableActions(Bool)
    case loop(Bool)
    case reverseScrolling(Bool)
    case foldersHeader(String)
    case folderNavigation(Bool)
    case animationsHeader(String)
    case gooeyAvatars(Bool)
    case quickTransitions(String)
    case predictiveBack(String)

    var section: ItemListSectionId {
        switch self {
        case .behaviorHeader, .enableActions, .loop, .reverseScrolling:
            return ExteraSwipeSettingsSection.behavior.rawValue
        case .foldersHeader, .folderNavigation:
            return ExteraSwipeSettingsSection.folders.rawValue
        case .animationsHeader, .gooeyAvatars, .quickTransitions, .predictiveBack:
            return ExteraSwipeSettingsSection.animations.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .behaviorHeader: return 0
        case .enableActions: return 1
        case .loop: return 2
        case .reverseScrolling: return 3
        case .foldersHeader: return 4
        case .folderNavigation: return 5
        case .animationsHeader: return 6
        case .gooeyAvatars: return 7
        case .quickTransitions: return 8
        case .predictiveBack: return 9
        }
    }

    static func <(lhs: ExteraSwipeSettingsEntry, rhs: ExteraSwipeSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraSwipeSettingsArguments
        switch self {
        case let .behaviorHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .enableActions(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Extera_Swipe_Settings_EnableActions, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateEnableActions(value)
            })
        case let .loop(isOn):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Extera_Swipe_Settings_Loop, value: isOn, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateLoop(value)
            })
        case let .reverseScrolling(isOn):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Extera_Swipe_Settings_ReverseScrolling, value: isOn, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateReverse(value)
            })
        case let .foldersHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .folderNavigation(isOn):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Extera_Swipe_Settings_FolderNavigation, value: isOn, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateFolderNavigation(value)
            })
        case let .animationsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .gooeyAvatars(isOn):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Extera_Swipe_Settings_GooeyAvatars, value: isOn, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateGooeyAvatars(value)
            })
        case let .quickTransitions(label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Extera_Swipe_Settings_QuickTransitions, label: label, sectionId: self.section, style: .blocks, action: {
                arguments.openSpeedPicker()
            })
        case let .predictiveBack(label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Extera_Swipe_Settings_PredictiveBack, label: label, sectionId: self.section, style: .blocks, action: {
                arguments.openIntensityPicker()
            })
        }
    }
}

private func exteraSwipeSettingsEntries(presentationData: PresentationData, settings: ExteraSwipeSettings) -> [ExteraSwipeSettingsEntry] {
    var entries: [ExteraSwipeSettingsEntry] = []
    entries.append(.behaviorHeader(presentationData.strings.Extera_Swipe_Settings_Header))
    entries.append(.enableActions(settings.areSwipeActionsEnabled))
    entries.append(.loop(settings.loopSwipeActions))
    entries.append(.reverseScrolling(settings.reverseSwipeScrolling))
    entries.append(.foldersHeader(presentationData.strings.Extera_Swipe_Settings_FoldersHeader))
    entries.append(.folderNavigation(settings.folderSwipeNavigation))
    entries.append(.animationsHeader(presentationData.strings.Extera_Swipe_Settings_AnimationsHeader))
    entries.append(.gooeyAvatars(settings.gooeyAvatars))
    entries.append(.quickTransitions(exteraOptionLabel(for: settings.quickTransitionsFactor, options: exteraQuickTransitionsOptions, strings: presentationData.strings)))
    entries.append(.predictiveBack(exteraOptionLabel(for: settings.predictiveBackIntensity, options: exteraPredictiveBackIntensityOptions, strings: presentationData.strings)))
    return entries
}

private final class ExteraSwipeOptionArguments {
    let select: (Int) -> Void

    init(select: @escaping (Int) -> Void) {
        self.select = select
    }
}

private enum ExteraSwipeOptionEntry: ItemListNodeEntry {
    case option(index: Int32, selected: Bool, label: String)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case let .option(index, _, _):
            return index
        }
    }

    static func <(lhs: ExteraSwipeOptionEntry, rhs: ExteraSwipeOptionEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraSwipeOptionArguments
        switch self {
        case let .option(_, selected, label):
            let accentColor = presentationData.theme.list.itemAccentColor
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: label, label: selected ? "✓" : "", labelStyle: .coloredText(accentColor), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.select(Int(self.stableId))
            })
        }
    }
}

private func exteraSwipeOptionPickerController(context: AccountContext, title: String, current: Double, options: [(value: Double, label: (PresentationStrings) -> String)], update: @escaping (Double) -> Void) -> ViewController {
    let arguments = ExteraSwipeOptionArguments(select: { index in
        guard index >= 0 && index < options.count else {
            return
        }
        update(options[index].value)
    })

    let signal = context.sharedContext.presentationData
    |> deliverOnMainQueue
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var entries: [ExteraSwipeOptionEntry] = []
        for (index, option) in options.enumerated() {
            entries.append(.option(index: Int32(index), selected: abs(option.value - current) < 0.001, label: option.label(presentationData.strings)))
        }
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    return controller
}

public func exteraSwipeSettingsController(context: AccountContext) -> ViewController {
    let pushControllerImpl = Atomic<(ViewController) -> Void>(value: { _ in })

    let arguments = ExteraSwipeSettingsArguments(
        updateEnableActions: { value in
            let _ = updateExteraSwipeSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedAreSwipeActionsEnabled(value) }).startStandalone()
        },
        updateLoop: { value in
            let _ = updateExteraSwipeSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedLoopSwipeActions(value) }).startStandalone()
        },
        updateReverse: { value in
            let _ = updateExteraSwipeSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedReverseSwipeScrolling(value) }).startStandalone()
        },
        updateFolderNavigation: { value in
            let _ = updateExteraSwipeSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedFolderSwipeNavigation(value) }).startStandalone()
        },
        updateGooeyAvatars: { value in
            let _ = updateExteraSwipeSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedGooeyAvatars(value) }).startStandalone()
        },
        openSpeedPicker: {
            let _ = (context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSwipeSettings])
            |> take(1)).start(next: { sharedData in
                let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSwipeSettings]?.get(ExteraSwipeSettings.self) ?? .defaultSettings
                let picker = exteraSwipeOptionPickerController(context: context, title: context.sharedContext.currentPresentationData.with({ $0 }).strings.Extera_Swipe_Settings_QuickTransitions, current: settings.quickTransitionsFactor, options: exteraQuickTransitionsOptions, update: { value in
                    let _ = updateExteraSwipeSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedQuickTransitionsFactor(value) }).startStandalone()
                })
                pushControllerImpl.with { impl in
                    impl(picker)
                }
            })
        },
        openIntensityPicker: {
            let _ = (context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSwipeSettings])
            |> take(1)).start(next: { sharedData in
                let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSwipeSettings]?.get(ExteraSwipeSettings.self) ?? .defaultSettings
                let picker = exteraSwipeOptionPickerController(context: context, title: context.sharedContext.currentPresentationData.with({ $0 }).strings.Extera_Swipe_Settings_PredictiveBack, current: settings.predictiveBackIntensity, options: exteraPredictiveBackIntensityOptions, update: { value in
                    let _ = updateExteraSwipeSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedPredictiveBackIntensity(value) }).startStandalone()
                })
                pushControllerImpl.with { impl in
                    impl(picker)
                }
            })
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        currentExteraSwipeSettings(context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(presentationData.strings.Extera_Swipe_Settings_Title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraSwipeSettingsEntries(presentationData: presentationData, settings: settings), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal

    let _ = pushControllerImpl.swap({ [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    })
    return controller
}
