import Foundation
import SwiftSignalKit
import Display
import UIKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import AccountContext
import ItemListUI
import PresentationDataUtils

private enum ExteraPluginEditorSection: Int32 {
    case meta
    case code
    case actions
}

final class ExteraPluginDraftState {
    var name: String
    var version: String
    var author: String
    var code: String

    init(name: String, version: String, author: String, code: String) {
        self.name = name
        self.version = version
        self.author = author
        self.code = code
    }
}

private final class ExteraPluginEditorArguments {
    let updateName: (String) -> Void
    let updateVersion: (String) -> Void
    let updateAuthor: (String) -> Void
    let openCodeEditor: () -> Void
    let test: () -> Void
    let save: () -> Void
    let remove: (() -> Void)?

    init(updateName: @escaping (String) -> Void, updateVersion: @escaping (String) -> Void, updateAuthor: @escaping (String) -> Void, openCodeEditor: @escaping () -> Void, test: @escaping () -> Void, save: @escaping () -> Void, remove: (() -> Void)?) {
        self.updateName = updateName
        self.updateVersion = updateVersion
        self.updateAuthor = updateAuthor
        self.openCodeEditor = openCodeEditor
        self.test = test
        self.save = save
        self.remove = remove
    }
}

private enum ExteraPluginEditorEntry: ItemListNodeEntry {
    case metaHeader(String)
    case name(String)
    case version(String)
    case author(String)
    case codeHeader(String)
    case codePreview(String)
    case editCode(String)
    case actionsHeader(String)
    case testAction(String)
    case saveAction(String)
    case removeAction

    var section: ItemListSectionId {
        switch self {
        case .metaHeader, .name, .version, .author:
            return ExteraPluginEditorSection.meta.rawValue
        case .codeHeader, .codePreview, .editCode:
            return ExteraPluginEditorSection.code.rawValue
        case .actionsHeader, .testAction, .saveAction, .removeAction:
            return ExteraPluginEditorSection.actions.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .metaHeader: return 0
        case .name: return 1
        case .version: return 2
        case .author: return 3
        case .codeHeader: return 4
        case .codePreview: return 5
        case .editCode: return 6
        case .actionsHeader: return 7
        case .testAction: return 8
        case .saveAction: return 9
        case .removeAction: return 10
        }
    }

    static func <(lhs: ExteraPluginEditorEntry, rhs: ExteraPluginEditorEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, draft: ExteraPluginDraftState, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraPluginEditorArguments
        switch self {
        case let .metaHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case .name(_):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(string: presentationData.strings.Extera_Plugins_Editor_Name, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: draft.name,
                placeholder: "",
                label: nil,
                type: .regular(capitalization: false, autocorrection: false),
                sectionId: self.section,
                style: .blocks,
                textUpdated: { arguments.updateName($0) },
                action: {}
            )
        case .version(_):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(string: presentationData.strings.Extera_Plugins_Editor_Version, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: draft.version,
                placeholder: "",
                label: nil,
                type: .regular(capitalization: false, autocorrection: false),
                sectionId: self.section,
                style: .blocks,
                textUpdated: { arguments.updateVersion($0) },
                action: {}
            )
        case .author(_):
            return ItemListSingleLineInputItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: NSAttributedString(string: presentationData.strings.Extera_Plugins_Editor_Author, textColor: presentationData.theme.list.itemPrimaryTextColor),
                text: draft.author,
                placeholder: "",
                label: nil,
                type: .regular(capitalization: false, autocorrection: false),
                sectionId: self.section,
                style: .blocks,
                textUpdated: { arguments.updateAuthor($0) },
                action: {}
            )
        case let .codeHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .codePreview(code):
            if code.isEmpty {
                return ItemListTextItem(presentationData: presentationData, text: .plain(presentationData.strings.Extera_Plugins_Editor_CodeEmpty), sectionId: self.section, style: .blocks)
            }
            let lines = code.components(separatedBy: "\n").prefix(12).joined(separator: "\n")
            return ItemListMultilineTextItem(
                presentationData: presentationData,
                text: .plain(lines + (code.components(separatedBy: "\n").count > 12 ? "\n…" : "")),
                enabledEntityTypes: [],
                sectionId: self.section,
                style: .blocks
            )
        case let .editCode(title):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: { arguments.openCodeEditor() }
            )
        case let .actionsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .testAction(title):
            return ItemListActionItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: { arguments.test() }
            )
        case let .saveAction(title):
            return ItemListActionItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: { arguments.save() }
            )
        case .removeAction:
            return ItemListActionItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: presentationData.strings.Extera_Plugins_RemoveConfirm,
                kind: .destructive,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: { arguments.remove?() }
            )
        }
    }
}

private func exteraPluginEditorEntries(presentationData: PresentationData, draft: ExteraPluginDraftState, isNew: Bool) -> [ExteraPluginEditorEntry] {
    var entries: [ExteraPluginEditorEntry] = []
    entries.append(.metaHeader(presentationData.strings.Extera_Plugins_Editor_MetaHeader))
    entries.append(.name(draft.name))
    entries.append(.version(draft.version))
    entries.append(.author(draft.author))
    entries.append(.codeHeader(presentationData.strings.Extera_Plugins_Editor_CodeHeader))
    entries.append(.codePreview(draft.code))
    entries.append(.editCode(presentationData.strings.Extera_Plugins_Editor_EditCode))
    entries.append(.actionsHeader(presentationData.strings.Extera_Plugins_Editor_ActionsHeader))
    entries.append(.testAction(presentationData.strings.Extera_Plugins_Editor_TestRun))
    if isNew {
        entries.append(.saveAction(presentationData.strings.Extera_Plugins_Editor_SaveNew))
    } else {
        entries.append(.saveAction(presentationData.strings.Extera_Plugins_Editor_SaveChanges))
        entries.append(.removeAction)
    }
    return entries
}

private func exteraPluginRemoveAlert(context: AccountContext, pluginName: String, remove: @escaping () -> Void) {
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let controller = textAlertController(
        context: context,
        title: presentationData.strings.Extera_Plugins_RemoveTitle,
        text: presentationData.strings.Extera_Plugins_RemoveText(pluginName),
        actions: [
            TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {}),
            TextAlertAction(type: .destructiveAction, title: presentationData.strings.Extera_Plugins_RemoveConfirm, action: { remove() })
        ]
    )
    context.sharedContext.presentGlobalController(controller, nil)
}

public func exteraPluginEditorScreen(context: AccountContext, existing: InstalledExteraPlugin?) -> ViewController {
    let initialDraft: ExteraPluginDraftState
    let pluginId: String
    let isNew: Bool
    if let existing {
        pluginId = existing.id
        initialDraft = ExteraPluginDraftState(name: existing.name, version: existing.version, author: existing.author, code: existing.sourceCode)
        isNew = false
    } else {
        pluginId = "user.\(Int(Date().timeIntervalSince1970 * 1000))"
        initialDraft = ExteraPluginDraftState(name: "", version: "1.0", author: "", code: "")
        isNew = true
    }

    let draft = Atomic<ExteraPluginDraftState>(value: initialDraft)
    let pushControllerImpl = Atomic<(ViewController) -> Void>(value: { _ in })

    let arguments = ExteraPluginEditorArguments(
        updateName: { value in
            draft.modify { $0.name = value.trimmingCharacters(in: .whitespacesAndNewlines) }
        },
        updateVersion: { value in
            draft.modify { $0.version = value.trimmingCharacters(in: .whitespacesAndNewlines) }
        },
        updateAuthor: { value in
            draft.modify { $0.author = value.trimmingCharacters(in: .whitespacesAndNewlines) }
        },
        openCodeEditor: {
            let editor = exteraPluginCodeScreen(context: context, code: draft.with({ $0 }).code, save: { code in
                draft.modify { $0.code = code }
            })
            pushControllerImpl.with { impl in
                impl(editor)
            }
        },
        test: {
            let current = draft.with { $0 }
            guard !current.code.isEmpty else {
                return
            }
            let (reply, error) = ExteraPluginsManager.testRun(
                sourceCode: current.code,
                sample: ("Привет! Это тестовое сообщение.", "Тестовый чат", 0)
            )
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let text: String
            if let error {
                text = error
            } else if let reply {
                text = presentationData.strings.Extera_Plugins_Editor_TestReply(reply)
            } else {
                text = presentationData.strings.Extera_Plugins_Editor_TestNoReply
            }
            let controller = UndoOverlayController(
                presentationData: presentationData,
                content: .info(title: current.name.isEmpty ? presentationData.strings.Extera_Plugins_Title : current.name, text: text, timeout: 4.0, customUndoText: nil),
                action: { _ in return false }
            )
            context.sharedContext.presentGlobalController(controller, nil)
        },
        save: {
            let current = draft.with { $0 }
            guard !current.name.isEmpty, !current.code.isEmpty else {
                return
            }
            let plugin = InstalledExteraPlugin(id: pluginId, name: current.name, version: current.version, author: current.author, sourceCode: current.code, enabled: true)
            let _ = updateExteraPluginsSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                return settings.withReplaced(plugin)
            }).startStandalone()
        },
        remove: isNew ? nil : {
            exteraPluginRemoveAlert(context: context, pluginName: draft.with({ $0 }).name, remove: {
                let _ = updateExteraPluginsSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                    return settings.withRemoved(pluginId)
                }).startStandalone()
            })
        }
    )

    let signal = context.sharedContext.presentationData
    |> deliverOnMainQueue
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(isNew ? presentationData.strings.Extera_Plugins_Editor_TitleNew : presentationData.strings.Extera_Plugins_Editor_TitleEdit),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: exteraPluginEditorEntries(presentationData: presentationData, draft: draft.with { $0 }, isNew: isNew),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    let _ = pushControllerImpl.swap({ [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    })
    return controller
}
