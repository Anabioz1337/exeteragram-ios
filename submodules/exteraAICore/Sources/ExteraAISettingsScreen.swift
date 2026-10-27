import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import TelegramPresentationData
import PresentationDataUtils
import ItemListUI

private final class ExteraAISettingsArguments {
    let openServices: () -> Void
    let openRoles: () -> Void
    let openGeneration: () -> Void
    let toggleReplaceTelegramAI: (Bool) -> Void
    let showOnDeviceInfo: () -> Void

    init(
        openServices: @escaping () -> Void,
        openRoles: @escaping () -> Void,
        openGeneration: @escaping () -> Void,
        toggleReplaceTelegramAI: @escaping (Bool) -> Void,
        showOnDeviceInfo: @escaping () -> Void
    ) {
        self.openServices = openServices
        self.openRoles = openRoles
        self.openGeneration = openGeneration
        self.toggleReplaceTelegramAI = toggleReplaceTelegramAI
        self.showOnDeviceInfo = showOnDeviceInfo
    }
}

private enum ExteraAISettingsSection: Int32 {
    case main
    case onDevice
}

private enum ExteraAISettingsEntry: ItemListNodeEntry {
    case replaceTelegramAI(PresentationTheme, String, Bool)
    case replaceTelegramAIInfo(String)
    case services(PresentationTheme, String, String)
    case roles(PresentationTheme, String, String)
    case generation(PresentationTheme, String, String)
    case servicesInfo(String)
    case onDeviceHeader(PresentationTheme, String)
    case onDevice(PresentationTheme, String, String)
    case onDeviceInfo(String)

    var section: ItemListSectionId {
        switch self {
        case .replaceTelegramAI, .replaceTelegramAIInfo, .services, .roles, .generation, .servicesInfo:
            return ExteraAISettingsSection.main.rawValue
        case .onDeviceHeader, .onDevice, .onDeviceInfo:
            return ExteraAISettingsSection.onDevice.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .replaceTelegramAI:
            return 0
        case .replaceTelegramAIInfo:
            return 1
        case .services:
            return 2
        case .roles:
            return 3
        case .generation:
            return 4
        case .servicesInfo:
            return 5
        case .onDeviceHeader:
            return 6
        case .onDevice:
            return 7
        case .onDeviceInfo:
            return 8
        }
    }

    static func ==(lhs: ExteraAISettingsEntry, rhs: ExteraAISettingsEntry) -> Bool {
        switch lhs {
        case let .replaceTelegramAI(lhsTheme, lhsText, lhsValue):
            if case let .replaceTelegramAI(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            }
            return false
        case let .replaceTelegramAIInfo(lhsText):
            if case .replaceTelegramAIInfo(lhsText) = rhs {
                return true
            }
            return false
        case let .services(lhsTheme, lhsTitle, lhsLabel):
            if case let .services(rhsTheme, rhsTitle, rhsLabel) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsLabel == rhsLabel {
                return true
            }
            return false
        case let .roles(lhsTheme, lhsTitle, lhsLabel):
            if case let .roles(rhsTheme, rhsTitle, rhsLabel) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsLabel == rhsLabel {
                return true
            }
            return false
        case let .generation(lhsTheme, lhsTitle, lhsLabel):
            if case let .generation(rhsTheme, rhsTitle, rhsLabel) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsLabel == rhsLabel {
                return true
            }
            return false
        case let .servicesInfo(lhsText):
            if case .servicesInfo(lhsText) = rhs {
                return true
            }
            return false
        case let .onDeviceHeader(lhsTheme, lhsText):
            if case let .onDeviceHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            }
            return false
        case let .onDevice(lhsTheme, lhsTitle, lhsLabel):
            if case let .onDevice(rhsTheme, rhsTitle, rhsLabel) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsLabel == rhsLabel {
                return true
            }
            return false
        case let .onDeviceInfo(lhsText):
            if case .onDeviceInfo(lhsText) = rhs {
                return true
            }
            return false
        }
    }

    static func <(lhs: ExteraAISettingsEntry, rhs: ExteraAISettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraAISettingsArguments
        switch self {
        case let .replaceTelegramAI(_, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleReplaceTelegramAI(value)
            })
        case let .replaceTelegramAIInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .services(_, title, label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.aiTools, title: title, label: label, labelStyle: .detailText, sectionId: self.section, style: .blocks, action: {
                arguments.openServices()
            })
        case let .roles(_, title, label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.language, title: title, label: label, labelStyle: .detailText, sectionId: self.section, style: .blocks, action: {
                arguments.openRoles()
            })
        case let .generation(_, title, label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.dataAndStorage, title: title, label: label, labelStyle: .detailText, sectionId: self.section, style: .blocks, action: {
                arguments.openGeneration()
            })
        case let .servicesInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .onDeviceHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .onDevice(_, title, label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.powerSaving, title: title, label: label, labelStyle: .detailText, sectionId: self.section, style: .blocks, action: {
                arguments.showOnDeviceInfo()
            })
        case let .onDeviceInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private struct ExteraAISettingsState: Equatable {
    let services: [ExteraAIServiceConfig]
    let roles: [ExterraAIRoleConfig]
    let settings: ExteraAIGenerationSettings
    let selectedServiceId: String?
    let selectedRoleId: String?
    let replaceTelegramAI: Bool
    let onDeviceStatus: ExteraAIOnDeviceStatus

    static func current(store: ExteraAIStore) -> ExteraAISettingsState {
        return ExteraAISettingsState(
            services: store.services,
            roles: store.roles,
            settings: store.generationSettings,
            selectedServiceId: store.selectedServiceId,
            selectedRoleId: store.selectedRoleId,
            replaceTelegramAI: store.replaceTelegramAI,
            onDeviceStatus: exteraAIOnDeviceStatus()
        )
    }
}

private func exteraAISettingsEntries(state: ExteraAISettingsState, presentationData: PresentationData) -> [ExteraAISettingsEntry] {
    let strings = presentationData.strings
    var entries: [ExteraAISettingsEntry] = []

    let activeServiceName: String
    if state.selectedServiceId == exteraAIOnDeviceServiceId && state.onDeviceStatus == .ready {
        activeServiceName = strings.ExteraAI_OnDevice
    } else if let service = state.services.first(where: { $0.id == state.selectedServiceId }) ?? state.services.first {
        activeServiceName = service.name
    } else {
        activeServiceName = strings.ExteraAI_OnDevice
    }

    entries.append(.replaceTelegramAI(presentationData.theme, strings.ExteraAI_ReplaceTelegramTitle, state.replaceTelegramAI))
    entries.append(.replaceTelegramAIInfo(strings.ExteraAI_ReplaceTelegramInfo))
    entries.append(.services(presentationData.theme, strings.ExteraAI_ServicesTitle, activeServiceName))
    entries.append(.roles(presentationData.theme, strings.ExteraAI_Roles, state.roles.first(where: { $0.id == state.selectedRoleId })?.name ?? ""))
    entries.append(.generation(presentationData.theme, strings.ExteraAI_Generation, String(format: "%.1f", state.settings.temperature ?? 0.0)))
    entries.append(.servicesInfo(strings.ExteraAI_ServicesInfo))

    entries.append(.onDeviceHeader(presentationData.theme, strings.ExteraAI_OnDevice))
    entries.append(.onDevice(presentationData.theme, strings.ExteraAI_OnDevice, exteraAIOnDeviceStatusText(strings: strings, status: state.onDeviceStatus)))
    if state.onDeviceStatus != .ready {
        entries.append(.onDeviceInfo(strings.ExteraAI_OnDeviceUnavailableInfo))
    }

    return entries
}

public func exteraAISettingsController(context: AccountContext) -> ItemListController {
    let statePromise = Promise<ExteraAISettingsState>(ExteraAISettingsState.current(store: ExteraAIStore.shared))

    let refreshState: () -> Void = {
        statePromise.set(.single(ExteraAISettingsState.current(store: ExteraAIStore.shared)))
    }

    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?

    let arguments = ExteraAISettingsArguments(
        openServices: {
            pushControllerImpl?(exteraAIServiceListController(context: context, refreshed: refreshState))
        },
        openRoles: {
            pushControllerImpl?(exteraAIRoleListController(context: context, refreshed: refreshState))
        },
        openGeneration: {
            pushControllerImpl?(exteraAIGenerationController(context: context, refreshed: refreshState))
        },
        toggleReplaceTelegramAI: { value in
            ExteraAIStore.shared.replaceTelegramAI = value
            refreshState()
        },
        showOnDeviceInfo: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let status = exteraAIOnDeviceStatus()
            if status == .ready {
                ExteraAIStore.shared.selectedServiceId = exteraAIOnDeviceServiceId
                refreshState()
            } else {
                presentControllerImpl?(textAlertController(context: context, title: exteraAIOnDeviceStatusText(strings: presentationData.strings, status: status), text: presentationData.strings.ExteraAI_OnDeviceUnavailableInfo, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]), nil)
            }
        }
    )

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(presentationData.strings.ExteraAI_Title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraAISettingsEntries(state: state, presentationData: presentationData), style: .blocks)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] target in
        if let controller = controller {
            (controller.navigationController as? NavigationController)?.pushViewController(target)
        }
    }
    presentControllerImpl = { [weak controller] target, animation in
        controller?.present(target, in: .window(.root), with: animation)
    }

    return controller
}
