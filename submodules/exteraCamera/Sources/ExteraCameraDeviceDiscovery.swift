import Foundation
import AVFoundation

public enum ExteraCameraDiscoveryResult: Equatable {
    /// `nil` device means "not overridden, follow the stock selection".
    case stock
    case device(AVCaptureDevice)
}

/// Resolves the extera preferred video device for the given capture position.
///
/// The stock selection picks the most "primary" device (triple camera, dual camera, wide angle);
/// the extera lens preference overrides the back-camera pick with a dedicated lens, and
/// `startWithWideAngle` pinning the initial video message camera to the plain wide-angle
/// camera overrides the more constrained multi-lens picks.
public func exteraCameraPreferredVideoDevice(position: AVCaptureDevice.Position, settings: ExteraCameraSettings? = nil) -> ExteraCameraDiscoveryResult {
    let settings = settings ?? ExteraCameraOptions.shared.current
    guard position != .front else {
        return .stock
    }

    var preferredDeviceType: AVCaptureDevice.DeviceType?
    switch settings.cameraTypeLens {
    case .auto:
        if !settings.startWithWideAngle {
            preferredDeviceType = .builtInWideAngleCamera
        }
    case .wide:
        preferredDeviceType = .builtInWideAngleCamera
    case .ultrawide:
        preferredDeviceType = .builtInUltraWideCamera
    }

    guard let deviceType = preferredDeviceType else {
        return .stock
    }

    if let device = AVCaptureDevice.default(deviceType, for: .video, position: position) {
        return .device(device)
    }
    if let device = AVCaptureDevice.DiscoverySession(
        deviceTypes: [deviceType, .builtInWideAngleCamera],
        mediaType: .video,
        position: position
    ).devices.first(where: { $0.deviceType == deviceType.rawValue }) {
        return .device(device)
    }
    return .stock
}

/// Extended frame rate ceiling used when the extended FPS range is enabled.
public let exteraCameraExtendedMaxFramerate: Double = 60.0

/// Resolves the extera mirror mode against the device position.
public func exteraCameraMirror(deviceIsFront: Bool, settings: ExteraCameraSettings? = nil) -> Bool {
    let settings = settings ?? ExteraCameraOptions.shared.current
    switch settings.mirrorMode {
    case .off:
        return false
    case .on:
        return true
    case .auto:
        return deviceIsFront
    }
}

/// Stabilization gate: whether the standard stabilization mode may be requested.
public func exteraCameraStabilizationEnabled(settings: ExteraCameraSettings? = nil) -> Bool {
    return (settings ?? ExteraCameraOptions.shared.current).stabilization
}
