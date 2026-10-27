import Foundation

public enum ExteraChatP1 {
    public static let suiteName = "exteraChatP1"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }

    public static var stickerSizeAdjustment: Double {
        get { defaults.object(forKey: "stickerSizeAdjustment") as? Double ?? 16.0 }
        set { defaults.set(newValue, forKey: "stickerSizeAdjustment") }
    }

    public static var hideReactions: Bool {
        get { defaults.bool(forKey: "hideReactions") }
        set { defaults.set(newValue, forKey: "hideReactions") }
    }

    public static var editedAsIcon: Bool {
        get { defaults.bool(forKey: "editedAsIcon") }
        set { defaults.set(newValue, forKey: "editedAsIcon") }
    }

    public static var stickerTimeHidden: Bool {
        get { defaults.bool(forKey: "stickerTimeHidden") }
        set { defaults.set(newValue, forKey: "stickerTimeHidden") }
    }

    public static var unlimitedRecentStickers: Bool {
        get { defaults.bool(forKey: "unlimitedRecentStickers") }
        set { defaults.set(newValue, forKey: "unlimitedRecentStickers") }
    }

    public static var widePosts: Bool {
        get { defaults.bool(forKey: "widePosts") }
        set { defaults.set(newValue, forKey: "widePosts") }
    }

    public static var replyAccentBackground: Bool {
        get { defaults.bool(forKey: "replyAccentBackground") }
        set { defaults.set(newValue, forKey: "replyAccentBackground") }
    }

    public static var bottomButtonStyle: Int {
        get { defaults.object(forKey: "bottomButtonStyle") as? Int ?? 0 }
        set { defaults.set(newValue, forKey: "bottomButtonStyle") }
    }
}
