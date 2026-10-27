import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import TelegramUIPreferences
import PresentationDataUtils
import ItemListUI
import AccountContext
import ExteraSearchToolkit

private final class ExteraInlineResultsSettingsArguments {
    let context: AccountContext

    let updateShowResults: (Bool) -> Void
    let updateCalculator: (Bool) -> Void
    let updateCurrencies: (Bool) -> Void
    let updateUnits: (Bool) -> Void
    let updateTimeZones: (Bool) -> Void
    let updateDigitGrouping: (Bool) -> Void
    let updateAngleUnit: () -> Void
    let updateMeasureSystem: () -> Void
    let openDefaultCurrency: () -> Void

    init(context: AccountContext, updateShowResults: @escaping (Bool) -> Void, updateCalculator: @escaping (Bool) -> Void, updateCurrencies: @escaping (Bool) -> Void, updateUnits: @escaping (Bool) -> Void, updateTimeZones: @escaping (Bool) -> Void, updateDigitGrouping: @escaping (Bool) -> Void, updateAngleUnit: @escaping () -> Void, updateMeasureSystem: @escaping () -> Void, openDefaultCurrency: @escaping () -> Void) {
        self.context = context
        self.updateShowResults = updateShowResults
        self.updateCalculator = updateCalculator
        self.updateCurrencies = updateCurrencies
        self.updateUnits = updateUnits
        self.updateTimeZones = updateTimeZones
        self.updateDigitGrouping = updateDigitGrouping
        self.updateAngleUnit = updateAngleUnit
        self.updateMeasureSystem = updateMeasureSystem
        self.openDefaultCurrency = openDefaultCurrency
    }
}

private enum ExteraInlineResultsSettingsSection: Int32 {
    case results
    case features
    case values
    case capabilities
}

private enum ExteraInlineResultsSettingsEntry: ItemListNodeEntry {
    case showResults(Bool)
    case resultsInfo(String)
    case featuresHeader(String)
    case calculator(Bool)
    case currencies(Bool)
    case units(Bool)
    case timeZones(Bool)
    case defaultCurrency(String)
    case autoCurrencyInfo(String)
    case angleUnit(String)
    case measureSystem(String)
    case digitGrouping(Bool)
    case docTitle(String)
    case docText(String)

    var section: ItemListSectionId {
        switch self {
        case .showResults, .resultsInfo:
            return ExteraInlineResultsSettingsSection.results.rawValue
        case .featuresHeader, .calculator, .currencies, .units, .timeZones:
            return ExteraInlineResultsSettingsSection.features.rawValue
        case .defaultCurrency, .autoCurrencyInfo, .angleUnit, .measureSystem, .digitGrouping:
            return ExteraInlineResultsSettingsSection.values.rawValue
        case .docTitle, .docText:
            return ExteraInlineResultsSettingsSection.capabilities.rawValue
        }
    }

    var sortId: Int {
        switch self {
        case .showResults: return 1000
        case .resultsInfo: return 1001
        case .featuresHeader: return 2000
        case .calculator: return 2001
        case .currencies: return 2002
        case .units: return 2003
        case .timeZones: return 2004
        case .defaultCurrency: return 3000
        case .autoCurrencyInfo: return 3001
        case .angleUnit: return 3002
        case .measureSystem: return 3003
        case .digitGrouping: return 3004
        case .docTitle: return 4000
        case .docText: return 4001
        }
    }

    var stableId: Int {
        return self.sortId
    }

    static func ==(lhs: ExteraInlineResultsSettingsEntry, rhs: ExteraInlineResultsSettingsEntry) -> Bool {
        switch lhs {
        case let .showResults(value):
            if case let .showResults(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .resultsInfo(text):
            if case let .resultsInfo(rhsText) = rhs, text == rhsText {
                return true
            }
        case let .featuresHeader(text):
            if case let .featuresHeader(rhsText) = rhs, text == rhsText {
                return true
            }
        case let .calculator(value):
            if case let .calculator(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .currencies(value):
            if case let .currencies(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .units(value):
            if case let .units(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .timeZones(value):
            if case let .timeZones(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .defaultCurrency(value):
            if case let .defaultCurrency(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .autoCurrencyInfo(text):
            if case let .autoCurrencyInfo(rhsText) = rhs, text == rhsText {
                return true
            }
        case let .angleUnit(value):
            if case let .angleUnit(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .measureSystem(value):
            if case let .measureSystem(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .digitGrouping(value):
            if case let .digitGrouping(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .docTitle(text):
            if case let .docTitle(rhsText) = rhs, text == rhsText {
                return true
            }
        case let .docText(text):
            if case let .docText(rhsText) = rhs, text == rhsText {
                return true
            }
        }
        return false
    }

    static func <(lhs: ExteraInlineResultsSettingsEntry, rhs: ExteraInlineResultsSettingsEntry) -> Bool {
        return lhs.sortId < rhs.sortId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraInlineResultsSettingsArguments
        let strings = presentationData.strings
        switch self {
        case let .showResults(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraPillString("extera_InlineShowResults"), value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                arguments.updateShowResults(updatedValue)
            })
        case let .resultsInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .featuresHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .calculator(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraPillString("extera_InlineCalculator"), value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                arguments.updateCalculator(updatedValue)
            })
        case let .currencies(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraPillString("extera_InlineCurrencies"), value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                arguments.updateCurrencies(updatedValue)
            })
        case let .units(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraPillString("extera_InlineUnits"), value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                arguments.updateUnits(updatedValue)
            })
        case let .timeZones(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraPillString("extera_InlineTimeZones"), value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                arguments.updateTimeZones(updatedValue)
            })
        case let .defaultCurrency(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: exteraPillString("extera_InlineDefaultCurrency"), label: value, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openDefaultCurrency()
            })
        case let .autoCurrencyInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .angleUnit(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: exteraPillString("extera_InlineAngleUnit"), label: value, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.updateAngleUnit()
            })
        case let .measureSystem(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: exteraPillString("extera_InlineMeasureSystem"), label: value, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.updateMeasureSystem()
            })
        case let .digitGrouping(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraPillString("extera_InlineDigitGrouping"), value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                arguments.updateDigitGrouping(updatedValue)
            })
        case let .docTitle(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .docText(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func exteraInlineResultsSettingsEntries(presentationData: PresentationData, settings: ExteraInlineResultsSettings) -> [ExteraInlineResultsSettingsEntry] {
    let strings = presentationData.strings
    var entries: [ExteraInlineResultsSettingsEntry] = []
    
    entries.append(.showResults(settings.showResults))
    entries.append(.resultsInfo(exteraPillString("extera_InlineMathResultInfo")))
    
    entries.append(.featuresHeader(exteraPillString("extera_InlineFeatures")))
    entries.append(.calculator(settings.calculatorEnabled))
    entries.append(.currencies(settings.currenciesEnabled))
    entries.append(.units(settings.unitsEnabled))
    entries.append(.timeZones(settings.timeZonesEnabled))
    
    entries.append(.defaultCurrency(settings.defaultCurrency.isEmpty ? "Auto" : settings.defaultCurrency))
    entries.append(.autoCurrencyInfo(exteraPillString("extera_InlineAutoCurrencyInfo")))
    entries.append(.angleUnit(settings.angleUnit == .degrees ? exteraPillString("extera_InlineAngleDegrees") : exteraPillString("extera_InlineAngleRadians")))
    entries.append(.measureSystem(settings.measureSystem == .metric ? exteraPillString("extera_InlineMeasureMetric") : exteraPillString("extera_InlineMeasureImperial")))
    entries.append(.digitGrouping(settings.digitGrouping))
    
    entries.append(.docTitle(exteraPillString("extera_InlineDocArithmetic")))
    entries.append(.docText(exteraPillString("extera_InlineDocArithmeticInfo") + ". " + exteraPillString("extera_InlineDocFunctionsText") + " " + exteraPillString("extera_InlineDocPercentText") + " " + exteraPillString("extera_InlineDocShorthandsText")))
    entries.append(.docTitle(exteraPillString("extera_InlineDocCurrenciesInfo")))
    entries.append(.docText(exteraPillString("extera_InlineDocCurrencyText")))
    entries.append(.docTitle(exteraPillString("extera_InlineDocUnitsInfo")))
    entries.append(.docText(exteraPillString("extera_InlineDocUnitsText")))
    entries.append(.docTitle(exteraPillString("extera_InlineDocTimeInfo")))
    entries.append(.docText(exteraPillString("extera_InlineDocTimeText")))
    
    return entries
}

public func exteraInlineResultsSettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    
    let arguments = ExteraInlineResultsSettingsArguments(context: context, updateShowResults: { value in
        let _ = updateExteraInlineResultsSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedShowResults(value) }).start()
    }, updateCalculator: { value in
        let _ = updateExteraInlineResultsSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedCalculatorEnabled(value) }).start()
    }, updateCurrencies: { value in
        let _ = updateExteraInlineResultsSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedCurrenciesEnabled(value) }).start()
    }, updateUnits: { value in
        let _ = updateExteraInlineResultsSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedUnitsEnabled(value) }).start()
    }, updateTimeZones: { value in
        let _ = updateExteraInlineResultsSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedTimeZonesEnabled(value) }).start()
    }, updateDigitGrouping: { value in
        let _ = updateExteraInlineResultsSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedDigitGrouping(value) }).start()
    }, updateAngleUnit: {
        let _ = updateExteraInlineResultsSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings -> ExteraInlineResultsSettings in
            return settings.withUpdatedAngleUnit(settings.angleUnit == .degrees ? .radians : .degrees)
        }).start()
    }, updateMeasureSystem: {
        let _ = updateExteraInlineResultsSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings -> ExteraInlineResultsSettings in
            return settings.withUpdatedMeasureSystem(settings.measureSystem == .metric ? .imperial : .metric)
        }).start()
    }, openDefaultCurrency: {
        pushControllerImpl?(exteraInlineDefaultCurrencyController(context: context))
    })
    
    let settingsSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraInlineResultsSettings])
    |> map { sharedData -> ExteraInlineResultsSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.exteraInlineResultsSettings]?.get(ExteraInlineResultsSettings.self) ?? .defaultSettings
    }
    |> distinctUntilChanged
    
    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, settingsSignal)
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState<ExteraInlineResultsSettingsEntry>, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(exteraPillString("extera_InlineMathResult")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraInlineResultsSettingsEntries(presentationData: presentationData, settings: settings), style: .blocks)
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] value in
        controller?.push(value)
    }
    
    return controller
}

private enum ExteraInlineDefaultCurrencySection: Int32 {
    case automatic
    case currencies
}

private enum ExteraInlineDefaultCurrencyEntry: ItemListNodeEntry {
    case automatic(Bool)
    case currency(code: String, checked: Bool)
    
    var section: ItemListSectionId {
        switch self {
        case .automatic:
            return ExteraInlineDefaultCurrencySection.automatic.rawValue
        case .currency:
            return ExteraInlineDefaultCurrencySection.currencies.rawValue
        }
    }
    
    var sortId: Int {
        switch self {
        case .automatic: return 0
        case let .currency(code, _): return 1 + (ExteraCurrencySupport.isoCodes.firstIndex(of: code.lowercased()) ?? 0)
        }
    }
    
    var stableId: String {
        switch self {
        case .automatic: return "automatic"
        case let .currency(code, _): return code
        }
    }
    
    static func ==(lhs: ExteraInlineDefaultCurrencyEntry, rhs: ExteraInlineDefaultCurrencyEntry) -> Bool {
        switch lhs {
        case let .automatic(value):
            if case let .automatic(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .currency(code, checked):
            if case let .currency(rhsCode, rhsChecked) = rhs, code == rhsCode, checked == rhsChecked {
                return true
            }
        }
        return false
    }
    
    static func <(lhs: ExteraInlineDefaultCurrencyEntry, rhs: ExteraInlineDefaultCurrencyEntry) -> Bool {
        return lhs.sortId < rhs.sortId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraInlineDefaultCurrencyArguments
        switch self {
        case let .automatic(checked):
            return ItemListCheckboxItem(presentationData: presentationData, iconPlacement: .check, title: "Auto", style: .right, checked: checked, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateCurrency("")
            })
        case let .currency(code, checked):
            return ItemListCheckboxItem(presentationData: presentationData, iconPlacement: .check, title: code, style: .right, checked: checked, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateCurrency(code)
            })
        }
    }
}

private final class ExteraInlineDefaultCurrencyArguments {
    let updateCurrency: (String) -> Void
    
    init(updateCurrency: @escaping (String) -> Void) {
        self.updateCurrency = updateCurrency
    }
}

private func exteraInlineDefaultCurrencyEntries(settings: ExteraInlineResultsSettings) -> [ExteraInlineDefaultCurrencyEntry] {
    var entries: [ExteraInlineDefaultCurrencyEntry] = []
    entries.append(.automatic(settings.defaultCurrency.isEmpty))
    for code in ExteraCurrencySupport.isoCodes {
        let uppercased = code.uppercased()
        entries.append(.currency(code: uppercased, checked: settings.defaultCurrency.uppercased() == uppercased))
    }
    return entries
}

public func exteraInlineDefaultCurrencyController(context: AccountContext) -> ViewController {
    let arguments = ExteraInlineDefaultCurrencyArguments(updateCurrency: { value in
        let _ = updateExteraInlineResultsSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedDefaultCurrency(value) }).start()
    })
    
    let settingsSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraInlineResultsSettings])
    |> map { sharedData -> ExteraInlineResultsSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.exteraInlineResultsSettings]?.get(ExteraInlineResultsSettings.self) ?? .defaultSettings
    }
    |> distinctUntilChanged
    
    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, settingsSignal)
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState<ExteraInlineDefaultCurrencyEntry>, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(exteraPillString("extera_InlineDefaultCurrency")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraInlineDefaultCurrencyEntries(settings: settings), style: .blocks)
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}
