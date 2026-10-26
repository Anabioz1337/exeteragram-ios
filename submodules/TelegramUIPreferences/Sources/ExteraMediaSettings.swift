import Foundation
import TelegramCore
import SwiftSignalKit

public struct ExteraMediaSettings: Codable, Equatable {
    public let doubleTapSeekSeconds: Int32
    public let pauseOnMinimize: Bool
    public let disableVolumeAutoplay: Bool
    public let preferOriginalQuality: Bool
    public let pitchCents: Int32
    public let trackSavePeerIdRaw: Int64
    public let lyricsOnlineSearch: Bool
    public let rhythmBackground: Bool
    public let particles: Bool

    public static var defaultSettings: ExteraMediaSettings {
        return ExteraMediaSettings(
            doubleTapSeekSeconds: 10,
            pauseOnMinimize: true,
            disableVolumeAutoplay: true,
            preferOriginalQuality: false,
            pitchCents: 0,
            trackSavePeerIdRaw: 0,
            lyricsOnlineSearch: true,
            rhythmBackground: false,
            particles: false
        )
    }

    public init(doubleTapSeekSeconds: Int32, pauseOnMinimize: Bool, disableVolumeAutoplay: Bool, preferOriginalQuality: Bool, pitchCents: Int32, trackSavePeerIdRaw: Int64, lyricsOnlineSearch: Bool, rhythmBackground: Bool, particles: Bool) {
        self.doubleTapSeekSeconds = doubleTapSeekSeconds
        self.pauseOnMinimize = pauseOnMinimize
        self.disableVolumeAutoplay = disableVolumeAutoplay
        self.preferOriginalQuality = preferOriginalQuality
        self.pitchCents = pitchCents
        self.trackSavePeerIdRaw = trackSavePeerIdRaw
        self.lyricsOnlineSearch = lyricsOnlineSearch
        self.rhythmBackground = rhythmBackground
        self.particles = particles
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.doubleTapSeekSeconds = try container.decode(Int32.self, forKey: "doubleTapSeek")
        self.pauseOnMinimize = (try container.decodeIfPresent(Int32.self, forKey: "pauseOnMinimize") ?? 1) != 0
        self.disableVolumeAutoplay = (try container.decodeIfPresent(Int32.self, forKey: "disableVolumeAutoplay") ?? 1) != 0
        self.preferOriginalQuality = (try container.decodeIfPresent(Int32.self, forKey: "preferOriginalQuality") ?? 0) != 0
        self.pitchCents = try container.decodeIfPresent(Int32.self, forKey: "pitchCents") ?? 0
        self.trackSavePeerIdRaw = try container.decodeIfPresent(Int64.self, forKey: "trackSavePeerId") ?? 0
        self.lyricsOnlineSearch = (try container.decodeIfPresent(Int32.self, forKey: "lyricsOnlineSearch") ?? 1) != 0
        self.rhythmBackground = (try container.decodeIfPresent(Int32.self, forKey: "rhythmBackground") ?? 0) != 0
        self.particles = (try container.decodeIfPresent(Int32.self, forKey: "particles") ?? 0) != 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(self.doubleTapSeekSeconds, forKey: "doubleTapSeek")
        try container.encode((self.pauseOnMinimize ? 1 : 0) as Int32, forKey: "pauseOnMinimize")
        try container.encode((self.disableVolumeAutoplay ? 1 : 0) as Int32, forKey: "disableVolumeAutoplay")
        try container.encode((self.preferOriginalQuality ? 1 : 0) as Int32, forKey: "preferOriginalQuality")
        try container.encode(self.pitchCents, forKey: "pitchCents")
        try container.encode(self.trackSavePeerIdRaw, forKey: "trackSavePeerId")
        try container.encode((self.lyricsOnlineSearch ? 1 : 0) as Int32, forKey: "lyricsOnlineSearch")
        try container.encode((self.rhythmBackground ? 1 : 0) as Int32, forKey: "rhythmBackground")
        try container.encode((self.particles ? 1 : 0) as Int32, forKey: "particles")
    }

    public static func ==(lhs: ExteraMediaSettings, rhs: ExteraMediaSettings) -> Bool {
        return lhs.doubleTapSeekSeconds == rhs.doubleTapSeekSeconds && lhs.pauseOnMinimize == rhs.pauseOnMinimize && lhs.disableVolumeAutoplay == rhs.disableVolumeAutoplay && lhs.preferOriginalQuality == rhs.preferOriginalQuality && lhs.pitchCents == rhs.pitchCents && lhs.trackSavePeerIdRaw == rhs.trackSavePeerIdRaw && lhs.lyricsOnlineSearch == rhs.lyricsOnlineSearch && lhs.rhythmBackground == rhs.rhythmBackground && lhs.particles == rhs.particles
    }

    public func withUpdatedTrackSavePeerIdRaw(_ trackSavePeerIdRaw: Int64) -> ExteraMediaSettings {
        return ExteraMediaSettings(doubleTapSeekSeconds: self.doubleTapSeekSeconds, pauseOnMinimize: self.pauseOnMinimize, disableVolumeAutoplay: self.disableVolumeAutoplay, preferOriginalQuality: self.preferOriginalQuality, pitchCents: self.pitchCents, trackSavePeerIdRaw: trackSavePeerIdRaw, lyricsOnlineSearch: self.lyricsOnlineSearch, rhythmBackground: self.rhythmBackground, particles: self.particles)
    }
}

public func updateExteraMediaSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraMediaSettings) -> ExteraMediaSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraMediaSettings, { entry in
            let currentSettings: ExteraMediaSettings
            if let entry = entry?.get(ExteraMediaSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = ExteraMediaSettings.defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}
