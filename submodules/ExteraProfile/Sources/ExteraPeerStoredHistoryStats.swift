import Foundation
import Postbox
import SwiftSignalKit
import TelegramCore

/// Facts that can only be read out of the locally stored history: when the oldest message is
/// from (a stand-in for the chat's creation date outside channels) and how many of the stored
/// messages are forwards.
public struct ExteraPeerStoredHistoryStats: Equatable {
    public var earliestTimestamp: Int32?
    public var forwardsCount: Int32 = 0

    public init(earliestTimestamp: Int32?, forwardsCount: Int32 = 0) {
        self.earliestTimestamp = earliestTimestamp
        self.forwardsCount = forwardsCount
    }
}

private let scanChunkSize = 500

public func exteraPeerStoredHistoryStats(account: Account, peerId: EnginePeer.Id) -> Signal<ExteraPeerStoredHistoryStats?, NoError> {
    return account.postbox.transaction { transaction -> ExteraPeerStoredHistoryStats? in
        guard transaction.getPeer(peerId) != nil else {
            return nil
        }

        var stats = ExteraPeerStoredHistoryStats(earliestTimestamp: nil, forwardsCount: 0)
        var olderBoundary = MessageIndex.upperBound(peerId: peerId)

        while true {
            let chunk = transaction.getMessages(
                peerId: peerId,
                namespace: Namespaces.Message.Cloud,
                from: olderBoundary,
                includeFrom: false,
                to: MessageIndex.lowerBound(peerId: peerId),
                limit: scanChunkSize
            )
            if chunk.isEmpty {
                break
            }
            for message in chunk where message.forwardInfo != nil {
                stats.forwardsCount += 1
            }
            guard let oldest = chunk.min(by: { $0.index < $1.index }) else {
                break
            }
            if stats.earliestTimestamp == nil || oldest.timestamp < stats.earliestTimestamp! {
                stats.earliestTimestamp = oldest.timestamp
            }
            olderBoundary = oldest.index
        }

        return stats
    }
}
