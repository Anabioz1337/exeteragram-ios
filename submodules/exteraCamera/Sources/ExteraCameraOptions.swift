import Foundation
import SwiftSignalKit

public enum ExteraCameraLens: Int32, Codable, Equatable, CaseIterable {
    case auto
    case wide
    case ultrawide
}

public enum ExteraCameraMirrorMode: Int32, Codable, Equatable, CaseIterable {
    case off
    case on
    case auto
}

public enum ExteraVideoMessagesCamera: Int32, Codable, Equatable, CaseIterable {
    case ask
    case rear
    case front
}

public struct ExteraCameraSettings: Codable, Equatable {
    public var cameraTypeLens: ExteraCameraLens
    public var extendedFpsRange: Bool
    public var stabilization: Bool
    public var mirrorMode: ExteraCameraMirrorMode
    public var startWithWideAngle: Bool
    public var staticZoom: Bool
    public var zoomSlider: Bool
    public var videoMessagesCamera: ExteraVideoMessagesCamera
    public var rememberLastUsedCamera: Bool
    public var alwaysSendHD: Bool
    public var hideCameraTile: Bool
    public var hideInstantCameraTile: Bool

    public static let `default` = ExteraCameraSettings(
        cameraTypeLens: .auto,
        extendedFpsRange: false,
        stabilization: true,
        mirrorMode: .auto,
        startWithWideAngle: true,
        staticZoom: false,
        zoomSlider: false,
        videoMessagesCamera: .ask,
        rememberLastUsedCamera: false,
        alwaysSendHD: false,
        hideCameraTile: false,
        hideInstantCameraTile: false
    )

    public init(
        cameraTypeLens: ExteraCameraLens,
        extendedFpsRange: Bool,
        stabilization: Bool,
        mirrorMode: ExteraCameraMirrorMode,
        startWithWideAngle: Bool,
        staticZoom: Bool,
        zoomSlider: Bool,
        videoMessagesCamera: ExteraVideoMessagesCamera,
        rememberLastUsedCamera: Bool,
        alwaysSendHD: Bool,
        hideCameraTile: Bool,
        hideInstantCameraTile: Bool
    ) {
        self.cameraTypeLens = cameraTypeLens
        self.extendedFpsRange = extendedFpsRange
        self.stabilization = stabilization
        self.mirrorMode = mirrorMode
        self.startWithWideAngle = startWithWideAngle
        self.staticZoom = staticZoom
        self.zoomSlider = zoomSlider
        self.videoMessagesCamera = videoMessagesCamera
        self.rememberLastUsedCamera = rememberLastUsedCamera
        self.alwaysSendHD = alwaysSendHD
        self.hideCameraTile = hideCameraTile
        self.hideInstantCameraTile = hideInstantCameraTile
    }
}

public enum ExteraCameraPosition: String, Codable, Equatable {
    case rear
    case front
}

/// User defaults storage for the extera camera, kept in a dedicated
/// `exteraCamera` defaults suite, with change notification through a signal.
public final class ExteraCameraOptions {
    public static let shared = ExteraCameraOptions()

    private static let defaults = UserDefaults(suiteName: "exteraCamera") ?? .standard
    private static let settingsKey = "settings"
    private static let lastUsedCameraKey = "lastUsedCamera"

    private let promise = ValuePromise<ExteraCameraSettings>(ignoreRepeated: true)
    private let lastUsedCameraPromise = ValuePromise<ExteraCameraPosition?>(ignoreRepeated: true)
    private let lock = NSLock()
    private var cachedSettings: ExteraCameraSettings

    private init() {
        if let data = ExteraCameraOptions.defaults.data(forKey: ExteraCameraOptions.settingsKey), let settings = try? JSONDecoder().decode(ExteraCameraSettings.self, from: data) {
            self.cachedSettings = settings
        } else {
            self.cachedSettings = .default
        }
    }

    public var current: ExteraCameraSettings {
        return self.lock.with {
            self.cachedSettings
        }
    }

    public func update(_ settings: ExteraCameraSettings) {
        let data = (try? JSONEncoder().encode(settings)) ?? Data()
        ExteraCameraOptions.defaults.set(data, forKey: ExteraCameraOptions.settingsKey)
        self.promise.set(settings)
        self.lock.with {
            self.cachedSettings = settings
        }
    }

    public var settingsSignal: Signal<ExteraCameraSettings, NoError> {
        return self.promise.signal()
    }

    public var lastUsedCamera: ExteraCameraPosition? {
        guard let raw = ExteraCameraOptions.defaults.string(forKey: ExteraCameraOptions.lastUsedCameraKey) else {
            return nil
        }
        return ExteraCameraPosition(rawValue: raw)
    }

    public func recordLastUsedCamera(_ position: ExteraCameraPosition) {
        ExteraCameraOptions.defaults.set(position.rawValue, forKey: ExteraCameraOptions.lastUsedCameraKey)
        self.lastUsedCameraPromise.set(position)
    }

    public var lastUsedCameraSignal: Signal<ExteraCameraPosition?, NoError> {
        return self.lastUsedCameraPromise.signal()
    }
}

extension NSLock {
    fileprivate func with<T>(_ body: () -> T) -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return body()
    }
}
