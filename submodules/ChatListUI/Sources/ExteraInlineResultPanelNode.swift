import Foundation
import UIKit
import AsyncDisplayKit
import SwiftSignalKit
import Display
import TelegramPresentationData
private let gearSide: CGFloat = 30.0

public final class ExteraInlineResultPanelNode: ASDisplayNode, UIGestureRecognizerDelegate {
    private let containerView = UIView()
    private var textNode: TextNode?
    private let gearNode = ASImageNode()

    public var resultTapped: ((String) -> Void)?
    public var settingsTapped: (() -> Void)?

    private var currentText: String?
    private var currentTheme: PresentationTheme
    private var validWidth: CGFloat?
    private var lastTextLayoutSize: CGSize?

    public init(theme: PresentationTheme) {
        self.currentTheme = theme
        super.init()
        self.view.addSubview(self.containerView)
        self.addSubnode(self.gearNode)
        self.updateBackground(for: theme)
        self.gearNode.image = generateTintedImage(image: UIImage(bundleImageName: "Wallet/InfoSettings"), color: theme.rootController.navigationBar.secondaryTextColor)
        self.gearNode.isUserInteractionEnabled = false

        let containerRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        containerRecognizer.delegate = self
        self.view.addGestureRecognizer(containerRecognizer)

        let gearRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleGearTap(_:)))
        gearRecognizer.delegate = self
        self.gearNode.view.addGestureRecognizer(gearRecognizer)
    }

    private func updateBackground(for theme: PresentationTheme) {
        self.containerView.backgroundColor = theme.rootController.navigationSearchBar.inputFillColor
        self.containerView.layer.cornerRadius = 13.0
        self.containerView.layer.masksToBounds = true
    }

    public func updateTheme(_ theme: PresentationTheme) {
        self.currentTheme = theme
        self.updateBackground(for: theme)
        self.gearNode.image = generateTintedImage(image: UIImage(bundleImageName: "Wallet/InfoSettings"), color: theme.rootController.navigationBar.secondaryTextColor)
        if let text = self.currentText {
            self.rebuildText(text: text, maximumWidth: self.validWidth ?? 320.0)
        }
    }

    public func updateResult(_ text: String?, maximumWidth: CGFloat) {
        self.validWidth = maximumWidth
        let hasResult = text != nil && !text!.isEmpty
        self.isHidden = !hasResult
        self.view.isUserInteractionEnabled = hasResult

        guard let text, !text.isEmpty else {
            self.currentText = nil
            if let node = self.textNode {
                self.textNode = nil
                node.removeFromSupernode()
            }
            return
        }
        guard self.currentText != text else {
            return
        }
        self.currentText = text
        self.rebuildText(text: text, maximumWidth: maximumWidth)
    }

    private func rebuildText(text: String, maximumWidth: CGFloat) {
        let attributed = NSAttributedString(
            string: "= \(text)",
            font: Font.regular(16.0),
            textColor: self.currentTheme.rootController.navigationBar.inputPlaceholderTextColor
        )
        let (layout, apply) = TextNode.asyncLayout(self.textNode)(TextNodeLayoutArguments(
            attributedString: attributed,
            backgroundColor: nil,
            minimumNumberOfLines: 0,
            maximumNumberOfLines: 1,
            truncationType: .end,
            constrainedSize: CGSize(width: maximumWidth - 2.0 * horizontalPadding - gearSide, height: .greatestFiniteMagnitude)
        ))
        let layoutNode = apply()
        if layoutNode !== self.textNode {
            self.textNode = layoutNode
            self.addSubnode(layoutNode)
        }
        self.lastTextLayoutSize = layout.size
        self.requestLayout()
    }

    public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        let contentWidth = size.width - 2.0 * horizontalPadding - gearSide
        transition.updateFrame(node: self.gearNode, frame: CGRect(
            x: size.width - horizontalPadding - gearSide + 4.0,
            y: (size.height - gearSide) / 2.0 + 1.0,
            width: gearSide,
            height: gearSide
        ))
        if let textNode = self.textNode, let layoutSize = self.lastTextLayoutSize {
            transition.updateFrame(node: textNode, frame: CGRect(
                x: horizontalPadding,
                y: (size.height - layoutSize.height) / 2.0,
                width: min(layoutSize.width, contentWidth),
                height: layoutSize.height
            ))
        }
        self.containerView.frame = CGRect(origin: CGPoint(), size: size)
    }

    public static let horizontalPadding: CGFloat = 12.0
    public static let verticalPadding: CGFloat = 8.0

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else {
            return
        }
        let location = recognizer.location(in: self.view)
        if location.x >= self.view.bounds.width - horizontalPadding - gearSide {
            return
        }
        if let result = self.currentText {
            self.resultTapped?(result)
        }
    }

    @objc private func handleGearTap(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            self.settingsTapped?()
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}

