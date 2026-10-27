import Foundation
import Postbox
import SwiftSignalKit

extension TelegramEngine.Messages {
    /// The most recent regular messages of every given channel, kept in per-peer order (oldest first).
    ///
    /// The feed aggregates each channel's own history view, so the query is a plain postbox view
    /// read: no server round trip, and updates arrive on every transaction that touches the history.
    public func exteraFeedMessages(peerIds: [EnginePeer.Id], countPerPeer: Int) -> Signal<[(peerId: EnginePeer.Id, messages: [EngineMessage])], NoError> {
        if peerIds.isEmpty {
            return .single([])
        }
        let postbox = self.account.postbox
        let signals: [Signal<[(peerId: EnginePeer.Id, messages: [EngineMessage])], NoError>] = peerIds.map { peerId in
            postbox.aroundMessageHistoryViewForLocation(
                .peer(peerId: peerId, threadId: nil),
                anchor: .upperBound,
                ignoreMessagesInTimestampRange: nil,
                ignoreMessageIds: Set(),
                count: countPerPeer,
                fixedCombinedReadStates: nil,
                topTaggedMessageIdNamespaces: Set(),
                tag: nil,
                appendMessagesFromTheSameGroup: false,
                namespaces: .not(Namespaces.Message.allNonRegular),
                orderStatistics: []
            )
            |> map { view, _ -> [(peerId: EnginePeer.Id, messages: [EngineMessage])] in
                let messages = view.entries.map { entry in
                    return EngineMessage(entry.message)
                }
                return [(EnginePeer.Id(peerId), messages)]
            }
        }
        return combineLatest(signals)
    }

    /// Which of the given peers live in the archived chat-list group.
    public func exteraFeedArchivedPeerIds(peerIds: [EnginePeer.Id]) -> Signal<Set<EnginePeer.Id>, NoError> {
        return self.account.postbox.transaction { transaction -> Set<EnginePeer.Id> in
            var archived = Set<EnginePeer.Id>()
            for peerId in peerIds {
                if case let .ifHasMessagesOrOneOf(groupId, _, _) = transaction.getPeerChatListInclusion(peerId), groupId == Namespaces.PeerGroup.archive {
                    archived.insert(peerId)
                }
            }
            return archived
        }
    }
}
