import Foundation
import SwiftSignalKit
import Display
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import AccountContext
import ItemListUI
import PresentationDataUtils
import ExteraSpeech

private enum ExteraSpeechSettingsSection: Int32 {
    case behavior
    case refinement
}

private func currentExteraSpeechSettings(_ accountManager: AccountManager<TelegramAccountManagerTypes>) -> Signal<ExteraSpeechSettings, NoError> {
    return accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSpeechSettings])
    |> map { sharedData -> ExteraSpeechSettings in
        if let entry = sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSpeechSettings], let settings = entry.get(ExteraSpeechSettings.self) {
            return settings
        }
        return .defaultSettings
    }
}

private func exteraSpeechLanguageName(languageIdentifier: String, availableLocales: [ExteraSpeechLocaleOption]) -> String? {
    return availableLocales.first(where: { $0.identifier == languageIdentifier })?.displayName
}

private final class ExteraSpeechSettingsArguments {
    let updateEnabled: (Bool) -> Void
    let updateTextCorrection: (Bool) -> Void
    let openLanguagePicker: () -> Void

    init(updateEnabled: @escaping (Bool) -> Void, updateTextCorrection: @escaping (Bool) -> Void, openLanguagePicker: @escaping () -> Void) {
        self.updateEnabled = updateEnabled
        self.updateTextCorrection = updateTextCorrection
        self.openLanguagePicker = openLanguagePicker
    }
}

private enum ExteraSpeechSettingsEntry: ItemListNodeEntry {
    case behaviorHeader(String)
    case enable(Bool)
    case language(String)
    case refinementHeader(String)
    case useTextCorrection(isOn: Bool, isEnabled: Bool)

    var section: ItemListSectionId {
        switch self {
        case .behaviorHeader, .enable, .language:
            return ExteraSpeechSettingsSection.behavior.rawValue
        case .refinementHeader, .useTextCorrection:
            return ExteraSpeechSettingsSection.refinement.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .behaviorHeader: return 0
        case .enable: return 1
        case .language: return 2
        case .refinementHeader: return 3
        case .useTextCorrection: return 4
        }
    }

    static func <(lhs: ExteraSpeechSettingsEntry, rhs: ExteraSpeechSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraSpeechSettingsArguments
        switch self {
        case let .behaviorHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .enable(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Extera_Speech_Settings_Enable, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateEnabled(value)
            })
        case let .language(label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Extera_Speech_Settings_Language, label: label, sectionId: self.section, style: .blocks, action: {
                arguments.openLanguagePicker()
            })
        case let .refinementHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .useTextCorrection(isOn, isEnabled):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Extera_Speech_Settings_UseTextCorrection, value: isOn, enabled: isEnabled, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateTextCorrection(value)
            })
        }
    }
}

private func exteraSpeechSettingsEntries(presentationData: PresentationData, settings: ExteraSpeechSettings, availableLocales: [ExteraSpeechLocaleOption], hasCorrectionService: Bool) -> [ExteraSpeechSettingsEntry] {
    var entries: [ExteraSpeechSettingsEntry] = []
    entries.append(.behaviorHeader(presentationData.strings.Extera_Speech_Settings_HeaderText))
    entries.append(.enable(settings.isEnabled))

    let languageLabel: String
    if settings.languageIdentifier == "auto" {
        let resolvedName = exteraSpeechLanguageName(languageIdentifier: resolveSpeechLocaleIdentifier(languageIdentifier: "auto", deviceLanguageCode: presentationData.strings.baseLanguageCode), availableLocales: availableLocales) ?? presentationData.strings.Extera_Speech_Settings_Language
        languageLabel = presentationData.strings.Extera_Speech_Settings_Language_Auto(resolvedName)
    } else {
        languageLabel = exteraSpeechLanguageName(languageIdentifier: settings.languageIdentifier, availableLocales: availableLocales) ?? settings.languageIdentifier
    }
    entries.append(.language(languageLabel))

    if hasCorrectionService {
        entries.append(.refinementHeader(presentationData.strings.Extera_Speech_Settings_UseTextCorrection))
        entries.append(.useTextCorrection(isOn: settings.useTextCorrection, isEnabled: settings.isEnabled))
    }

    return entries
}

public func exteraSpeechSettingsController(context: AccountContext) -> ViewController {
    let pushControllerImpl = Atomic<(ViewController) -> Void>(value: { _ in })
    let availableLocales = exteraAvailableSpeechRecognitionLocales()
    let hasCorrectionService = registeredTranscriptCorrectionService() != nil

    let arguments = ExteraSpeechSettingsArguments(
        updateEnabled: { value in
            let _ = updateExteraSpeechSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedIsEnabled(value) }).startStandalone()
        },
        updateTextCorrection: { value in
            let _ = updateExteraSpeechSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedUseTextCorrection(value) }).startStandalone()
        },
        openLanguagePicker: {
            let picker = exteraSpeechLanguagePickerController(context: context, availableLocales: availableLocales)
            pushControllerImpl.with { impl in
                impl(picker)
            }
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        currentExteraSpeechSettings(context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(presentationData.strings.Extera_Speech_Settings_Title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraSpeechSettingsEntries(presentationData: presentationData, settings: settings, availableLocales: availableLocales, hasCorrectionService: hasCorrectionService), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal

    let _ = pushControllerImpl.swap({ [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    })
    return controller
}

private final class ExteraSpeechLanguageArguments {
    let select: (String) -> Void

    init(select: @escaping (String) -> Void) {
        self.select = select
    }
}

private enum ExteraSpeechLanguageEntry: ItemListNodeEntry {
    case auto(selected: Bool, String)
    case locale(index: Int32, selected: Bool, identifier: String, String)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case .auto: return 0
        case let .locale(index, _, _): return 1 + index
        }
    }

    static func <(lhs: ExteraSpeechLanguageEntry, rhs: ExteraSpeechLanguageEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraSpeechLanguageArguments
        let accentColor = presentationData.theme.list.itemAccentColor
        switch self {
        case let .auto(selected, label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: label, label: selected ? "✓" : "", labelStyle: .coloredText(accentColor), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.select("auto")
            })
        case let .locale(_, _, identifier, title):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: selected ? "✓" : "", labelStyle: .coloredText(accentColor), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.select(identifier)
            })
        }
    }
}

private func exteraSpeechLanguageEntries(presentationData: PresentationData, currentLanguageIdentifier: String, availableLocales: [ExteraSpeechLocaleOption]) -> [ExteraSpeechLanguageEntry] {
    var entries: [ExteraSpeechLanguageEntry] = []

    let autoResolvedName = exteraSpeechLanguageName(languageIdentifier: resolveSpeechLocaleIdentifier(languageIdentifier: "auto", deviceLanguageCode: presentationData.strings.baseLanguageCode), availableLocales: availableLocales) ?? availableLocales.first?.displayName ?? currentLanguageIdentifier
    entries.append(.auto(selected: currentLanguageIdentifier == "auto", presentationData.strings.Extera_Speech_Settings_Language_Auto(autoResolvedName)))
    for (index, option) in availableLocales.enumerated() {
        entries.append(.locale(index: Int32(index), selected: currentLanguageIdentifier == option.identifier, identifier: option.identifier, option.displayName))
    }
    return entries
}

private func exteraSpeechLanguagePickerController(context: AccountContext, availableLocales: [ExteraSpeechLocaleOption]) -> ViewController {
    let arguments = ExteraSpeechLanguageArguments(select: { identifier in
        let _ = updateExteraSpeechSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedLanguageIdentifier(identifier) }).startStandalone()
    })

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        currentExteraSpeechSettings(context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(presentationData.strings.Extera_Speech_Settings_Language), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraSpeechLanguageEntries(presentationData: presentationData, currentLanguageIdentifier: settings.languageIdentifier, availableLocales: availableLocales), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    return controller
}
