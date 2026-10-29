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

private enum ExteraWeatherLocationSection: Int32 {
    case source
    case info
}

private enum ExteraWeatherLocationEntry: ItemListNodeEntry {
    case current(Bool)
    case manual(String, Bool)
    case info(String)

    var section: ItemListSectionId {
        switch self {
        case .current, .manual:
            return ExteraWeatherLocationSection.source.rawValue
        case .info:
            return ExteraWeatherLocationSection.info.rawValue
        }
    }

    var sortId: Int {
        switch self {
        case .current: return 0
        case .manual: return 1
        case .info: return 2
        }
    }

    var stableId: AnyHashable {
        return AnyHashable(self.sortId)
    }

    static func ==(lhs: ExteraWeatherLocationEntry, rhs: ExteraWeatherLocationEntry) -> Bool {
        switch lhs {
        case let .current(value):
            if case let .current(rhsValue) = rhs, value == rhsValue {
                return true
            }
        case let .manual(name, active):
            if case let .manual(rhsName, rhsActive) = rhs, name == rhsName, active == rhsActive {
                return true
            }
        case let .info(text):
            if case let .info(rhsText) = rhs, text == rhsText {
                return true
            }
        }
        return false
    }

    static func <(lhs: ExteraWeatherLocationEntry, rhs: ExteraWeatherLocationEntry) -> Bool {
        return lhs.sortId < rhs.sortId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraWeatherLocationArguments
        switch self {
        case let .current(checked):
            return ItemListCheckboxItem(presentationData: presentationData, title: exteraPillString("extera_CurrentLocation"), style: .right, checked: checked, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.selectCurrent()
            })
        case let .manual(cityName, active):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .legacy, title: NSAttributedString(string: exteraPillString("extera_SelectCity"), font: Font.regular(13.0), textColor: presentationData.theme.list.itemSecondaryTextColor), text: cityName, placeholder: exteraPillString("extera_SelectLocation"), type: .regular(capitalization: true, autocorrection: false), returnKeyType: .search, alignment: .default, clearType: .always, sectionId: self.section, textUpdated: { value in
                arguments.updateDraft(value)
            }, action: {
                arguments.commitCity()
            })
        case let .info(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private final class ExteraWeatherLocationArguments {
    let context: AccountContext
    let selectCurrent: () -> Void
    let updateDraft: (String) -> Void
    let commitCity: () -> Void

    init(context: AccountContext, selectCurrent: @escaping () -> Void, updateDraft: @escaping (String) -> Void, commitCity: @escaping () -> Void) {
        self.context = context
        self.selectCurrent = selectCurrent
        self.updateDraft = updateDraft
        self.commitCity = commitCity
    }
}

private func exteraWeatherLocationEntries(presentationData: PresentationData, settings: ExteraPillStackSettings, draft: String) -> [ExteraWeatherLocationEntry] {
    let isAutomatic = settings.weatherLocation == nil || settings.weatherLocation?.source == .current
    var entries: [ExteraWeatherLocationEntry] = []
    entries.append(.current(isAutomatic))
    entries.append(.manual(draft, !isAutomatic))
    entries.append(.info(exteraPillString("extera_WeatherSettingsInfo")))
    return entries
}

public func exteraPillWeatherSettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?

    var draftValue = ""
    let draftPromise = ValuePromise<String>(ignoreRepeated: true)

    let arguments = ExteraWeatherLocationArguments(context: context, selectCurrent: {
        let _ = updateExteraPillStackSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedWeatherLocation(ExteraWeatherLocation(source: .current)) }).start()
    }, updateDraft: { value in
        draftValue = value
        draftPromise.set(value)
    }, commitCity: {
        let cityName = draftValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cityName.isEmpty else {
            return
        }
        let presentInGlobalOverlay = presentControllerImpl
        ExteraWeatherService.searchLocations(named: cityName, completion: { locations in
            guard let location = locations.first else {
                if let presentInGlobalOverlay {
                    presentInGlobalOverlay(textAlertController(context: context, title: exteraPillString("extera_SelectCity"), text: exteraPillString("extera_WeatherCityNotFound"), actions: [TextAlertAction(type: .defaultAction, title: context.sharedContext.currentPresentationData.with { $0 }.strings.Common_OK, action: {})]), nil)
                }
                return
            }
            let _ = updateExteraPillStackSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                settings.withUpdatedWeatherLocation(ExteraWeatherLocation(source: .manual, latitude: location.latitude, longitude: location.longitude, title: location.name))
            }).start()
            DispatchQueue.main.async(execute: {
                dismissImpl?()
            })
        })
    })

    let settingsSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraPillStackSettings])
    |> map { sharedData -> ExteraPillStackSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.exteraPillStackSettings]?.get(ExteraPillStackSettings.self) ?? .defaultSettings
    }
    |> distinctUntilChanged

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, settingsSignal, draftPromise.get())
    |> map { presentationData, settings, draft -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(exteraPillString("extera_WeatherLocation")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraWeatherLocationEntries(presentationData: presentationData, settings: settings, draft: draft), style: .blocks)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] value in
        controller?.push(value)
    }
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    presentControllerImpl = { [weak controller] c, p in
        controller?.present(c, in: .window(.root), with: p)
    }

    return controller
}

private enum ExteraCryptoCurrencySection: Int32 {
    case currencies
}

private enum ExteraCryptoCurrencyEntry: ItemListNodeEntry {
    case currency(code: String, currency: ExteraCryptoPillTargetCurrency, checked: Bool)

    var section: ItemListSectionId {
        return ExteraCryptoCurrencySection.currencies.rawValue
    }

    var sortId: Int {
        switch self.code {
        case "BTC": return 0
        case "ETH": return 1
        default: return 2
        }
    }

    var stableId: String {
        return self.code
    }

    static func ==(lhs: ExteraCryptoCurrencyEntry, rhs: ExteraCryptoCurrencyEntry) -> Bool {
        if case let .currency(lhsCode, lhsCurrency, lhsChecked) = lhs, case let .currency(rhsCode, rhsCurrency, rhsChecked) = rhs, lhsCode == rhsCode, lhsCurrency == rhsCurrency, lhsChecked == rhsChecked {
            return true
        }
        return false
    }

    static func <(lhs: ExteraCryptoCurrencyEntry, rhs: ExteraCryptoCurrencyEntry) -> Bool {
        return lhs.sortId < rhs.sortId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        guard case let .currency(code, currency, checked) = self else {
            return ItemListTextItem(presentationData: presentationData, text: .plain(""), sectionId: self.section)
        }
        let arguments = arguments as! ExteraCryptoCurrencyArguments
        return ItemListCheckboxItem(presentationData: presentationData, title: code, style: .right, checked: checked, zeroSeparatorInsets: false, sectionId: self.section, action: {
            arguments.select(currency)
        })
    }

    private var code: String {
        switch self {
        case let .currency(code, _): return code
        }
    }
}

private final class ExteraCryptoCurrencyArguments {
    let select: (ExteraCryptoPillTargetCurrency) -> Void

    init(select: @escaping (ExteraCryptoPillTargetCurrency) -> Void) {
        self.select = select
    }
}

private func exteraCryptoCurrencyEntries(settings: ExteraPillStackSettings) -> [ExteraCryptoCurrencyEntry] {
    return [("BTC", ExteraCryptoPillTargetCurrency.btc), ("ETH", ExteraCryptoPillTargetCurrency.eth), ("USDT", ExteraCryptoPillTargetCurrency.usd)].map({ code, currency in
        return .currency(code: code, currency: currency, checked: settings.cryptoTargetCurrency == currency)
    })
}

public func exteraPillCryptoCurrencyController(context: AccountContext) -> ViewController {
    let arguments = ExteraCryptoCurrencyArguments(select: { currency in
        let _ = updateExteraPillStackSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedCryptoTargetCurrency(currency) }).start()
    })

    let settingsSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraPillStackSettings])
    |> map { sharedData -> ExteraPillStackSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.exteraPillStackSettings]?.get(ExteraPillStackSettings.self) ?? .defaultSettings
    }
    |> distinctUntilChanged

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, settingsSignal)
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(exteraPillString("extera_CryptoPillTargetCurrency")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraCryptoCurrencyEntries(settings: settings), style: .blocks)

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
