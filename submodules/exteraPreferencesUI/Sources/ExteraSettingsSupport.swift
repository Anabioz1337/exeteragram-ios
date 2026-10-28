import Foundation
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext

final class ExteraSettingsEditor {
    private let accountManager: AccountManager<TelegramAccountManagerTypes>

    init(accountManager: AccountManager<TelegramAccountManagerTypes>) {
        self.accountManager = accountManager
    }

    func update(_ transform: @escaping (ExteraSettings) -> ExteraSettings) {
        let _ = updateExteraSettingsInteractively(accountManager: self.accountManager, transform).start()
    }

    func set<Value>(_ keyPath: WritableKeyPath<ExteraSettings, Value>, _ value: Value) {
        self.update { $0.with(keyPath, value) }
    }

    func cycle(_ keyPath: WritableKeyPath<ExteraSettings, Int32>, values: [Int32], currentValue: Int32) {
        let index = values.firstIndex(of: currentValue) ?? values.indices.lowerBound
        self.set(keyPath, values[(index + 1) % values.count])
    }

    func apply(_ settings: ExteraSettings) {
        self.update { _ in settings }
    }

    func reset() {
        self.update { _ in ExteraSettings.defaultSettings }
    }
}

final class ExteraSettingsArguments {
    let editor: ExteraSettingsEditor
    let performAction: (Int, ExteraSettingsArguments) -> Void

    var pushController: (ViewController) -> Void = { _ in }
    var presentController: (ViewController) -> Void = { _ in }

    init(editor: ExteraSettingsEditor, performAction: @escaping (Int, ExteraSettingsArguments) -> Void) {
        self.editor = editor
        self.performAction = performAction
    }

    func set<Value>(_ keyPath: WritableKeyPath<ExteraSettings, Value>, _ value: Value) {
        self.editor.set(keyPath, value)
    }

    func cycle(_ keyPath: WritableKeyPath<ExteraSettings, Int32>, values: [Int32], currentValue: Int32) {
        self.editor.cycle(keyPath, values: values, currentValue: currentValue)
    }
}

enum ExteraSettingsEntry: ItemListNodeEntry {
    case header(id: Int32, sectionId: Int32, text: String)
    case toggle(id: Int32, sectionId: Int32, keyPath: WritableKeyPath<ExteraSettings, Bool>, title: String, value: Bool)
    case option(id: Int32, sectionId: Int32, keyPath: WritableKeyPath<ExteraSettings, Int32>, title: String, value: Int32, optionValues: [Int32], optionTitles: [String])
    case slider(id: Int32, sectionId: Int32, keyPath: WritableKeyPath<ExteraSettings, Int32>, title: String, value: Int32, maximumValue: Int32, leftText: String?, rightText: String?)
    case disclosure(id: Int32, sectionId: Int32, title: String)
    case footer(id: Int32, sectionId: Int32, text: String)
    case action(id: Int32, sectionId: Int32, title: String)

    var id: Int32 {
        switch self {
        case let .header(id, _, _):
            return id
        case let .toggle(id, _, _, _, _):
            return id
        case let .option(id, _, _, _, _, _, _):
            return id
        case let .slider(id, _, _, _, _, _, _, _):
            return id
        case let .disclosure(id, _, _):
            return id
        case let .footer(id, _, _):
            return id
        case let .action(id, _, _):
            return id
        }
    }

    var section: ItemListSectionId {
        switch self {
        case let .header(_, sectionId, _):
            return sectionId
        case let .toggle(_, sectionId, _, _, _):
            return sectionId
        case let .option(_, sectionId, _, _, _, _, _):
            return sectionId
        case let .slider(_, sectionId, _, _, _, _, _, _):
            return sectionId
        case let .disclosure(_, sectionId, _):
            return sectionId
        case let .footer(_, sectionId, _):
            return sectionId
        case let .action(_, sectionId, _):
            return sectionId
        }
    }

    var stableId: AnyHashable {
        return AnyHashable(self.id)
    }

    static func <(lhs: ExteraSettingsEntry, rhs: ExteraSettingsEntry) -> Bool {
        return lhs.id < rhs.id
    }

    static func ==(lhs: ExteraSettingsEntry, rhs: ExteraSettingsEntry) -> Bool {
        switch lhs {
        case let .header(lhsId, lhsSectionId, lhsText):
            if case let .header(rhsId, rhsSectionId, rhsText) = rhs, lhsId == rhsId, lhsSectionId == rhsSectionId, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .toggle(lhsId, lhsSectionId, lhsKeyPath, lhsTitle, lhsValue):
            if case let .toggle(rhsId, rhsSectionId, rhsKeyPath, rhsTitle, rhsValue) = rhs, lhsId == rhsId, lhsSectionId == rhsSectionId, lhsKeyPath == rhsKeyPath, lhsTitle == rhsTitle, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .option(lhsId, lhsSectionId, lhsKeyPath, lhsTitle, lhsValue, lhsOptionValues, lhsOptionTitles):
            if case let .option(rhsId, rhsSectionId, rhsKeyPath, rhsTitle, rhsValue, rhsOptionValues, rhsOptionTitles) = rhs, lhsId == rhsId, lhsSectionId == rhsSectionId, lhsKeyPath == rhsKeyPath, lhsTitle == rhsTitle, lhsValue == rhsValue, lhsOptionValues == rhsOptionValues, lhsOptionTitles == rhsOptionTitles {
                return true
            } else {
                return false
            }
        case let .slider(lhsId, lhsSectionId, lhsKeyPath, lhsTitle, lhsValue, lhsMaximumValue, lhsLeftText, lhsRightText):
            if case let .slider(rhsId, rhsSectionId, rhsKeyPath, rhsTitle, rhsValue, rhsMaximumValue, rhsLeftText, rhsRightText) = rhs, lhsId == rhsId, lhsSectionId == rhsSectionId, lhsKeyPath == rhsKeyPath, lhsTitle == rhsTitle, lhsValue == rhsValue, lhsMaximumValue == rhsMaximumValue, lhsLeftText == rhsLeftText, lhsRightText == rhsRightText {
                return true
            } else {
                return false
            }
        case let .disclosure(lhsId, lhsSectionId, lhsTitle):
            if case let .disclosure(rhsId, rhsSectionId, rhsTitle) = rhs, lhsId == rhsId, lhsSectionId == rhsSectionId, lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
        case let .footer(lhsId, lhsSectionId, lhsText):
            if case let .footer(rhsId, rhsSectionId, rhsText) = rhs, lhsId == rhsId, lhsSectionId == rhsSectionId, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .action(lhsId, lhsSectionId, lhsTitle):
            if case let .action(rhsId, rhsSectionId, rhsTitle) = rhs, lhsId == rhsId, lhsSectionId == rhsSectionId, lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraSettingsArguments
        switch self {
        case let .header(_, _, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .toggle(_, _, keyPath, title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.set(keyPath, value)
            })
        case let .option(_, _, keyPath, title, value, optionValues, optionTitles):
            let selectedIndex = max(0, min(optionTitles.count - 1, Int(optionValues.firstIndex(of: value) ?? 0)))
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: optionTitles[selectedIndex], labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.cycle(keyPath, values: optionValues, currentValue: value)
            })
        case let .slider(_, _, keyPath, title, value, maximumValue, leftText, rightText):
            return ExteraValueSliderItem(presentationData: presentationData, title: title, leftText: leftText, rightText: rightText, value: value, maximumValue: maximumValue, sectionId: self.section, updated: { value in
                arguments.set(keyPath, value)
            })
        case let .disclosure(_, _, title):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: "", labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.performAction(Int(self.id), arguments)
            })
        case let .footer(_, _, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .action(_, _, title):
            return ItemListActionItem(presentationData: presentationData, title: title, kind: .destructive, alignment: .center, sectionId: self.section, style: .blocks, action: {
                arguments.performAction(Int(self.id), arguments)
            })
        }
    }
}

func exteraLocalizedStrings(_ presentationData: PresentationData) -> ExteraStrings {
    return ExteraStrings(languageCode: presentationData.strings.primaryComponent.languageCode)
}

func exteraSettingsScreen(
    context: AccountContext,
    title: @escaping (PresentationData) -> String,
    performAction: @escaping (Int, ExteraSettingsArguments, PresentationData) -> Void,
    entries: @escaping (PresentationData, ExteraSettings) -> [ExteraSettingsEntry]
) -> ViewController {
    let editor = ExteraSettingsEditor(accountManager: context.sharedContext.accountManager)
    let arguments = ExteraSettingsArguments(editor: editor, performAction: { actionId, arguments in
        performAction(actionId, arguments, context.sharedContext.currentPresentationData.with { $0 })
    })

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSettings])
    )
    |> map { presentationData, sharedData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSettings]?.get(ExteraSettings.self) ?? ExteraSettings.defaultSettings

        let itemListPresentationData = ItemListPresentationData(presentationData)
        let controllerState = ItemListControllerState(presentationData: itemListPresentationData, title: .text(title(presentationData)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: itemListPresentationData, entries: entries(presentationData, settings), style: .blocks)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    arguments.pushController = { [weak controller] target in
        (controller?.navigationController as? NavigationController)?.pushViewController(target)
    }
    arguments.presentController = { [weak controller] target in
        controller?.present(target, in: .window(.root), with: nil)
    }

    return controller
}
