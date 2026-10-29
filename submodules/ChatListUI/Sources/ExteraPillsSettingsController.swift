import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import TelegramUIPreferences
import PresentationDataUtils
import ItemListUI
import AccountContext

private final class ExteraPillsSettingsArguments {
    let context: AccountContext
    let togglePill: (String) -> Void
    let updateInfiniteScrolling: (Bool) -> Void
    let openWeather: () -> Void
    let openCryptoTargetCurrency: () -> Void

    init(context: AccountContext, togglePill: @escaping (String) -> Void, updateInfiniteScrolling: @escaping (Bool) -> Void, openWeather: @escaping () -> Void, openCryptoTargetCurrency: @escaping () -> Void) {
        self.context = context
        self.togglePill = togglePill
        self.updateInfiniteScrolling = updateInfiniteScrolling
        self.openWeather = openWeather
        self.openCryptoTargetCurrency = openCryptoTargetCurrency
    }
}

private enum ExteraPillsSettingsSection: Int32 {
    case pills
    case scrolling
    case extras
}

private enum ExteraPillsSettingsEntryStableId: Hashable {
    case index(Int)
    case pill(String)
}

private final class ExteraPillsSettingsState: Equatable {
    let editing: Bool
    let revealedKind: String?

    init(editing: Bool, revealedKind: String?) {
        self.editing = editing
        self.revealedKind = revealedKind
    }

    static func ==(lhs: ExteraPillsSettingsState, rhs: ExteraPillsSettingsState) -> Bool {
        return lhs.editing == rhs.editing && lhs.revealedKind == rhs.revealedKind
    }

    func withUpdatedEditing(_ editing: Bool) -> ExteraPillsSettingsState {
        return ExteraPillsSettingsState(editing: editing, revealedKind: self.revealedKind)
    }

    func withUpdatedRevealedKind(_ revealedKind: String?) -> ExteraPillsSettingsState {
        return ExteraPillsSettingsState(editing: self.editing, revealedKind: revealedKind)
    }
}

private func pillTitle(kind: String) -> String {
    switch kind {
    case "weather":
        return exteraPillString("extera_WeatherPill")
    case "crypto":
        return exteraPillString("extera_CryptoCoin")
    default:
        return exteraPillString("extera_Pill\(kind.prefix(1).uppercased())\(kind.dropFirst())")
    }
}

private enum ExteraPillsSettingsEntry: ItemListNodeEntry {
    case pillsHeader(String)
    case activeHeader(String)
    case hiddenHeader(String)
    case pill(kind: String, title: String, hidden: Bool, editing: Bool)
    case infiniteScrolling(String, Bool)
    case pillsInfo(String)
    case weather(String)
    case cryptoTargetCurrency(String, String)

    var section: ItemListSectionId {
        switch self {
        case .pillsHeader, .activeHeader, .hiddenHeader, .pill, .pillsInfo:
            return ExteraPillsSettingsSection.pills.rawValue
        case .infiniteScrolling:
            return ExteraPillsSettingsSection.scrolling.rawValue
        case .weather, .cryptoTargetCurrency:
            return ExteraPillsSettingsSection.extras.rawValue
        }
    }

    var stableId: ExteraPillsSettingsEntryStableId {
        switch self {
        case .pillsHeader:
            return .index(0)
        case .activeHeader:
            return .index(1)
        case .hiddenHeader:
            return .index(2)
        case let .pill(kind, _, _, _):
            return .pill(kind)
        case .infiniteScrolling:
            return .index(3)
        case .pillsInfo:
            return .index(4)
        case .weather:
            return .index(5)
        case .cryptoTargetCurrency:
            return .index(6)
        }
    }

    static func ==(lhs: ExteraPillsSettingsEntry, rhs: ExteraPillsSettingsEntry) -> Bool {
        switch lhs {
        case let .pillsHeader(text):
            if case let .pillsHeader(rhsText) = rhs, text == rhsText {
                return true
            }
        case let .activeHeader(text):
            if case let .activeHeader(rhsText) = rhs, text == rhsText {
                return true
            }
        case let .hiddenHeader(text):
            if case let .hiddenHeader(rhsText) = rhs, text == rhsText {
                return true
            }
        case let .pill(kind, title, hidden, editing):
            if case let .pill(rhsKind, rhsTitle, rhsHidden, rhsEditing) = rhs, kind == rhsKind, title == rhsTitle, hidden == rhsHidden, editing == rhsEditing {
                return true
            }
        case let .infiniteScrolling(title, value):
            if case let .infiniteScrolling(rhsTitle, rhsValue) = rhs, title == rhsTitle, value == rhsValue {
                return true
            }
        case let .pillsInfo(text):
            if case let .pillsInfo(rhsText) = rhs, text == rhsText {
                return true
            }
        case let .weather(text):
            if case let .weather(rhsText) = rhs, text == rhsText {
                return true
            }
        case let .cryptoTargetCurrency(title, label):
            if case let .cryptoTargetCurrency(rhsTitle, rhsLabel) = rhs, title == rhsTitle, label == rhsLabel {
                return true
            }
        }
        return false
    }

    static func <(lhs: ExteraPillsSettingsEntry, rhs: ExteraPillsSettingsEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    private var sortIndex: Int {
        switch self {
        case .pillsHeader: return 0
        case .activeHeader: return 1
        case .pill: return 10
        case .hiddenHeader: return 1000000
        case .infiniteScrolling: return 2000000
        case .pillsInfo: return 2000001
        case .weather: return 3000000
        case .cryptoTargetCurrency: return 3000001
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraPillsSettingsArguments
        switch self {
        case let .pillsHeader(text), let .activeHeader(text), let .hiddenHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .pill(kind, title, hidden, editing):
            return ExteraPillRowItem(
                presentationData: presentationData,
                title: title,
                hidden: hidden,
                canBeReordered: true,
                editing: ExteraPillRowEditing(editable: true, editing: editing),
                sectionId: self.section,
                action: {
                    arguments.togglePill(kind)
                }
            )
        case let .infiniteScrolling(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                arguments.updateInfiniteScrolling(updatedValue)
            })
        case let .pillsInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .weather(label):
            return ItemListDisclosureItem(presentationData: presentationData, title: exteraPillString("extera_WeatherPill"), label: label, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openWeather()
            })
        case let .cryptoTargetCurrency(title, label):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label: label, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openCryptoTargetCurrency()
            })
        }
    }
}

private func exteraPillsSettingsEntries(presentationData: PresentationData, settings: ExteraPillStackSettings, state: ExteraPillsSettingsState) -> [ExteraPillsSettingsEntry] {
    var entries: [ExteraPillsSettingsEntry] = []
    entries.append(.activeHeader(exteraPillString("extera_PillStackActivePills")))
    for kind in settings.visiblePills {
        entries.append(.pill(kind: kind, title: pillTitle(kind: kind), hidden: false, editing: state.editing))
    }
    entries.append(.hiddenHeader(exteraPillString("extera_PillStackHiddenPills")))
    for kind in settings.hiddenPills {
        entries.append(.pill(kind: kind, title: pillTitle(kind: kind), hidden: true, editing: state.editing))
    }
    entries.append(.infiniteScrolling(exteraPillString("extera_PillStackInfiniteScrolling"), settings.infiniteScrolling))
    entries.append(.pillsInfo(exteraPillString("extera_PillStackPillsSettingsInfo")))

    let weatherLabel: String
    if let location = settings.weatherLocation, location.source == .manual, let title = location.title, !title.isEmpty {
        weatherLabel = title
    } else if settings.weatherLocation != nil {
        weatherLabel = exteraPillString("extera_CurrentLocation")
    } else {
        weatherLabel = exteraPillString("extera_WeatherLocation")
    }
    entries.append(.weather(weatherLabel))
    entries.append(.cryptoTargetCurrency(exteraPillString("extera_CryptoPillTargetCurrency"), cryptoTargetCurrencyLabel(settings.cryptoTargetCurrency)))
    return entries
}

private func cryptoTargetCurrencyLabel(_ currency: ExteraCryptoPillTargetCurrency) -> String {
    switch currency {
    case .btc: return "BTC"
    case .eth: return "ETH"
    case .usd: return "USDT"
    }
}

public func exteraPillsSettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?

    let statePromise = ValuePromise<ExteraPillsSettingsState>()
    var stateValue = ExteraPillsSettingsState(editing: false, revealedKind: nil)
    let updateState: ((ExteraPillsSettingsState) -> (ExteraPillsSettingsState)) -> Void = { f in
        stateValue = f(stateValue)
        statePromise.set(stateValue)
    }

    let arguments = ExteraPillsSettingsArguments(context: context, togglePill: { kind in
        let _ = updateExteraPillStackSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
            if settings.hiddenPills.contains(kind) {
                return settings.withUpdatedHiddenPills(settings.hiddenPills.filter({ $0 != kind }))
            } else {
                return settings.withUpdatedHiddenPills(settings.hiddenPills + [kind])
            }
        }).start()
    }, updateInfiniteScrolling: { value in
        let _ = updateExteraPillStackSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedInfiniteScrolling(value) }).start()
    }, openWeather: {
        pushControllerImpl?(exteraPillWeatherSettingsController(context: context))
    }, openCryptoTargetCurrency: {
        pushControllerImpl?(exteraPillCryptoCurrencyController(context: context))
    })

    let settingsSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraPillStackSettings])
    |> map { sharedData -> ExteraPillStackSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.exteraPillStackSettings]?.get(ExteraPillStackSettings.self) ?? .defaultSettings
    }
    |> distinctUntilChanged

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, settingsSignal, statePromise.get())
    |> map { presentationData, settings, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let editButton: ItemListNavigationButton
        if state.editing {
            editButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Done), style: .bold, enabled: true, action: {
                updateState { $0.withUpdatedEditing(false) }
            })
        } else {
            editButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Edit), style: .regular, enabled: true, action: {
                updateState { $0.withUpdatedEditing(true) }
            })
        }
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(exteraPillString("extera_PillStackPills")), leftNavigationButton: nil, rightNavigationButton: editButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraPillsSettingsEntries(presentationData: presentationData, settings: settings, state: state), style: .blocks)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] value in
        controller?.push(value)
    }
    controller.setReorderEntry({ fromIndex, toIndex, entries -> Signal<Bool, NoError> in
        guard case let .pill(fromKind, _, _, _) = entries[fromIndex] else {
            return .single(false)
        }

        var rows: [(kind: String, hidden: Bool)] = []
        for entry in entries {
            if case let .pill(kind, _, hidden, _) = entry {
                rows.append((kind, hidden))
            }
        }
        guard let fromRowIndex = rows.firstIndex(where: { $0.kind == fromKind }) else {
            return .single(false)
        }

        var targetHidden = false
        var referenceKind: String?
        if toIndex < entries.count {
            if case let .pill(kind, _, hidden, _) = entries[toIndex] {
                referenceKind = kind
                targetHidden = hidden
            } else {
                targetHidden = toIndex > fromRowIndex
            }
        } else {
            targetHidden = rows.last?.hidden ?? false
        }

        var updatedRows = rows
        let moved = updatedRows.remove(at: fromRowIndex)
        updatedRows.insert((fromKind, moved.hidden), at: 0)

        var insertionIndex = updatedRows.count
        if let referenceKind {
            if let index = updatedRows.firstIndex(where: { $0.kind == referenceKind }) {
                insertionIndex = fromRowIndex < toIndex ? index + 1 : index
            }
        }
        insertionIndex = max(0, min(insertionIndex, updatedRows.count))
        updatedRows.insert((fromKind, targetHidden), at: insertionIndex)

        let initialActiveOrder = rows.filter({ !$0.hidden }).map({ $0.kind })
        let initialHiddenOrder = rows.filter({ $0.hidden }).map({ $0.kind })

        let updatedActiveOrder = updatedRows.filter({ !$0.hidden }).map({ $0.kind })
        let updatedHiddenOrder = updatedRows.filter({ $0.hidden }).map({ $0.kind })

        if initialActiveOrder == updatedActiveOrder && initialHiddenOrder == updatedHiddenOrder {
            return .single(false)
        }

        let _ = updateExteraPillStackSettingsInteractively(accountManager: context.sharedContext.accountManager, { currentSettings in
            let untouchedActive = currentSettings.activePills.filter({ !updatedActiveOrder.contains($0) && !currentSettings.hiddenPills.contains($0) })
            return currentSettings.withUpdatedActivePills(updatedActiveOrder + untouchedActive).withUpdatedHiddenPills(updatedHiddenOrder)
        }).start()

        return .single(true)
    })
    controller.setReorderCompleted({ _ in
    })

    return controller
}
