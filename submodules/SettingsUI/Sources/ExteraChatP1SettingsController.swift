import Foundation
import SwiftSignalKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import ItemListUI
import PresentationDataUtils

private struct ExteraChatP1DisplayState: Equatable {
    var stickerSizeAdjustment: Double
    var hideReactions: Bool
    var editedAsIcon: Bool
    var stickerTimePosition: Int
    var unlimitedRecentStickers: Bool
    var widePosts: Bool
    var replyAccentBackground: Bool
    var bottomButtonStyle: Int

    init() {
        self.stickerSizeAdjustment = ExteraChatP1.stickerSizeAdjustment
        self.hideReactions = ExteraChatP1.hideReactions
        self.editedAsIcon = ExteraChatP1.editedAsIcon
        self.stickerTimePosition = ExteraChatP1.stickerTimePosition
        self.unlimitedRecentStickers = ExteraChatP1.unlimitedRecentStickers
        self.widePosts = ExteraChatP1.widePosts
        self.replyAccentBackground = ExteraChatP1.replyAccentBackground
        self.bottomButtonStyle = ExteraChatP1.bottomButtonStyle
    }

    static let stickerTimePositionCount = 3
    static let bottomButtonStyleCount = 3
}

private final class ExteraChatP1SettingsArguments {
    private let state: Atomic<ExteraChatP1DisplayState>
    private let commit: (ExteraChatP1DisplayState) -> Void

    init(state: ExteraChatP1DisplayState, commit: @escaping (ExteraChatP1DisplayState) -> Void) {
        self.state = Atomic(value: state)
        self.commit = commit
    }

    private func apply(_ transform: (inout ExteraChatP1DisplayState) -> Void) {
        let next = self.state.modify { value in
            transform(&value)
            return value
        }
        self.commit(next)
    }

    func updateStickerSize(_ value: Double) {
        ExteraChatP1.stickerSizeAdjustment = value
        self.apply { $0.stickerSizeAdjustment = value }
    }

    func updateHideReactions(_ value: Bool) {
        ExteraChatP1.hideReactions = value
        self.apply { $0.hideReactions = value }
    }

    func updateEditedAsIcon(_ value: Bool) {
        ExteraChatP1.editedAsIcon = value
        self.apply { $0.editedAsIcon = value }
    }

    func cycleStickerTimePosition() {
        self.apply { state in
            ExteraChatP1.stickerTimePosition = (state.stickerTimePosition + 1) % ExteraChatP1DisplayState.stickerTimePositionCount
            state.stickerTimePosition = ExteraChatP1.stickerTimePosition
        }
    }

    func updateUnlimitedRecentStickers(_ value: Bool) {
        ExteraChatP1.unlimitedRecentStickers = value
        self.apply { $0.unlimitedRecentStickers = value }
    }

    func updateWidePosts(_ value: Bool) {
        ExteraChatP1.widePosts = value
        self.apply { $0.widePosts = value }
    }

    func updateReplyAccentBackground(_ value: Bool) {
        ExteraChatP1.replyAccentBackground = value
        self.apply { $0.replyAccentBackground = value }
    }

    func cycleBottomButtonStyle() {
        self.apply { state in
            ExteraChatP1.bottomButtonStyle = (state.bottomButtonStyle + 1) % ExteraChatP1DisplayState.bottomButtonStyleCount
            state.bottomButtonStyle = ExteraChatP1.bottomButtonStyle
        }
    }
}

private enum ExteraChatP1SettingsEntry: ItemListNodeEntry {
    case sizingHeader(String)
    case stickerSize(Double)
    case stickerTimePosition(Int)
    case messagesHeader(String)
    case hideReactions(Bool)
    case editedAsIcon(Bool)
    case widePosts(Bool)
    case replyAccentBackground(Bool)
    case inputHeader(String)
    case unlimitedRecentStickers(Bool)
    case bottomButtonStyle(Int)

    var section: ItemListSectionId {
        switch self {
        case .sizingHeader, .stickerSize, .stickerTimePosition:
            return 0
        case .messagesHeader, .hideReactions, .editedAsIcon, .widePosts, .replyAccentBackground:
            return 1
        case .inputHeader, .unlimitedRecentStickers, .bottomButtonStyle:
            return 2
        }
    }

    var stableId: Int32 {
        switch self {
        case .sizingHeader: return 0
        case .stickerSize: return 1
        case .stickerTimePosition: return 2
        case .messagesHeader: return 10
        case .hideReactions: return 11
        case .editedAsIcon: return 12
        case .widePosts: return 13
        case .replyAccentBackground: return 14
        case .inputHeader: return 20
        case .unlimitedRecentStickers: return 21
        case .bottomButtonStyle: return 22
        }
    }

    static func <(lhs: ExteraChatP1SettingsEntry, rhs: ExteraChatP1SettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraChatP1SettingsArguments
        switch self {
        case let .sizingHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .stickerSize(value):
            return ExteraChatP1StickerSizeItem(theme: presentationData.theme, value: value, sectionId: self.section, updated: { value in
                arguments.updateStickerSize(value)
            })
        case let .stickerTimePosition(position):
            return ItemListDisclosureItem(presentationData: presentationData, title: exteraChatP1String("extera.ChatP1.StickerTime"), label: stickerTimePositionName(position), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.cycleStickerTimePosition()
            })
        case let .messagesHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .hideReactions(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraChatP1String("extera.ChatP1.HideReactions"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHideReactions(value)
            })
        case let .editedAsIcon(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraChatP1String("extera.ChatP1.EditedAsIcon"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateEditedAsIcon(value)
            })
        case let .widePosts(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraChatP1String("extera.ChatP1.WidePosts"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateWidePosts(value)
            })
        case let .replyAccentBackground(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraChatP1String("extera.ChatP1.ReplyBackground"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateReplyAccentBackground(value)
            })
        case let .inputHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .unlimitedRecentStickers(value):
            return ItemListSwitchItem(presentationData: presentationData, title: exteraChatP1String("extera.ChatP1.UnlimitedRecentStickers"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateUnlimitedRecentStickers(value)
            })
        case let .bottomButtonStyle(style):
            return ItemListDisclosureItem(presentationData: presentationData, title: exteraChatP1String("extera.ChatP1.BottomButton"), label: bottomButtonStyleName(style), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.cycleBottomButtonStyle()
            })
        }
    }
}

private func stickerTimePositionName(_ position: Int) -> String {
    switch position {
    case 1:
        return exteraChatP1String("extera.ChatP1.StickerTime.Side")
    case 2:
        return exteraChatP1String("extera.ChatP1.StickerTime.Hidden")
    default:
        return exteraChatP1String("extera.ChatP1.StickerTime.Default")
    }
}

private func bottomButtonStyleName(_ style: Int) -> String {
    switch style {
    case 1:
        return exteraChatP1String("extera.ChatP1.BottomButton.Accent")
    case 2:
        return exteraChatP1String("extera.ChatP1.BottomButton.Glass")
    default:
        return exteraChatP1String("extera.ChatP1.BottomButton.Default")
    }
}

public func exteraChatP1SettingsController(context: AccountContext) -> ViewController {
    let initialState = ExteraChatP1DisplayState()
    let stateValue = ValuePromise<ExteraChatP1DisplayState>(ignoreRepeatedUpdates: false)
    stateValue.set(initialState)

    let arguments = ExteraChatP1SettingsArguments(state: initialState, commit: { next in
        stateValue.set(next)
    })

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        stateValue.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let presentationData = ItemListPresentationData(presentationData)
        let entries: [ExteraChatP1SettingsEntry] = [
            .sizingHeader(exteraChatP1String("extera.ChatP1.StickersHeader")),
            .stickerSize(state.stickerSizeAdjustment),
            .stickerTimePosition(state.stickerTimePosition),
            .messagesHeader(exteraChatP1String("extera.ChatP1.MessagesHeader")),
            .hideReactions(state.hideReactions),
            .editedAsIcon(state.editedAsIcon),
            .widePosts(state.widePosts),
            .replyAccentBackground(state.replyAccentBackground),
            .inputHeader(exteraChatP1String("extera.ChatP1.InputHeader")),
            .unlimitedRecentStickers(state.unlimitedRecentStickers),
            .bottomButtonStyle(state.bottomButtonStyle)
        ]
        let controllerState = ItemListControllerState(presentationData: presentationData, title: .text(exteraChatP1String("extera.ChatP1.Title")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: presentationData, entries: entries, style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    return controller
}
