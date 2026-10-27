import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import TelegramPresentationData
import PresentationDataUtils
import ItemListUI

private final class ExteraAIGenerationArguments {
    let toggleReasoning: (Bool) -> Void
    let toggleStreaming: (Bool) -> Void
    let updateTemperature: (String) -> Void
    let showResponseOnly: () -> Void
    let insertAsQuote: () -> Void

    init(
        toggleReasoning: @escaping (Bool) -> Void,
        toggleStreaming: @escaping (Bool) -> Void,
        updateTemperature: @escaping (String) -> Void,
        showResponseOnly: @escaping () -> Void,
        insertAsQuote: @escaping () -> Void
    ) {
        self.toggleReasoning = toggleReasoning
        self.toggleStreaming = toggleStreaming
        self.updateTemperature = updateTemperature
        self.showResponseOnly = showResponseOnly
        self.insertAsQuote = insertAsQuote
    }
}

private enum ExteraAIGenerationSection: Int32 {
    case output
    case behavior
}

private enum ExteraAIGenerationEntry: ItemListNodeEntry {
    case showResponseOnly(PresentationTheme, String, Bool)
    case insertAsQuote(PresentationTheme, String, Bool)
    case temperature(PresentationTheme, NSAttributedString, String, String)
    case temperatureInfo(String)
    case reasoning(PresentationTheme, String, Bool)
    case reasoningInfo(String)
    case streaming(PresentationTheme, String, Bool)
    case streamingInfo(String)

    var section: ItemListSectionId {
        switch self {
        case .showResponseOnly, .insertAsQuote:
            return ExteraAIGenerationSection.output.rawValue
        case .temperature, .temperatureInfo, .reasoning, .reasoningInfo, .streaming, .streamingInfo:
            return ExteraAIGenerationSection.behavior.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .showResponseOnly:
            return 0
        case .insertAsQuote:
            return 1
        case .temperature:
            return 2
        case .temperatureInfo:
            return 3
        case .reasoning:
            return 4
        case .reasoningInfo:
            return 5
        case .streaming:
            return 6
        case .streamingInfo:
            return 7
        }
    }

    static func ==(lhs: ExteraAIGenerationEntry, rhs: ExteraAIGenerationEntry) -> Bool {
        switch lhs {
        case let .showResponseOnly(lhsTheme, lhsText, lhsValue):
            if case let .showResponseOnly(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            }
            return false
        case let .insertAsQuote(lhsTheme, lhsText, lhsValue):
            if case let .insertAsQuote(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            }
            return false
        case let .temperature(lhsTheme, lhsTitle, lhsText, lhsPlaceholder):
            if case let .temperature(rhsTheme, rhsTitle, rhsText, rhsPlaceholder) = rhs, lhsTheme === rhsTheme, lhsTitle == rhsTitle, lhsText == rhsText, lhsPlaceholder == rhsPlaceholder {
                return true
            }
            return false
        case let .temperatureInfo(lhsText):
            if case .temperatureInfo(lhsText) = rhs {
                return true
            }
            return false
        case let .reasoning(lhsTheme, lhsText, lhsValue):
            if case let .reasoning(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            }
            return false
        case let .reasoningInfo(lhsText):
            if case .reasoningInfo(lhsText) = rhs {
                return true
            }
            return false
        case let .streaming(lhsTheme, lhsText, lhsValue):
            if case let .streaming(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            }
            return false
        case let .streamingInfo(lhsText):
            if case .streamingInfo(lhsText) = rhs {
                return true
            }
            return false
        }
    }

    static func <(lhs: ExteraAIGenerationEntry, rhs: ExteraAIGenerationEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraAIGenerationArguments
        switch self {
        case let .showResponseOnly(_, title, checked):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: title, style: .left, checked: checked, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.showResponseOnly()
            })
        case let .insertAsQuote(_, title, checked):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: title, style: .left, checked: checked, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.insertAsQuote()
            })
        case let .temperature(_, title, text, placeholder):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, placeholder: placeholder, sectionId: self.section, textUpdated: { value in
                arguments.updateTemperature(value)
            }, action: {})
        case let .temperatureInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .reasoning(_, title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleReasoning(value)
            })
        case let .reasoningInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .streaming(_, title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleStreaming(value)
            })
        case let .streamingInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func exteraAIGenerationEntries(settings: ExteraAIGenerationSettings, presentationData: PresentationData) -> [ExteraAIGenerationEntry] {
    let strings = presentationData.strings
    var entries: [ExteraAIGenerationEntry] = []
    entries.append(.showResponseOnly(presentationData.theme, exteraAIString("Extera.AI.ShowResponseOnly"), settings.responseDisplay == .showResponseOnly))
    entries.append(.insertAsQuote(presentationData.theme, exteraAIString("Extera.AI.InsertAsQuote"), settings.responseDisplay == .insertAsQuote))
    entries.append(.temperature(presentationData.theme, NSAttributedString(string: exteraAIString("Extera.AI.Temperature"), attributes: [
        .font: Font.regular(presentationData.listsFontSize.itemListBaseFontSize),
        .foregroundColor: presentationData.theme.list.itemPrimaryTextColor
    ]), settings.temperature.map { String(format: "%.1f", $0) } ?? "", exteraAIString("Extera.AI.Temperature")))
    entries.append(.temperatureInfo(exteraAIString("Extera.AI.TemperatureInfo")))
    entries.append(.reasoning(presentationData.theme, exteraAIString("Extera.AI.Reasoning"), settings.showReasoningTokens))
    entries.append(.reasoningInfo(exteraAIString("Extera.AI.ReasoningInfo")))
    entries.append(.streaming(presentationData.theme, exteraAIString("Extera.AI.ResponseStreaming"), settings.responseStreaming))
    entries.append(.streamingInfo(exteraAIString("Extera.AI.ResponseStreamingInfo")))
    return entries
}

public func exteraAIGenerationController(context: AccountContext, refreshed: @escaping () -> Void) -> ItemListController {
    let settingsPromise = Promise<ExteraAIGenerationSettings>(ExteraAIStore.shared.generationSettings)

    func updateSettings(_ transform: (inout ExteraAIGenerationSettings) -> Void) {
        var settings = ExteraAIStore.shared.generationSettings
        transform(&settings)
        ExteraAIStore.shared.generationSettings = settings
        settingsPromise.set(.single(settings))
        refreshed()
    }

    let arguments = ExteraAIGenerationArguments(
        toggleReasoning: { value in
            updateSettings { $0.showReasoningTokens = value }
        },
        toggleStreaming: { value in
            updateSettings { $0.responseStreaming = value }
        },
        updateTemperature: { value in
            guard let parsed = Double(value.replacingOccurrences(of: ",", with: ".")), (0.0...2.0).contains(parsed) else {
                return
            }
            updateSettings { $0.temperature = parsed }
        },
        showResponseOnly: {
            updateSettings { $0.responseDisplay = .showResponseOnly }
        },
        insertAsQuote: {
            updateSettings { $0.responseDisplay = .insertAsQuote }
        }
    )

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, settingsPromise.get())
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(presentationData.exteraAIString("Extera.AI.Generation")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraAIGenerationEntries(settings: settings, presentationData: presentationData), style: .blocks)
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
