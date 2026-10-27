import Foundation
import SwiftSignalKit
import Postbox

public struct ExteraFeedChannel: Equatable {
    public let peer: EnginePeer
    public let isArchived: Bool

    public init(peer: EnginePeer, isArchived: Bool) {
        self.peer = peer
        self.isArchived = isArchived
    }
}

extension TelegramEngine.Messages {
    /// The most recent regular messages of every given channel, keyed per peer (oldest first).
    ///
    /// The feed aggregates each channel's own history view, so the query is a plain postbox view
    /// read: no server round trip, and updates arrive on every transaction that touches the history.
    public func exteraFeedMessages(peerIds: [PeerId], countPerPeer: Int) -> Signal<[(peerId: PeerId, messages: [EngineMessage])], NoError> {
        if peerIds.isEmpty {
            return .single([])
        }
        let postbox = self.account.postbox
        let signals: [Signal<(peerId: PeerId, messages: [EngineMessage]), NoError>] = peerIds.map { peerId in
            return postbox.aroundMessageHistoryViewForLocation(
                .peer(peerId: peerId, threadId: nil),
                anchor: .upperBound,
                ignoreMessagesInTimestampRange: nil,
                ignoreMessageIds: Set(),
                count: countPerPeer,
                fixedCombinedReadStates: nil,
                topTaggedMessageIdNamespaces: [],
                tag: nil,
                appendMessagesFromTheSameGroup: false,
                namespaces: .not(Namespaces.Message.allNonRegular),
                orderStatistics: []
            )
            |> map { view, _, _ -> (peerId: PeerId, messages: [EngineMessage]) in
                let messages = view.entries.map { entry in
                    return EngineMessage(entry.message)
                }
                return (peerId, messages)
            }
        }
        return combineLatest(signals)
    }

    /// Which of the given peers live in the archived chat-list group.
    public func exteraFeedArchivedPeerIds(peerIds: [PeerId]) -> Signal<Set<PeerId>, NoError> {
        return self.account.postbox.transaction { transaction -> Set<PeerId> in
            var archived = Set<PeerId>()
            for peerId in peerIds {
                if transaction.getPeerChatListInclusion(peerId).groupId == Namespaces.PeerGroup.archive {
                    archived.insert(peerId)
                }
            }
            return archived
        }
    }

    /// Every broadcast channel present in the chat list, with its archive placement. Read from the
    /// chat-list tables directly, so the result reflects whatever dialogs are stored at call time.
    public func exteraFeedChannels() -> Signal<[ExteraFeedChannel], NoError> {
        return self.account.postbox.transaction { transaction -> [ExteraFeedChannel] in
            var candidates = transaction.chatListGetAllPeerIds(groupId: PeerGroupId.root)
            candidates += transaction.chatListGetAllPeerIds(groupId: Namespaces.PeerGroup.archive)
            var channels: [ExteraFeedChannel] = []
            var seenPeers = Set<PeerId>()
            for peerId in candidates where !seenPeers.contains(peerId) {
                seenPeers.insert(peerId)
                guard let channel = transaction.getPeer(peerId) as? TelegramChannel,
                    case .broadcast = channel.info, !channel.flags.contains(.isForum) else {
                    continue
                }
                let isArchived = transaction.getPeerChatListInclusion(peerId).groupId == Namespaces.PeerGroup.archive
                channels.append(ExteraFeedChannel(peer: EnginePeer(channel), isArchived: isArchived))
            }
            channels.sort { lhs, rhs -> Bool in
                let lhsTitle = (lhs.peer._asPeer() as? TelegramChannel)?.title ?? ""
                let rhsTitle = (rhs.peer._asPeer() as? TelegramChannel)?.title ?? ""
                return lhsTitle.localizedCaseInsensitiveCompare(rhsTitle) == .orderedAscending
            }
        }
    }
}
