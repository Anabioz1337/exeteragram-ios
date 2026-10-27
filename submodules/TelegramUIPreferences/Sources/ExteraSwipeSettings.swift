import Foundation
import TelegramCore
import SwiftSignalKit

public enum ExteraSwipeAction: Int32 {
    case pin = 0
    case mute = 1
    case markAsRead = 2
    case archive = 3
    case delete = 4
}

public struct ExteraSwipeSettings: Codable, Equatable {
    public let areSwipeActionsEnabled: Bool
    public let loopSwipeActions: Bool
    public let reverseSwipeScrolling: Bool
    public let folderSwipeNavigation: Bool
    public let quickTransitionsFactor: Double
    public let predictiveBackIntensity: Double
    public let gooeyAvatars: Bool
    public let swipeActionIds: [Int32]

    public static var defaultSettings: ExteraSwipeSettings {
        return ExteraSwipeSettings(
            areSwipeActionsEnabled: true,
            loopSwipeActions: false,
            reverseSwipeScrolling: false,
            folderSwipeNavigation: true,
            quickTransitionsFactor: 1.0,
            predictiveBackIntensity: 1.0,
            gooeyAvatars: false,
            swipeActionIds: [
                ExteraSwipeAction.pin.rawValue,
                ExteraSwipeAction.mute.rawValue,
                ExteraSwipeAction.markAsRead.rawValue,
                ExteraSwipeAction.archive.rawValue,
                ExteraSwipeAction.delete.rawValue
            ]
        )
    }

    public init(areSwipeActionsEnabled: Bool, loopSwipeActions: Bool, reverseSwipeScrolling: Bool, folderSwipeNavigation: Bool, quickTransitionsFactor: Double, predictiveBackIntensity: Double, gooeyAvatars: Bool, swipeActionIds: [Int32]) {
        self.areSwipeActionsEnabled = areSwipeActionsEnabled
        self.loopSwipeActions = loopSwipeActions
        self.reverseSwipeScrolling = reverseSwipeScrolling
        self.folderSwipeNavigation = folderSwipeNavigation
        self.quickTransitionsFactor = quickTransitionsFactor
        self.predictiveBackIntensity = predictiveBackIntensity
        self.gooeyAvatars = gooeyAvatars
        self.swipeActionIds = swipeActionIds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.areSwipeActionsEnabled = (try container.decodeIfPresent(Int32.self, forKey: "areSwipeActionsEnabled") ?? 1) != 0
        self.loopSwipeActions = (try container.decodeIfPresent(Int32.self, forKey: "loopSwipeActions") ?? 0) != 0
        self.reverseSwipeScrolling = (try container.decodeIfPresent(Int32.self, forKey: "reverseSwipeScrolling") ?? 0) != 0
        self.folderSwipeNavigation = (try container.decodeIfPresent(Int32.self, forKey: "folderSwipeNavigation") ?? 1) != 0
        self.quickTransitionsFactor = try container.decodeIfPresent(Double.self, forKey: "quickTransitionsFactor") ?? 1.0
        self.predictiveBackIntensity = try container.decodeIfPresent(Double.self, forKey: "predictiveBackIntensity") ?? 1.0
        self.gooeyAvatars = (try container.decodeIfPresent(Int32.self, forKey: "gooeyAvatars") ?? 0) != 0
        self.swipeActionIds = (try? container.decodeIfPresent([Int32].self, forKey: "swipeActionIds")) ?? ExteraSwipeSettings.defaultSettings.swipeActionIds
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode((self.areSwipeActionsEnabled ? 1 : 0) as Int32, forKey: "areSwipeActionsEnabled")
        try container.encode((self.loopSwipeActions ? 1 : 0) as Int32, forKey: "loopSwipeActions")
        try container.encode((self.reverseSwipeScrolling ? 1 : 0) as Int32, forKey: "reverseSwipeScrolling")
        try container.encode((self.folderSwipeNavigation ? 1 : 0) as Int32, forKey: "folderSwipeNavigation")
        try container.encode(self.quickTransitionsFactor, forKey: "quickTransitionsFactor")
        try container.encode(self.predictiveBackIntensity, forKey: "predictiveBackIntensity")
        try container.encode((self.gooeyAvatars ? 1 : 0) as Int32, forKey: "gooeyAvatars")
        try container.encode(self.swipeActionIds, forKey: "swipeActionIds")
    }

    public static func ==(lhs: ExteraSwipeSettings, rhs: ExteraSwipeSettings) -> Bool {
        return lhs.areSwipeActionsEnabled == rhs.areSwipeActionsEnabled && lhs.loopSwipeActions == rhs.loopSwipeActions && lhs.reverseSwipeScrolling == rhs.reverseSwipeScrolling && lhs.folderSwipeNavigation == rhs.folderSwipeNavigation && lhs.quickTransitionsFactor == rhs.quickTransitionsFactor && lhs.predictiveBackIntensity == rhs.predictiveBackIntensity && lhs.gooeyAvatars == rhs.gooeyAvatars && lhs.swipeActionIds == rhs.swipeActionIds
    }

    public func withUpdatedAreSwipeActionsEnabled(_ areSwipeActionsEnabled: Bool) -> ExteraSwipeSettings {
        return ExteraSwipeSettings(areSwipeActionsEnabled: areSwipeActionsEnabled, loopSwipeActions: self.loopSwipeActions, reverseSwipeScrolling: self.reverseSwipeScrolling, folderSwipeNavigation: self.folderSwipeNavigation, quickTransitionsFactor: self.quickTransitionsFactor, predictiveBackIntensity: self.predictiveBackIntensity, gooeyAvatars: self.gooeyAvatars, swipeActionIds: self.swipeActionIds)
    }

    public func withUpdatedLoopSwipeActions(_ loopSwipeActions: Bool) -> ExteraSwipeSettings {
        return ExteraSwipeSettings(areSwipeActionsEnabled: self.areSwipeActionsEnabled, loopSwipeActions: loopSwipeActions, reverseSwipeScrolling: self.reverseSwipeScrolling, folderSwipeNavigation: self.folderSwipeNavigation, quickTransitionsFactor: self.quickTransitionsFactor, predictiveBackIntensity: self.predictiveBackIntensity, gooeyAvatars: self.gooeyAvatars, swipeActionIds: self.swipeActionIds)
    }

    public func withUpdatedReverseSwipeScrolling(_ reverseSwipeScrolling: Bool) -> ExteraSwipeSettings {
        return ExteraSwipeSettings(areSwipeActionsEnabled: self.areSwipeActionsEnabled, loopSwipeActions: self.loopSwipeActions, reverseSwipeScrolling: reverseSwipeScrolling, folderSwipeNavigation: self.folderSwipeNavigation, quickTransitionsFactor: self.quickTransitionsFactor, predictiveBackIntensity: self.predictiveBackIntensity, gooeyAvatars: self.gooeyAvatars, swipeActionIds: self.swipeActionIds)
    }

    public func withUpdatedFolderSwipeNavigation(_ folderSwipeNavigation: Bool) -> ExteraSwipeSettings {
        return ExteraSwipeSettings(areSwipeActionsEnabled: self.areSwipeActionsEnabled, loopSwipeActions: self.loopSwipeActions, reverseSwipeScrolling: self.reverseSwipeScrolling, folderSwipeNavigation: folderSwipeNavigation, quickTransitionsFactor: self.quickTransitionsFactor, predictiveBackIntensity: self.predictiveBackIntensity, gooeyAvatars: self.gooeyAvatars, swipeActionIds: self.swipeActionIds)
    }

    public func withUpdatedQuickTransitionsFactor(_ quickTransitionsFactor: Double) -> ExteraSwipeSettings {
        return ExteraSwipeSettings(areSwipeActionsEnabled: self.areSwipeActionsEnabled, loopSwipeActions: self.loopSwipeActions, reverseSwipeScrolling: self.reverseSwipeScrolling, folderSwipeNavigation: self.folderSwipeNavigation, quickTransitionsFactor: quickTransitionsFactor, predictiveBackIntensity: self.predictiveBackIntensity, gooeyAvatars: self.gooeyAvatars, swipeActionIds: self.swipeActionIds)
    }

    public func withUpdatedPredictiveBackIntensity(_ predictiveBackIntensity: Double) -> ExteraSwipeSettings {
        return ExteraSwipeSettings(areSwipeActionsEnabled: self.areSwipeActionsEnabled, loopSwipeActions: self.loopSwipeActions, reverseSwipeScrolling: self.reverseSwipeScrolling, folderSwipeNavigation: self.folderSwipeNavigation, quickTransitionsFactor: self.quickTransitionsFactor, predictiveBackIntensity: predictiveBackIntensity, gooeyAvatars: self.gooeyAvatars, swipeActionIds: self.swipeActionIds)
    }

    public func withUpdatedGooeyAvatars(_ gooeyAvatars: Bool) -> ExteraSwipeSettings {
        return ExteraSwipeSettings(areSwipeActionsEnabled: self.areSwipeActionsEnabled, loopSwipeActions: self.loopSwipeActions, reverseSwipeScrolling: self.reverseSwipeScrolling, folderSwipeNavigation: self.folderSwipeNavigation, quickTransitionsFactor: self.quickTransitionsFactor, predictiveBackIntensity: self.predictiveBackIntensity, gooeyAvatars: gooeyAvatars, swipeActionIds: self.swipeActionIds)
    }

    public func withUpdatedSwipeActionIds(_ swipeActionIds: [Int32]) -> ExteraSwipeSettings {
        return ExteraSwipeSettings(areSwipeActionsEnabled: self.areSwipeActionsEnabled, loopSwipeActions: self.loopSwipeActions, reverseSwipeScrolling: self.reverseSwipeScrolling, folderSwipeNavigation: self.folderSwipeNavigation, quickTransitionsFactor: self.quickTransitionsFactor, predictiveBackIntensity: self.predictiveBackIntensity, gooeyAvatars: self.gooeyAvatars, swipeActionIds: swipeActionIds)
    }
}

public func updateExteraSwipeSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraSwipeSettings) -> ExteraSwipeSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraSwipeSettings, { entry in
            let currentSettings: ExteraSwipeSettings
            if let entry = entry?.get(ExteraSwipeSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = ExteraSwipeSettings.defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}
