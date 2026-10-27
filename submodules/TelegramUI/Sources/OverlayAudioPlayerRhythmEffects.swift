import Foundation
import UIKit
import Display
import SwiftSignalKit

private func rhythmGlowImage() -> UIImage? {
    return generateImage(CGSize(width: 100.0, height: 100.0), rotatedContext: { size, context in
        UIGraphicsPushContext(context)
        context.clear(CGRect(origin: CGPoint(), size: size))

        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
            UIColor(white: 1.0, alpha: 0.42).cgColor,
            UIColor(white: 1.0, alpha: 0.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        if let gradient = gradient {
            context.drawRadialGradient(gradient, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: size.width / 2.0, options: [])
        }

        UIGraphicsPopContext()
    })
}

private func rhythmSparkPath(diameter: CGFloat) -> UIBezierPath {
    return UIBezierPath(roundedRect: CGRect(origin: CGPoint(), size: CGSize(width: diameter, height: diameter)), cornerRadius: diameter / 2.0)
}

/// The pulsing halo behind the expanded album art, driven by the player's output amplitude.
final class RhythmGlowView: UIImageView {
    private static let image: UIImage? = rhythmGlowImage()

    init() {
        super.init(frame: CGRect())

        self.isUserInteractionEnabled = false
        self.isOpaque = false
        self.image = RhythmGlowView.image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLevel(_ level: CGFloat) {
        let scale = 0.92 + level * 0.18
        self.alpha = 0.15 + level * 0.55
        self.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}

/// Sparks emitted on loud playback levels while a track plays.
final class RhythmParticlesNode: ASDisplayNode {
    private let sparkPath = rhythmSparkPath(diameter: 4.0)

    init() {
        super.init()

        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func emit(level: CGFloat, color: UIColor, boundsSize: CGSize) {
        guard level > 0.2, boundsSize.width > 0.0, (self.layer.sublayers?.count ?? 0) < 24 else {
            return
        }
        let layer = CAShapeLayer()
        layer.path = self.sparkPath.cgPath
        layer.fillColor = color.withAlphaComponent(0.85).cgColor
        layer.position = CGPoint(x: CGFloat.random(in: 0.15 ... 0.85) * boundsSize.width, y: boundsSize.height)

        self.layer.addSublayer(layer)

        let duration: Double = 1.1 + level * 0.8
        let targetPosition = CGPoint(x: layer.position.x, y: boundsSize.height - boundsSize.height * (0.35 + level * 0.45))
        layer.animatePosition(from: layer.position, to: targetPosition, duration: duration, removeOnCompletion: false)
        layer.animateAlpha(from: 0.9, to: 0.0, duration: duration, removeOnCompletion: false, completion: { [weak layer] _ in
            layer?.removeFromSuperlayer()
        })
    }

    func clear() {
        if let sublayers = self.layer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
        }
    }
}
