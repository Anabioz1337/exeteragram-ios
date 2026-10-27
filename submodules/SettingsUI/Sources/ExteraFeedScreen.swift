import Foundation
import Display
import SwiftSignalKit
import TelegramCore
import AccountContext
import TelegramPresentationData
import TelegramUIPreferences
import PresentationDataUtils
import LocalizedPeerData
import ItemListUI

private enum ExteraFeedSection: Int32 {
    case adblock = 0
    case categories = 1
    case actions = 2
    case posts = 3
}

public let exteraFeedAllCategoryId: Int64 = 0

private final class ExteraFeedArguments {
    let selectCategory: (Int64) -> Void
    let setAdblockEnabled: (Bool) -> Void
    let setIncludeArchived: (Bool) -> Void
    let setFeedTabEnabled: (Bool) -> Void
    let markAllAsRead: () -> Void
    let openPost: (PeerId, MessageId) -> Void
    let requestHideChannel: (PeerId, String) -> Void

    init(selectCategory: @escaping (Int64) -> Void, setAdblockEnabled: @escaping (Bool) -> Void, setIncludeArchived: @escaping (Bool) -> Void, setFeedTabEnabled: @escaping (Bool) -> Void, markAllAsRead: @escaping () -> Void, openPost: @escaping (PeerId, MessageId) -> Void, requestHideChannel: @escaping (PeerId, String) -> Void) {
        self.selectCategory = selectCategory
        self.setAdblockEnabled = setAdblockEnabled
        self.setIncludeArchived = setIncludeArchived
        self.setFeedTabEnabled = setFeedTabEnabled
        self.markAllAsRead = markAllAsRead
        self.openPost = openPost
        self.requestHideChannel = requestHideChannel
    }
}

private struct ExteraFeedPostEntry: Equatable {
    let messageId: MessageId
    let peerId: PeerId
    let peerTitle: String
    let previewText: String
    let timestamp: Int32
    let unreadCount: Int
}

/// Everything the list is built from in one value, so the controller state signal stays a single map.
private struct ExteraFeedModel {
    let presentationData: PresentationData
    let settings: ExteraSettings
    let categoryId: Int64
    let posts: [ExteraFeedPostEntry]
    let activePeerIds: [EnginePeer.Id]
}

private enum ExteraFeedEntry: ItemListNodeEntry {
    case adblockSwitch(title: String, value: Bool)
    case blockedRequests(label: String, count: String)
    case categoriesHeader(String)
    case category(index: Int32, id: Int64, title: String, selected: Bool)
    case markAllAsRead(String)
    case includeArchived(title: String, value: Bool)
    case feedTabSwitch(title: String, value: Bool)
    case emptyPosts(String)
    case post(index: Int32, post: ExteraFeedPostEntry)

    var section: ItemListSectionId {
        switch self {
        case .adblockSwitch, .blockedRequests:
            return ExteraFeedSection.adblock.rawValue
        case .categoriesHeader, .category:
            return ExteraFeedSection.categories.rawValue
        case .markAllAsRead, .includeArchived, .feedTabSwitch:
            return ExteraFeedSection.actions.rawValue
        case .emptyPosts, .post:
            return ExteraFeedSection.posts.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .adblockSwitch:
            return 0
        case .blockedRequests:
            return 1
        case .categoriesHeader:
            return 10
        case let .category(index, _, _, _):
            return 20 &+ index
        case .markAllAsRead:
            return 30
        case .includeArchived:
            return 31
        case .feedTabSwitch:
            return 32
        case .emptyPosts:
            return 40
        case let .post(index, _):
            return 1000 &+ index
        }
    }

    static func <(lhs: ExteraFeedEntry, rhs: ExteraFeedEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraFeedArguments
        switch self {
        case let .adblockSwitch(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updated in
                arguments.setAdblockEnabled(updated)
            })
        case let .blockedRequests(label, count):
            return ItemListTextWithLabelItem(presentationData: presentationData, label: label, text: count, style: .blocks, enabledEntityTypes: [], multiline: false, selected: nil, sectionId: self.section, action: nil)
        case let .categoriesHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .category(_, id, title, selected):
            return ItemListActionItem(presentationData: presentationData, title: selected ? "✓ \(title)" : title, kind: selected ? .accent : .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.selectCategory(id)
            }, longTapAction: nil)
        case let .markAllAsRead(title):
            return ItemListActionItem(presentationData: presentationData, title: title, kind: .accent, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.markAllAsRead()
            }, longTapAction: nil)
        case let .includeArchived(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updated in
                arguments.setIncludeArchived(updated)
            })
        case let .feedTabSwitch(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updated in
                arguments.setFeedTabEnabled(updated)
            })
        case let .emptyPosts(text):
            return ItemListMultilineTextItem(presentationData: presentationData, text: text, enabledEntityTypes: [], sectionId: self.section, style: .blocks, action: nil, longTapAction: nil)
        case let .post(_, post):
            let unreadSuffix = post.unreadCount > 0 ? " (\(post.unreadCount))" : ""
            let peerId = post.peerId
            let messageId = post.messageId
            return ItemListMultilineTextItem(
                presentationData: presentationData,
                text: "\(post.peerTitle)\(unreadSuffix)\n\(exteraFeedTimestamp(post.timestamp)) · \(post.previewText)",
                enabledEntityTypes: [],
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openPost(peerId, messageId)
                },
                longTapAction: {
                    arguments.requestHideChannel(peerId, post.peerTitle)
                }
            )
        }
    }
}

private func exteraFeedTimestamp(_ timestamp: Int32) -> String {
    let date = Date(timeIntervalSince1970: Double(timestamp))
    let calendar = Calendar(identifier: .gregorian)
    let formatter = DateFormatter()
    if calendar.isDateInToday(date) || calendar.isDateInYesterday(date) {
        formatter.dateStyle = .none
        formatter.timeStyle = .short
    } else {
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
    }
    return formatter.string(from: date)
}

func exteraFeedHiddenChannelIds(defaults: UserDefaults?) -> Set<Int64> {
    return Set((defaults?.stringArray(forKey: "feedHiddenChannelIds") ?? []).compactMap { Int64($0) })
}

public func exteraFeedSetChannelHidden(_ peerId: PeerId, hidden: Bool, defaults: UserDefaults?) {
    guard let defaults else {
        return
    }
    var ids = exteraFeedHiddenChannelIds(defaults: defaults)
    if hidden {
        ids.insert(peerId.toInt64())
    } else {
        ids.remove(peerId.toInt64())
    }
    defaults.set(Array(ids.map { String($0) }), forKey: "feedHiddenChannelIds")
}

private func exteraFeedVisiblePeerIds(settings: ExteraSettings, categoryId: Int64, channels: [ExteraFeedChannel], hiddenPeerIds: Set<PeerId>) -> [EnginePeer.Id] {
    var candidates = channels.filter { channel in
        !hiddenPeerIds.contains(channel.peer.id) && (settings.feedIncludeArchived || !channel.isArchived)
    }
    if categoryId != exteraFeedAllCategoryId, let category = settings.feedCategories.first(where: { $0.id == categoryId }) {
        let wanted = Set(category.channelIds.map { PeerId($0) })
        candidates = candidates.filter { wanted.contains($0.peer.id) }
    }
    return candidates.map { $0.peer.id }
}

private func exteraFeedEntries(model: ExteraFeedModel) -> [ExteraFeedEntry] {
    let strings = model.presentationData.strings
    var entries: [ExteraFeedEntry] = [
        .adblockSwitch(title: strings.Extera_Adblock_Title, value: model.settings.adBlockEnabled),
        .blockedRequests(label: strings.Extera_Adblock_BlockedRequests, count: "\(model.settings.adBlockBlockedRequests)")
    ]
    entries.append(.categoriesHeader(strings.Extera_Feed_Categories))
    entries.append(.category(index: 0, id: exteraFeedAllCategoryId, title: strings.Extera_Feed_All, selected: model.categoryId == exteraFeedAllCategoryId))
    for (index, category) in model.settings.feedCategories.enumerated() where !category.hidden {
        entries.append(.category(index: Int32(index + 1), id: category.id, title: category.title, selected: category.id == model.categoryId))
    }
    entries.append(.markAllAsRead(strings.Extera_Feed_MarkAllAsRead))
    entries.append(.includeArchived(title: strings.Extera_Feed_IncludeArchived, value: model.settings.feedIncludeArchived))
    entries.append(.feedTabSwitch(title: strings.Extera_Feed_ShowInTabs, value: model.settings.feedEnabled))
    if model.posts.isEmpty {
        entries.append(.emptyPosts(strings.Extera_Feed_Empty))
    } else {
        for (index, post) in model.posts.enumerated() {
            entries.append(.post(index: Int32(truncatingIfNeeded: index), post: post))
        }
    }
    return entries
}

private func exteraFeedPosts(grouped: [(peerId: PeerId, messages: [EngineMessage])], titles: [EnginePeer.Id: String], unreadCounts: [EnginePeer.Id: Int]) -> [ExteraFeedPostEntry] {
    var merged: [(peerId: PeerId, message: EngineMessage)] = []
    for group in grouped {
        for message in group.messages.prefix(30) {
            merged.append((group.peerId, message))
        }
    }
    merged.sort(by: { $0.message.timestamp > $1.message.timestamp })
    if merged.count > 300 {
        merged.removeLast(merged.count - 300)
    }
    return merged.map { pair -> ExteraFeedPostEntry in
        let previewText = pair.message.text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return ExteraFeedPostEntry(
            messageId: pair.message.id,
            peerId: pair.peerId,
            peerTitle: titles[pair.peerId] ?? "",
            previewText: String(previewText.prefix(140)),
            timestamp: pair.message.timestamp,
            unreadCount: unreadCounts[pair.peerId] ?? 0
        )
    }
}

/// An aggregated view of the most recent posts across every subscribed broadcast channel. All data
/// comes straight from the postbox: per-channel history views and unread counters, no server calls.
public func exteraFeedController(context: AccountContext) -> ViewController {
    let accountManager = context.sharedContext.accountManager
    let defaults = exteraAdBlockUserDefaults ?? UserDefaults.standard

    let selectedCategoryId = Promise<Int64>(exteraFeedAllCategoryId)
    let refreshPromise = Promise<Int>(0)
    let refreshCounter = Atomic<Int>(value: 0)
    let activePeerIds = Atomic<[EnginePeer.Id]>(value: [])
    let stringsHolder = Atomic<PresentationStrings?>(value: nil)

    let settingsSignal = accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSettings])
        |> map { sharedData -> ExteraSettings in
            return sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSettings]?.get(ExteraSettings.self) ?? ExteraSettings.defaultSettings
        }

    func updateSettings(_ f: (ExteraSettings) -> ExteraSettings) {
        let _ = updateExteraSettingsInteractively(accountManager: accountManager, f).startStandalone()
    }

    weak var weakController: ViewController?
    var presentControllerImpl: (ViewController, Any?) -> Void = { _, _ in }

    let arguments = ExteraFeedArguments(
        selectCategory: { id in
            selectedCategoryId.set(id)
        },
        setAdblockEnabled: { value in
            updateSettings { $0.withUpdatedAdBlockEnabled(value) }
        },
        setIncludeArchived: { value in
            updateSettings { $0.withUpdatedFeedIncludeArchived(value) }
        },
        setFeedTabEnabled: { value in
            updateSettings { $0.withUpdatedFeedEnabled(value) }
        },
        markAllAsRead: {
            let peers = activePeerIds.with({ $0 })
            guard !peers.isEmpty else {
                return
            }
            let _ = context.engine.messages.togglePeersUnreadMarkInteractively(peerIds: peers, setToValue: nil).startStandalone()
        },
        openPost: { peerId, messageId in
            guard let controller = weakController, let navigationController = controller.navigationController as? NavigationController else {
                return
            }
            let _ = (context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
            |> deliverOnMainQueue).start(next: { peer in
                guard let peer else {
                    return
                }
                context.sharedContext.navigateToChatController(NavigateToChatControllerParams(
                    navigationController: navigationController,
                    context: context,
                    chatLocation: .peer(peer),
                    subject: .message(id: .id(messageId), highlight: nil, timecode: nil, setupReply: false)
                ))
            })
        },
        requestHideChannel: { peerId, title in
            let strings = stringsHolder.with({ $0 })
            let alertController = textAlertController(context: context, title: strings?.Extera_Feed_HideChannel ?? "", text: title, actions: [
                TextAlertAction(type: .genericAction, title: strings?.Common_Cancel ?? "", action: {}),
                TextAlertAction(type: .defaultAction, title: strings?.Extera_Feed_Hide ?? "", action: {
                    exteraFeedSetChannelHidden(peerId, hidden: true, defaults: defaults)
                    refreshCounter.with { current -> Int in
                        let updated = current + 1
                        refreshPromise.set(updated)
                        return updated
                    }
                })
            ])
            presentControllerImpl(alertController, nil)
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        settingsSignal,
        selectedCategoryId.get(),
        refreshPromise.get()
    )
    |> mapToSignal { presentationData, settings, categoryId, _ -> Signal<ExteraFeedModel, NoError> in
        let hiddenPeerIds = Set(exteraFeedHiddenChannelIds(defaults: defaults).map { PeerId($0) })

        return context.engine.messages.exteraFeedChannels()
        |> mapToSignal { channels -> Signal<ExteraFeedModel, NoError> in
            let peerIds = exteraFeedVisiblePeerIds(settings: settings, categoryId: categoryId, channels: channels, hiddenPeerIds: hiddenPeerIds)
            let titles = Dictionary(channels.map { ($0.peer.id, $0.peer.compactDisplayTitle) }, uniquingKeysWith: { first, _ in first })

            guard !peerIds.isEmpty else {
                return .single(ExteraFeedModel(presentationData: presentationData, settings: settings, categoryId: categoryId, posts: [], activePeerIds: []))
            }

            let messagesSignal = context.engine.messages.exteraFeedMessages(peerIds: peerIds, countPerPeer: 30)
            let unreadSignals = combineLatest(peerIds.map { peerId in
                context.engine.data.subscribe(TelegramEngine.EngineData.Item.Messages.PeerUnreadCount(id: peerId, handleThreads: false))
            })

            return combineLatest(messagesSignal, unreadSignals)
            |> map { grouped, counts -> ExteraFeedModel in
                let unreadByPeer = Dictionary(zip(peerIds, counts), uniquingKeysWith: { _, second in second })
                return ExteraFeedModel(
                    presentationData: presentationData,
                    settings: settings,
                    categoryId: categoryId,
                    posts: exteraFeedPosts(grouped: grouped, titles: titles, unreadCounts: unreadByPeer),
                    activePeerIds: peerIds
                )
            }
        }
    }
    |> map { model -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let _ = activePeerIds.swap(model.activePeerIds)
        let _ = stringsHolder.swap(model.presentationData.strings)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(model.presentationData), entries: exteraFeedEntries(model: model), style: .blocks, ensureVisibleItemTag: nil, emptyStateItem: nil)
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(model.presentationData), title: .text(model.presentationData.strings.Extera_Feed_Title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: model.presentationData.strings.Common_Back))
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    weakController = controller
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }

    return controller
}
