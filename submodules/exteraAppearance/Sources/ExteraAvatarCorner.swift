import UIKit

/// Corner radius for avatar containers derived from the `avatarCorners` setting.
///
/// `avatarCorners` is a radius in points: `0` renders a square, larger values round the corners,
/// and anything at or above half the avatar's side becomes a circle. The stock look is the
/// circular one for small avatars, which the default of `30` preserves (it clamps to a circle
/// everywhere the container is 60pt or smaller).
public func exteraAvatarCornerRadius(displayDimensions: CGSize) -> CGFloat {
    return min(CGFloat(ExteraAppearanceSettings.shared.avatarCorners), displayDimensions.height * 0.5)
}
