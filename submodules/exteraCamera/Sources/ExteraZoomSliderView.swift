import Foundation
import UIKit

/// Horizontal zoom slider drawn over the camera preview area.
///
/// Reports a normalized 0...1 position; the consumer maps it to the camera's zoom range.
public final class ExteraZoomSliderView: UIView {
    public var onValueChanged: ((CGFloat) -> Void)?
    public var onInteractionEnded: (() -> Void)?

    private let trackLayer = CALayer()
    private let filledTrackLayer = CALayer()
    private let thumbLayer = CALayer()

    private var trackColor: UIColor
    private var thumbColor: UIColor

    private static let trackHeight: CGFloat = 4.0
    private static let thumbDiameter: CGFloat = 22.0
    private static let horizontalPadding: CGFloat = 11.0

    private var isTracking = false

    public init(trackColor: UIColor, thumbColor: UIColor) {
        self.trackColor = trackColor
        self.thumbColor = thumbColor

        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 220.0, height: 36.0)))

        self.backgroundColor = .clear

        self.trackLayer.cornerRadius = ExteraZoomSliderView.trackHeight / 2.0
        self.filledTrackLayer.cornerRadius = ExteraZoomSliderView.trackHeight / 2.0
        self.thumbLayer.cornerRadius = ExteraZoomSliderView.thumbDiameter / 2.0
        for layer in [self.trackLayer, self.filledTrackLayer, self.thumbLayer] {
            layer.masksToBounds = true
            self.layer.addSublayer(layer)
        }

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        panRecognizer.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panRecognizer)
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    /// Re-applies the palette without rebuilding the view.
    public func updateColors(track: UIColor, thumb: UIColor) {
        self.trackColor = track
        self.thumbColor = thumb
        self.applyColors()
    }

    private func applyColors() {
        self.trackLayer.backgroundColor = self.trackColor.withAlphaComponent(0.3).cgColor
        self.filledTrackLayer.backgroundColor = self.thumbColor.cgColor
        self.thumbLayer.backgroundColor = self.thumbColor.cgColor
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.applyColors()
        self.updateLayers(animated: false)
    }

    private var normalizedValue: CGFloat = 0.0

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            self.isTracking = true
            self.updateFromLocation(recognizer.location(in: self))
        case .changed:
            self.updateFromLocation(recognizer.location(in: self))
        case .ended, .cancelled:
            self.isTracking = false
            self.onInteractionEnded?()
        default:
            break
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.isTracking = true
        if let touch = touches.first {
            self.updateFromLocation(touch.location(in: self))
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.isTracking = false
        self.onInteractionEnded?()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.isTracking = false
        self.onInteractionEnded?()
    }

    private func updateFromLocation(_ location: CGPoint) {
        let usableWidth = self.bounds.width - ExteraZoomSliderView.horizontalPadding * 2.0
        guard usableWidth > 0.0 else {
            return
        }
        let value = ((location.x - ExteraZoomSliderView.horizontalPadding) / usableWidth).clampedToUnitRange()
        self.setValue(value)
    }

    public func setValue(_ value: CGFloat) {
        self.normalizedValue = value.clampedToUnitRange()
        self.updateLayers(animated: !self.isTracking)
        self.onValueChanged?(self.normalizedValue)
    }

    private func updateLayers(animated: Bool) {
        let bounds = self.bounds
        guard bounds.width > 0.0 else {
            return
        }
        let trackY = (bounds.height - ExteraZoomSliderView.trackHeight) / 2.0
        let trackFrame = CGRect(
            x: ExteraZoomSliderView.horizontalPadding,
            y: trackY,
            width: bounds.width - ExteraZoomSliderView.horizontalPadding * 2.0,
            height: ExteraZoomSliderView.trackHeight
        )
        let thumbX = trackFrame.minX + self.normalizedValue * (trackFrame.width - ExteraZoomSliderView.thumbDiameter)
        let thumbFrame = CGRect(x: thumbX, y: (bounds.height - ExteraZoomSliderView.thumbDiameter) / 2.0, width: ExteraZoomSliderView.thumbDiameter, height: ExteraZoomSliderView.thumbDiameter)
        let filledWidth = max(ExteraZoomSliderView.trackHeight, thumbX + ExteraZoomSliderView.thumbDiameter - trackFrame.minX)

        self.trackLayer.frame = trackFrame
        CATransaction.begin()
        if !animated {
            CATransaction.setDisableActions(true)
        }
        self.filledTrackLayer.frame = CGRect(origin: trackFrame.origin, size: CGSize(width: filledWidth, height: ExteraZoomSliderView.trackHeight))
        self.thumbLayer.frame = thumbFrame
        CATransaction.commit()
    }
}

extension CGFloat {
    fileprivate func clampedToUnitRange() -> CGFloat {
        return Swift.max(0.0, Swift.min(1.0, self))
    }
}
