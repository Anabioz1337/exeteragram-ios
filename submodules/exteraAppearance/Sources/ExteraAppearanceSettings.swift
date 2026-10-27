import Foundation
import SwiftSignalKit

/// Appearance toggles owned by the extera appearance domain.
///
/// Deliberately kept outside `PresentationData`/preferences pipelines (those belong to other
/// workstreams): the values live in the shared "exteraAppearance" suite and every surface re-reads
/// them on its own update pass. `updated` lets reactive hosts observe that a toggle flipped.
public final class ExteraAppearanceSettings {
    public static let shared = ExteraAppearanceSettings()

    /// Which identity the chat title shows: the display name (0) or the @username (1).
    public enum TitleTextMode: Int32 {
        case firstName
        case username

        public var rawInt: Int32 {
            switch self {
            case .firstName: return 0
            case .username: return 1
            }
        }

        public init(rawInt: Int32) {
            self = rawInt == 1 ? .username : .firstName
        }
    }

    private let defaults: UserDefaults
    private let versionPromise = ValuePromise<Int>(ignoreRepeated: true)
    private var currentVersion = 0

    private init() {
        if let suiteDefaults = UserDefaults(suiteName: "exteraAppearance") {
            self.defaults = suiteDefaults
        } else {
            self.defaults = .standard
        }
        self.defaults.register(defaults: [
            "forceBlur": false,
            "forceSnow": false,
            "avatarCorners": 30,
            "newSwitchStyle": true,
            "disableDividers": false,
            "hideActionBarStatus": false,
            "centerTitle": true,
            "titleText": 0,
            "useSystemFonts": false
        ])
    }

    public var updated: Signal<Int, NoError> {
        return self.versionPromise.get()
    }

    private func finishWriting() {
        self.currentVersion += 1
        self.versionPromise.set(self.currentVersion)
    }

    public var forceBlur: Bool {
        get { return self.defaults.bool(forKey: "forceBlur") }
        set {
            self.defaults.set(newValue, forKey: "forceBlur")
            self.finishWriting()
        }
    }

    public var forceSnow: Bool {
        get { return self.defaults.bool(forKey: "forceSnow") }
        set {
            self.defaults.set(newValue, forKey: "forceSnow")
            self.finishWriting()
        }
    }

    public var avatarCorners: Int32 {
        get { return Int32(self.defaults.integer(forKey: "avatarCorners")) }
        set {
            self.defaults.set(Int(newValue), forKey: "avatarCorners")
            self.finishWriting()
        }
    }

    public var newSwitchStyle: Bool {
        get { return self.defaults.bool(forKey: "newSwitchStyle") }
        set {
            self.defaults.set(newValue, forKey: "newSwitchStyle")
            self.finishWriting()
        }
    }

    public var disableDividers: Bool {
        get { return self.defaults.bool(forKey: "disableDividers") }
        set {
            self.defaults.set(newValue, forKey: "disableDividers")
            self.finishWriting()
        }
    }

    public var hideActionBarStatus: Bool {
        get { return self.defaults.bool(forKey: "hideActionBarStatus") }
        set {
            self.defaults.set(newValue, forKey: "hideActionBarStatus")
            self.finishWriting()
        }
    }

    /// Whether titles stay band-centered (the iOS base's own placement) or hug the left buttons.
    /// `true` is the registered default so an account that never touches this suite keeps the stock layout.
    public var centerTitle: Bool {
        get { return self.defaults.bool(forKey: "centerTitle") }
        set {
            self.defaults.set(newValue, forKey: "centerTitle")
            self.finishWriting()
        }
    }

    public var titleText: TitleTextMode {
        get { return TitleTextMode(rawInt: Int32(self.defaults.integer(forKey: "titleText"))) }
        set {
            self.defaults.set(newValue.rawInt, forKey: "titleText")
            self.finishWriting()
        }
    }

    /// Retained for parity with exteraGram's option list: every face this port draws comes through
    /// `Display.Font`/`UIFont.systemFont`, so system typography is already the only behaviour here.
    /// Kept so the preferences surface can store the toggle without drifting from the other platforms.
    public var useSystemFonts: Bool {
        get { return self.defaults.bool(forKey: "useSystemFonts") }
        set {
            self.defaults.set(newValue, forKey: "useSystemFonts")
            self.finishWriting()
        }
    }
}
