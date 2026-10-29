import Foundation
import Postbox
import TelegramCore

private func cloudPhotoRepresentations(peer: Peer) -> [TelegramMediaImageRepresentation] {
    if let user = peer as? TelegramUser {
        return user.photo
    } else if let channel = peer as? TelegramChannel {
        return channel.photo
    } else if let group = peer as? TelegramGroup {
        return group.photo
    }
    return []
}

private let datacenterLocations: [Int: String] = [
    1: "Miami FL, USA",
    2: "Amsterdam, NL",
    3: "Miami FL, USA",
    4: "Amsterdam, NL",
    5: "Singapore, SG"
]

public enum ExteraProfilePeerInfo {
    /// Peer id as the Bot API spells it: users keep their raw id, basic groups get a minus,
    /// channels and supergroups are prefixed with -100.
    public static func botApiIdString(peer: Peer) -> String {
        switch peer.id.namespace {
        case Namespaces.Peer.CloudUser:
            return "\(peer.id.id._internalGetInt64Value())"
        case Namespaces.Peer.CloudGroup:
            return "-\(peer.id.id._internalGetInt64Value())"
        case Namespaces.Peer.CloudChannel:
            return "-100\(peer.id.id._internalGetInt64Value())"
        default:
            return "\(peer.id.toInt64())"
        }
    }

    /// Datacenter the peer's current profile photo lives in. Both users and chats parse their
    /// cloud photos into `CloudPeerPhotoSizeMediaResource`, which carries the dc id.
    public static func photoDatacenterId(peer: Peer) -> Int? {
        guard let representation = cloudPhotoRepresentations(peer: peer).first(where: { $0.resource is CloudPeerPhotoSizeMediaResource }) else {
            return nil
        }
        guard let resource = representation.resource as? CloudPeerPhotoSizeMediaResource else {
            return nil
        }
        return resource.datacenterId
    }

    public static func idAndDcLine(peer: Peer) -> String {
        let id = botApiIdString(peer: peer)
        if let dc = photoDatacenterId(peer: peer), let location = datacenterLocations[dc] {
            return "\(id)\nDC\(dc), \(location)"
        }
        return id
    }

    /// The exact creation date only exists on channels and supergroups; every other peer kind
    /// falls back to the oldest locally stored message (`exteraPeerStoredHistoryStats`).
    public static func exactCreationDate(channel: TelegramChannel) -> Int32? {
        return channel.creationDate
    }
}

/// Coarse mapping from a cloud user id to the year Telegram assigned ids of that size.
/// Registration dates are not exposed by the API, so this stays a wide-brush estimate.
private let registrationYearBrackets: [(upTo: Int64, year: Int)] = [
    (upTo: 10_000_000, year: 2013),
    (upTo: 250_000_000, year: 2015),
    (upTo: 1_000_000_000, year: 2017),
    (upTo: 2_500_000_000, year: 2020),
    (upTo: Int64.max, year: 2024)
]

public extension ExteraProfilePeerInfo {
    static func approximateRegistrationYear(userId: EnginePeer.Id) -> Int? {
        guard userId.namespace == Namespaces.Peer.CloudUser else {
            return nil
        }
        let rawId = userId.id._internalGetInt64Value()
        for bracket in registrationYearBrackets where rawId < bracket.upTo {
            return bracket.year
        }
        return nil
    }
}
