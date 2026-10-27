import UIKit

/// Corner radius for avatar containers derived from the `avatarCorners` setting.
///
/// `avatarCorners` is a radius in points: 0 renders a square, at or above half the avatar's side
/// it renders a circle. Returns nil when the value is still the stock default of 30, so callers
/// keep their own stock geometry (circles / quarter-rounded rects) until the setting is moved.
public func exteraAvatarCornerRadius(displayDimensions: CGSize) -> CGFloat? {
    let cornerRadius = CGFloat(ExteraAppearanceSettings.shared.avatarCorners)
    guard cornerRadius != 30.0 else {
        return nil
    }
    return min(cornerRadius, displayDimensions.height * 0.5)
}
