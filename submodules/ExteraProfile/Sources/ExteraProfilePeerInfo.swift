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
        if let dc = photoDatacenterId(peer: peer) {
            return "\(id) (DC \(dc))"
        }
        return id
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
        let rawId = userId.id.rawValue
        for bracket in registrationYearBrackets where rawId < bracket.upTo {
            return bracket.year
        }
        return nil
    }
}
