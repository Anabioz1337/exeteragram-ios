import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import TelegramPresentationData
import PresentationDataUtils
import ItemListUI
import ItemListPeerActionItem

private final class ExteraAIServiceListArguments {
    let openService: (ExteraAIServiceConfig) -> Void
    let addService: () -> Void

    init(openService: @escaping (ExteraAIServiceConfig) -> Void, addService: @escaping () -> Void) {
        self.openService = openService
        self.addService = addService
    }
}

private enum ExteraAIServiceListSection: Int32 {
    case list
    case add
}

private enum ExteraAIServiceListEntry: ItemListNodeEntry {
    case service(Int, PresentationTheme, String, String)
    case addAction(PresentationTheme, String)

    var section: ItemListSectionId {
        switch self {
        case .service:
            return ExteraAIServiceListSection.list.rawValue
        case .addAction:
            return ExteraAIServiceListSection.add.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case let .service(index, _, _, _):
            return Int32(index)
        case .addAction:
            return 1000
        }
    }

    static func ==(lhs: ExteraAIServiceListEntry, rhs: ExteraAIServiceListEntry) -> Bool {
        switch lhs {
        case let .service(lhsIndex, lhsTheme, lhsTitle, lhsLabel):
            if case let .service(rhsIndex, rhsTheme, rhsTitle, rhsLabel) = rhs, lhsIndex == rhsIndex, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsLabel == rhsLabel {
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

    static func <(lhs: ExteraAIServiceListEntry, rhs: ExteraAIServiceListEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraAIServiceListArguments
        switch self {
        case let .service(index, _, title, label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: label, labelStyle: .detailText, sectionId: self.section, style: .blocks, action: {
                let services = ExteraAIStore.shared.services
                guard index < services.count else {
                    return
                }
                arguments.openService(services[index])
            })
        case let .addAction(_, text):
            return ItemListPeerActionItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesItemList.plusIconImage(presentationData.theme), title: text, sectionId: self.section, height: .generic, color: .accent, editing: false, action: {
                arguments.addService()
            })
        }
    }
}

private func exteraAIServiceListEntries(state: [ExteraAIServiceConfig], presentationData: PresentationData) -> [ExteraAIServiceListEntry] {
    var entries: [ExteraAIServiceListEntry] = []
    for (index, service) in state.enumerated() {
        entries.append(.service(index, presentationData.theme, service.name, service.model))
    }
    entries.append(.addAction(presentationData.theme, presentationData.exteraAIString("Extera.AI.NewService")))
    return entries
}

public func exteraAIServiceListController(context: AccountContext, refreshed: @escaping () -> Void) -> ItemListController {
    let servicesPromise = Promise<[ExteraAIServiceConfig]>(ExteraAIStore.shared.services)
    let refreshServices: () -> Void = {
        servicesPromise.set(.single(ExteraAIStore.shared.services))
        refreshed()
    }

    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = ExteraAIServiceListArguments(
        openService: { service in
            pushControllerImpl?(exteraAIServiceEditController(context: context, service: service, refreshed: refreshServices))
        },
        addService: {
            pushControllerImpl?(exteraAIServiceEditController(context: context, service: ExteraAIServiceConfig(name: "", url: "", model: "", apiKey: ""), refreshed: refreshServices))
        }
    )

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, servicesPromise.get())
    |> map { presentationData, services -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(exteraAIString("Extera.AI.Services")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraAIServiceListEntries(state: services, presentationData: presentationData), style: .blocks)
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

private enum ExteraAIServiceTestState: Equatable {
    case idle
    case testing
    case passed
    case failed(title: String, info: String)
}

private final class ExteraAIServiceEditState: Equatable {
    var name: String
    var url: String
    var model: String
    var apiKey: String
    var testState: ExteraAIServiceTestState

    init(name: String, url: String, model: String, apiKey: String, testState: ExteraAIServiceTestState) {
        self.name = name
        self.url = url
        self.model = model
        self.apiKey = apiKey
        self.testState = testState
    }

    static func ==(lhs: ExteraAIServiceEditState, rhs: ExteraAIServiceEditState) -> Bool {
        return lhs.name == rhs.name && lhs.url == rhs.url && lhs.model == rhs.model && lhs.apiKey == rhs.apiKey && lhs.testState == rhs.testState
    }
}

private final class ExteraAIServiceEditArguments {
    let updateName: (String) -> Void
    let updateURL: (String) -> Void
    let updateModel: (String) -> Void
    let updateAPIKey: (String) -> Void
    let testAndSave: () -> Void
    let useService: () -> Void
    let deleteService: () -> Void

    init(
        updateName: @escaping (String) -> Void,
        updateURL: @escaping (String) -> Void,
        updateModel: @escaping (String) -> Void,
        updateAPIKey: @escaping (String) -> Void,
        testAndSave: @escaping () -> Void,
        useService: @escaping () -> Void,
        deleteService: @escaping () -> Void
    ) {
        self.updateName = updateName
        self.updateURL = updateURL
        self.updateModel = updateModel
        self.updateAPIKey = updateAPIKey
        self.testAndSave = testAndSave
        self.useService = useService
        self.deleteService = deleteService
    }
}

private enum ExteraAIServiceEditSection: Int32 {
    case fields
    case test
    case delete
}

private enum ExteraAIServiceEditEntry: ItemListNodeEntry {
    case name(PresentationTheme, NSAttributedString, String, String)
    case url(PresentationTheme, NSAttributedString, String, String)
    case model(PresentationTheme, NSAttributedString, String, String)
    case apiKey(PresentationTheme, NSAttributedString, String, String)
    case testAndSave(PresentationTheme, String)
    case testResult(PresentationTheme, String)
    case testResultInfo(String)
    case useService(PresentationTheme, String)
    case delete(PresentationTheme, String)

    var section: ItemListSectionId {
        switch self {
        case .name, .url, .model, .apiKey:
            return ExteraAIServiceEditSection.fields.rawValue
        case .testAndSave, .testResult, .testResultInfo, .useService:
            return ExteraAIServiceEditSection.test.rawValue
        case .delete:
            return ExteraAIServiceEditSection.delete.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .name:
            return 0
        case .url:
            return 1
        case .model:
            return 2
        case .apiKey:
            return 3
        case .testAndSave:
            return 4
        case .testResult:
            return 5
        case .testResultInfo:
            return 6
        case .useService:
            return 7
        case .delete:
            return 8
        }
    }

    static func ==(lhs: ExteraAIServiceEditEntry, rhs: ExteraAIServiceEditEntry) -> Bool {
        switch lhs {
        case let .name(lhsTheme, lhsTitle, lhsText, lhsPlaceholder):
            if case let .name(rhsTheme, rhsTitle, rhsText, rhsPlaceholder) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsText == rhsText, lhsPlaceholder == rhsPlaceholder {
                return true
            }
            return false
        case let .url(lhsTheme, lhsTitle, lhsText, lhsPlaceholder):
            if case let .url(rhsTheme, rhsTitle, rhsText, rhsPlaceholder) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsText == rhsText, lhsPlaceholder == rhsPlaceholder {
                return true
            }
            return false
        case let .model(lhsTheme, lhsTitle, lhsText, lhsPlaceholder):
            if case let .model(rhsTheme, rhsTitle, rhsText, rhsPlaceholder) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsText == rhsText, lhsPlaceholder == rhsPlaceholder {
                return true
            }
            return false
        case let .apiKey(lhsTheme, lhsTitle, lhsText, lhsPlaceholder):
            if case let .apiKey(rhsTheme, rhsTitle, rhsText, rhsPlaceholder) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsText == rhsText, lhsPlaceholder == rhsPlaceholder {
                return true
            }
            return false
        case let .testAndSave(lhsTheme, lhsText):
            if case let .testAndSave(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            }
            return false
        case let .testResult(lhsTheme, lhsText):
            if case let .testResult(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            }
            return false
        case let .testResultInfo(lhsText):
            if case .testResultInfo(lhsText) = rhs {
                return true
            }
            return false
        case let .useService(lhsTheme, lhsText):
            if case let .useService(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
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

    static func <(lhs: ExteraAIServiceEditEntry, rhs: ExteraAIServiceEditEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraAIServiceEditArguments
        switch self {
        case let .name(_, title, text, placeholder):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, placeholder: placeholder, sectionId: self.section, textUpdated: { value in
                arguments.updateName(value)
            }, action: {})
        case let .url(_, title, text, placeholder):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, placeholder: placeholder, sectionId: self.section, textUpdated: { value in
                arguments.updateURL(value)
            }, action: {})
        case let .model(_, title, text, placeholder):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, placeholder: placeholder, sectionId: self.section, textUpdated: { value in
                arguments.updateModel(value)
            }, action: {})
        case let .apiKey(_, title, text, placeholder):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, placeholder: placeholder, sectionId: self.section, textUpdated: { value in
                arguments.updateAPIKey(value)
            }, action: {})
        case let .testAndSave(_, text):
            return ItemListPeerActionItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesItemList.roundPlusIconImage(presentationData.theme), title: text, sectionId: self.section, height: .generic, color: .accent, editing: false, action: {
                arguments.testAndSave()
            })
        case let .testResult(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .testResultInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .useService(_, text):
            return ItemListPeerActionItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesItemList.checkIconImage(presentationData.theme), title: text, sectionId: self.section, height: .generic, color: .accent, editing: false, action: {
                arguments.useService()
            })
        case let .delete(_, text):
            return ItemListPeerActionItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesItemList.deleteIconImage(presentationData.theme), title: text, sectionId: self.section, height: .generic, color: .destructive, editing: false, action: {
                arguments.deleteService()
            })
        }
    }
}

private func exteraAIServiceEditTitle(_ text: String, presentationData: PresentationData) -> NSAttributedString {
    return NSAttributedString(string: text, attributes: [
        .font: Font.regular(presentationData.listsFontSize.itemListBaseFontSize),
        .foregroundColor: presentationData.theme.list.itemPrimaryTextColor
    ])
}

private func exteraAIServiceEditEntries(state: ExteraAIServiceEditState, presentationData: PresentationData) -> [ExteraAIServiceEditEntry] {
    var entries: [ExteraAIServiceEditEntry] = []
    entries.append(.name(presentationData.theme, exteraAIServiceEditTitle(exteraAIString("Extera.AI.ServiceName"), presentationData: presentationData), state.name, exteraAIString("Extera.AI.ServiceName")))
    entries.append(.url(presentationData.theme, exteraAIServiceEditTitle(exteraAIString("Extera.AI.ServiceURL"), presentationData: presentationData), state.url, "https://api.example.com/v1"))
    entries.append(.model(presentationData.theme, exteraAIServiceEditTitle(exteraAIString("Extera.AI.ServiceModel"), presentationData: presentationData), state.model, exteraAIString("Extera.AI.ServiceModel")))
    entries.append(.apiKey(presentationData.theme, exteraAIServiceEditTitle(exteraAIString("Extera.AI.ServiceKey"), presentationData: presentationData), state.apiKey, exteraAIString("Extera.AI.ServiceKey")))
    entries.append(.testAndSave(presentationData.theme, exteraAIString("Extera.AI.ServiceTestAndSave")))
    switch state.testState {
    case .idle:
        break
    case .testing:
        entries.append(.testResult(presentationData.theme, exteraAIString("Extera.AI.ResultGenerating")))
    case .passed:
        entries.append(.testResult(presentationData.theme, exteraAIString("Extera.AI.ServiceTestPassed")))
    case let .failed(title, info):
        entries.append(.testResult(presentationData.theme, exteraAIString("Extera.AI.ServiceTestFailed") + ": " + title))
        entries.append(.testResultInfo(info))
    }
    entries.append(.delete(presentationData.theme, exteraAIString("Extera.AI.DeleteService")))
    entries.append(.useService(presentationData.theme, exteraAIString("Extera.AI.UseService")))
    return entries
}

public func exteraAIServiceEditController(context: AccountContext, service: ExteraAIServiceConfig, refreshed: @escaping () -> Void) -> ItemListController {
    let isNew = !ExteraAIStore.shared.services.contains(where: { $0.id == service.id })
    var currentState = ExteraAIServiceEditState(name: service.name, url: service.url, model: service.model, apiKey: service.apiKey, testState: .idle)
    let statePromise = Promise<ExteraAIServiceEditState>(currentState)
    var testTask: Task<Void, Never>?
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?

    func refreshEntries(_ state: ExteraAIServiceEditState) {
        currentState = state
        statePromise.set(.single(state))
    }

    func updateState(_ transform: (inout ExteraAIServiceEditState) -> Void) {
        transform(&currentState)
        refreshEntries(currentState)
    }

    func persist(_ state: ExteraAIServiceEditState) -> ExteraAIServiceConfig {
        var services = ExteraAIStore.shared.services
        let updated = ExteraAIServiceConfig(id: service.id, name: state.name, url: state.url, model: state.model, apiKey: state.apiKey)
        if let index = services.firstIndex(where: { $0.id == service.id }) {
            services[index] = updated
        } else {
            services.append(updated)
        }
        ExteraAIStore.shared.services = services
        return updated
    }

    let arguments = ExteraAIServiceEditArguments(
        updateName: { value in
            updateState { $0.name = value }
        },
        updateURL: { value in
            updateState { $0.url = value }
        },
        updateModel: { value in
            updateState { $0.model = value }
        },
        updateAPIKey: { value in
            updateState { $0.apiKey = value }
        },
        testAndSave: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let current = currentState
            let config = ExteraAIServiceConfig(id: service.id, name: current.name, url: current.url, model: current.model, apiKey: current.apiKey)
            guard ExteraAIChatClient.endpoint(for: config) != nil, !config.model.isEmpty else {
                updateState {
                    $0.testState = .failed(title: presentationData.exteraAIString("Extera.AI.ErrorParsingTitle"), info: presentationData.exteraAIString("Extera.AI.ErrorParsingInfo"))
                }
                return
            }

            let duplicate = ExteraAIStore.shared.services.first(where: { $0.identity == config.identity && $0.id != config.id })
            if let duplicate {
                ExteraAIStore.shared.selectedServiceId = duplicate.id
                refreshEntries(ExteraAIServiceEditState(name: current.name, url: current.url, model: current.model, apiKey: current.apiKey, testState: .idle))
                presentControllerImpl?(textAlertController(context: context, title: presentationData.exteraAIString("Extera.AI.ServiceDuplicateTitle"), text: presentationData.exteraAIString("Extera.AI.ServiceDuplicateInfo"), actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
                    dismissImpl?()
                })]), nil)
                return
            }

            updateState { $0.testState = .testing }

            let saved = persist(current)
            let testSettings = ExteraAIGenerationSettings(temperature: 0.0, showReasoningTokens: false, responseStreaming: false, responseDisplay: .showResponseOnly)
            let client = ExteraAIChatClient()
            testTask = Task { @MainActor in
                do {
                    var produced = ""
                    for try await event in client.stream(service: saved, system: "Reply with the single word: OK", user: "Test", settings: testSettings) {
                        if case .content(let content) = event {
                            produced += content
                        }
                    }
                    if produced.isEmpty {
                        throw ExteraAIRequestFailure.emptyResponse
                    }
                    if ExteraAIStore.shared.services.first(where: { $0.id == config.id }) != nil {
                        ExteraAIStore.shared.selectedServiceId = config.id
                    }
                    updateState { $0.testState = .passed }
                    refreshed()
                } catch let failure as ExteraAIRequestFailure {
                    updateState {
                        $0.testState = .failed(title: exteraAIRequestErrorTexts(requestFailure: failure).title, info: exteraAIRequestErrorTexts(requestFailure: failure).info)
                    }
                } catch is CancellationError {
                } catch {
                    updateState {
                        $0.testState = .failed(title: presentationData.exteraAIString("Extera.AI.ErrorNetworkTitle"), info: presentationData.exteraAIString("Extera.AI.ErrorNetworkInfo"))
                    }
                }
            }
        },
        useService: {
            if !ExteraAIStore.shared.services.contains(where: { $0.id == service.id }) {
                let _ = persist(currentState)
            }
            ExteraAIStore.shared.selectedServiceId = service.id
            refreshed()
        },
        deleteService: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            presentControllerImpl?(textAlertController(context: context, title: nil, text: String(format: presentationData.exteraAIString("Extera.AI.DeleteServiceText"), service.name), actions: [
                TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {}),
                TextAlertAction(type: .destructiveAction, title: presentationData.exteraAIString("Extera.AI.DeleteService"), action: {
                    ExteraAIStore.shared.services = ExteraAIStore.shared.services.filter { $0.id != service.id }
                    if ExteraAIStore.shared.selectedServiceId == service.id {
                        ExteraAIStore.shared.selectedServiceId = nil
                    }
                    refreshed()
                    dismissImpl?()
                })
            ]), nil)
        }
    )

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let title = isNew ? presentationData.exteraAIString("Extera.AI.NewService") : presentationData.exteraAIString("Extera.AI.EditService")
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraAIServiceEditEntries(state: state, presentationData: presentationData), style: .blocks)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] target, animation in
        controller?.present(target, in: .window(.root), with: animation)
    }
    dismissImpl = { [weak controller] in
        testTask?.cancel()
        if let navigationController = controller?.navigationController as? NavigationController {
            let _ = navigationController.popViewController(animated: true)
        }
    }
    return controller
}
