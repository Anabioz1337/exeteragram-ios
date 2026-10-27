import UIKit

/// Falling snow over the navigation bar, forced by the extera `forceSnow` setting. Renders above
/// the bar's own content, ignores touches; flakes render white against both light and dark themes.
public final class ExteraSnowView: UIView {
    public override class var layerClass: AnyClass {
        return CAEmitterLayer.self
    }

    var emitterLayer: CAEmitterLayer {
        return self.layer as! CAEmitterLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.setupEmitter()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeFlakeImage() -> UIImage {
        let diameter = CGFloat(6.0)
        let size = CGSize(width: diameter, height: diameter)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: CGRect(origin: CGPoint(), size: size).insetBy(dx: diameter * 0.3, dy: diameter * 0.3))
        }
    }

    private func setupEmitter() {
        let layer = self.emitterLayer
        layer.emitterShape = .line
        layer.emitterSize = CGSize(width: 1.0, height: 1.0)
        layer.renderMode = .additive

        let flakeImage = self.makeFlakeImage()
        let cell = CAEmitterCell()
        cell.contents = flakeImage.cgImage
        cell.birthRate = 14.0
        cell.lifetime = 8.0
        cell.velocity = 60.0
        cell.velocityRange = 30.0
        cell.yAcceleration = 18.0
        cell.emissionRange = .pi
        cell.scale = 0.12
        cell.scaleRange = 0.1
        cell.alphaSpeed = -0.02
        cell.spinRange = .pi

        layer.emitterCells = [cell]
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.emitterLayer.emitterPosition = CGPoint(x: self.bounds.midX, y: self.bounds.minY)
        self.emitterLayer.emitterSize = CGSize(width: max(self.bounds.width, 1.0), height: 1.0)
    }
}
