import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import TelegramPresentationData
import PresentationDataUtils
import ItemListUI
import ItemListPeerActionItem

private final class ExteraAIRoleListArguments {
    let openRole: (ExteraAIRoleConfig) -> Void
    let addRole: () -> Void

    init(openRole: @escaping (ExteraAIRoleConfig) -> Void, addRole: @escaping () -> Void) {
        self.openRole = openRole
        self.addRole = addRole
    }
}

private enum ExteraAIRoleListSection: Int32 {
    case list
    case add
}

private enum ExteraAIRoleListEntry: ItemListNodeEntry {
    case role(Int, PresentationTheme, String, String)
    case addAction(PresentationTheme, String)

    var section: ItemListSectionId {
        switch self {
        case .role:
            return ExteraAIRoleListSection.list.rawValue
        case .addAction:
            return ExteraAIRoleListSection.add.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case let .role(index, _, _, _):
            return Int32(index)
        case .addAction:
            return 1000
        }
    }

    static func ==(lhs: ExteraAIRoleListEntry, rhs: ExteraAIRoleListEntry) -> Bool {
        switch lhs {
        case let .role(lhsIndex, lhsTheme, lhsTitle, lhsLabel):
            if case let .role(rhsIndex, rhsTheme, rhsTitle, rhsLabel) = rhs, lhsIndex == rhsIndex, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsLabel == rhsLabel {
                return true
            }
            return false
        case let .addAction(lhsTheme, lhsText):
            if case let .addAction(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            }
            return false
        }
    }

    static func <(lhs: ExteraAIRoleListEntry, rhs: ExteraAIRoleListEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraAIRoleListArguments
        switch self {
        case let .role(index, _, title, label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: label, labelStyle: .detailText, sectionId: self.section, style: .blocks, action: {
                let roles = ExteraAIStore.shared.roles
                guard index < roles.count else {
                    return
                }
                arguments.openRole(roles[index])
            })
        case let .addAction(_, text):
            return ItemListPeerActionItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesItemList.plusIconImage(presentationData.theme), title: text, sectionId: self.section, height: .generic, color: .accent, editing: false, action: {
                arguments.addRole()
            })
        }
    }
}

private func exteraAIRoleListEntries(state: [ExteraAIRoleConfig], presentationData: PresentationData) -> [ExteraAIRoleListEntry] {
    var entries: [ExteraAIRoleListEntry] = []
    for (index, role) in state.enumerated() {
        let promptPreview = role.prompt.components(separatedBy: "\n").first ?? role.prompt
        entries.append(.role(index, presentationData.theme, role.name, promptPreview))
    }
    entries.append(.addAction(presentationData.theme, presentationData.exteraAIString("Extera.AI.NewRole")))
    return entries
}

public func exteraAIRoleListController(context: AccountContext, refreshed: @escaping () -> Void) -> ItemListController {
    let rolesPromise = Promise<[ExteraAIRoleConfig]>(ExteraAIStore.shared.roles)
    let refreshRoles: () -> Void = {
        rolesPromise.set(.single(ExteraAIStore.shared.roles))
        refreshed()
    }

    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = ExteraAIRoleListArguments(
        openRole: { role in
            pushControllerImpl?(exteraAIRoleEditController(context: context, role: role, refreshed: refreshRoles))
        },
        addRole: {
            pushControllerImpl?(exteraAIRoleEditController(context: context, role: ExteraAIRoleConfig(name: "", prompt: ""), refreshed: refreshRoles))
        }
    )

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, rolesPromise.get())
    |> map { presentationData, roles -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(presentationData.exteraAIString("Extera.AI.Roles")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraAIRoleListEntries(state: roles, presentationData: presentationData), style: .blocks)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] target in
        if let controller = controller {
            (controller.navigationController as? NavigationController)?.pushViewController(target)
        }
    }
    return controller
}

private final class ExteraAIRoleEditArguments {
    let updateName: (String) -> Void
    let updatePrompt: (String) -> Void
    let useRole: () -> Void
    let deleteRole: () -> Void

    init(
        updateName: @escaping (String) -> Void,
        updatePrompt: @escaping (String) -> Void,
        useRole: @escaping () -> Void,
        deleteRole: @escaping () -> Void
    ) {
        self.updateName = updateName
        self.updatePrompt = updatePrompt
        self.useRole = useRole
        self.deleteRole = deleteRole
    }
}

private enum ExteraAIRoleEditSection: Int32 {
    case fields
    case promptInfo
    case manage
}

private enum ExteraAIRoleEditEntry: ItemListNodeEntry {
    case name(PresentationTheme, NSAttributedString, String, String)
    case prompt(PresentationTheme, String, String)
    case promptInfo(String)
    case useRole(PresentationTheme, String)
    case delete(PresentationTheme, String)

    var section: ItemListSectionId {
        switch self {
        case .name, .prompt:
            return ExteraAIRoleEditSection.fields.rawValue
        case .promptInfo:
            return ExteraAIRoleEditSection.promptInfo.rawValue
        case .useRole, .delete:
            return ExteraAIRoleEditSection.manage.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .name:
            return 0
        case .prompt:
            return 1
        case .promptInfo:
            return 2
        case .useRole:
            return 3
        case .delete:
            return 4
        }
    }

    static func ==(lhs: ExteraAIRoleEditEntry, rhs: ExteraAIRoleEditEntry) -> Bool {
        switch lhs {
        case let .name(lhsTheme, lhsTitle, lhsText, lhsPlaceholder):
            if case let .name(rhsTheme, rhsTitle, rhsText, rhsPlaceholder) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsText == rhsText, lhsPlaceholder == rhsPlaceholder {
                return true
            }
            return false
        case let .prompt(lhsTheme, lhsText, lhsPlaceholder):
            if case let .prompt(rhsTheme, rhsText, rhsPlaceholder) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsPlaceholder == rhsPlaceholder {
                return true
            }
            return false
        case let .promptInfo(lhsText):
            if case .promptInfo(lhsText) = rhs {
                return true
            }
            return false
        case let .useRole(lhsTheme, lhsText):
            if case let .useRole(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            }
            return false
        case let .delete(lhsTheme, lhsText):
            if case let .delete(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            }
            return false
        }
    }

    static func <(lhs: ExteraAIRoleEditEntry, rhs: ExteraAIRoleEditEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraAIRoleEditArguments
        switch self {
        case let .name(_, title, text, placeholder):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, placeholder: placeholder, sectionId: self.section, textUpdated: { value in
                arguments.updateName(value)
            }, action: {})
        case let .prompt(_, text, placeholder):
            return ItemListMultilineInputItem(presentationData: presentationData, systemStyle: .glass, text: text, placeholder: placeholder, maxLength: nil, sectionId: self.section, style: .blocks, textUpdated: { value in
                arguments.updatePrompt(value)
            })
        case let .promptInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .useRole(_, text):
            return ItemListPeerActionItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesItemList.checkIconImage(presentationData.theme), title: text, sectionId: self.section, height: .generic, color: .accent, editing: false, action: {
                arguments.useRole()
            })
        case let .delete(_, text):
            return ItemListPeerActionItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesItemList.deleteIconImage(presentationData.theme), title: text, sectionId: self.section, height: .generic, color: .destructive, editing: false, action: {
                arguments.deleteRole()
            })
        }
    }
}

private struct ExteraAIRoleEditState: Equatable {
    var name: String
    var prompt: String
}

private func exteraAIRoleEditEntries(state: ExteraAIRoleEditState, presentationData: PresentationData) -> [ExteraAIRoleEditEntry] {
    var entries: [ExteraAIRoleEditEntry] = []
    entries.append(.name(presentationData.theme, NSAttributedString(string: exteraAIString("Extera.AI.RoleName"), attributes: [
        .font: Font.regular(presentationData.listsFontSize.itemListBaseFontSize),
        .foregroundColor: presentationData.theme.list.itemPrimaryTextColor
    ]), state.name, exteraAIString("Extera.AI.RoleName")))
    entries.append(.prompt(presentationData.theme, state.prompt, exteraAIString("Extera.AI.RolePrompt")))
    entries.append(.promptInfo(exteraAIString("Extera.AI.PromptInfo")))
    entries.append(.useRole(presentationData.theme, exteraAIString("Extera.AI.UseRole")))
    entries.append(.delete(presentationData.theme, exteraAIString("Extera.AI.DeleteRole")))
    return entries
}

public func exteraAIRoleEditController(context: AccountContext, role: ExteraAIRoleConfig, refreshed: @escaping () -> Void) -> ItemListController {
    var currentState = ExteraAIRoleEditState(name: role.name, prompt: role.prompt)

    func persist(_ state: ExteraAIRoleEditState) {
        var roles = ExteraAIStore.shared.roles
        let updated = ExteraAIRoleConfig(id: role.id, name: state.name, prompt: state.prompt)
        if let index = roles.firstIndex(where: { $0.id == role.id }) {
            roles[index] = updated
        } else {
            roles.append(updated)
        }
        ExteraAIStore.shared.roles = roles
    }

    let statePromise = Promise<ExteraAIRoleEditState>(currentState)

    func refreshEntries(_ state: ExteraAIRoleEditState) {
        currentState = state
        statePromise.set(.single(state))
    }

    func updateState(_ transform: (inout ExteraAIRoleEditState) -> Void) {
        transform(&currentState)
        refreshEntries(currentState)
        persist(currentState)
    }

    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    var dismissImpl: (() -> Void)?

    let arguments = ExteraAIRoleEditArguments(
        updateName: { value in
            updateState { $0.name = value }
        },
        updatePrompt: { value in
            updateState { $0.prompt = value }
        },
        useRole: {
            if !ExteraAIStore.shared.roles.contains(where: { $0.id == role.id }) {
                persist(currentState)
            }
            ExteraAIStore.shared.selectedRoleId = role.id
            refreshed()
        },
        deleteRole: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            presentControllerImpl?(textAlertController(context: context, title: nil, text: String(format: presentationData.exteraAIString("Extera.AI.DeleteRoleText"), role.name), actions: [
                TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {}),
                TextAlertAction(type: .destructiveAction, title: presentationData.exteraAIString("Extera.AI.DeleteRole"), action: {
                    ExteraAIStore.shared.roles = ExteraAIStore.shared.roles.filter { $0.id != role.id }
                    if ExteraAIStore.shared.selectedRoleId == role.id {
                        ExteraAIStore.shared.selectedRoleId = nil
                    }
                    refreshed()
                    dismissImpl?()
                })
            ]), nil)
        }
    )

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let title = state.name.isEmpty ? presentationData.exteraAIString("Extera.AI.NewRole") : presentationData.exteraAIString("Extera.AI.EditRole")
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraAIRoleEditEntries(state: state, presentationData: presentationData), style: .blocks)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] target, animation in
        controller?.present(target, in: .window(.root), with: animation)
    }
    dismissImpl = { [weak controller] in
        if let navigationController = controller?.navigationController as? NavigationController {
            let _ = navigationController.popViewController(animated: true)
        }
    }
    return controller
}
