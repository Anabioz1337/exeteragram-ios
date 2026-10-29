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

public func exteraPeerStoredHistoryStats(account: Account, peerId: EnginePeer.Id) -> Signal<ExteraPeerStoredHistoryStats?, NoError> {
    return account.postbox.transaction { transaction -> ExteraPeerStoredHistoryStats? in
        guard transaction.getPeer(peerId) != nil else {
            return nil
        }

        var stats = ExteraPeerStoredHistoryStats(earliestTimestamp: nil, forwardsCount: 0)
        transaction.scanTopMessages(peerId: peerId, namespace: Namespaces.Message.Cloud, limit: Int(Int32.max)) { message in
            if message.forwardInfo != nil {
                stats.forwardsCount += 1
            }
            if let current = stats.earliestTimestamp {
                if message.timestamp < current {
                    stats.earliestTimestamp = message.timestamp
                }
            } else {
                stats.earliestTimestamp = message.timestamp
            }
            return true
        }

        return stats
    }
}
