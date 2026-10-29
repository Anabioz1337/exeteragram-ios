import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import PresentationDataUtils

private final class ExteraPageBlockedScreenNode: ASDisplayNode {
    private let titleNode: ASTextNode
    private let descriptionNode: ASTextNode
    private let urlNode: ASTextNode
    private let goBackButton: HighlightableButtonNode
    private let proceedButton: HighlightableButtonNode

    var goBack: (() -> Void)?
    var proceed: (() -> Void)?

    init(theme: PresentationTheme, strings: PresentationStrings, url: String) {
        self.titleNode = ASTextNode()
        self.descriptionNode = ASTextNode()
        self.urlNode = ASTextNode()
        self.goBackButton = HighlightableButtonNode()
        self.proceedButton = HighlightableButtonNode()

        super.init()

        self.backgroundColor = theme.list.blocksBackgroundColor

        self.titleNode.attributedText = NSAttributedString(string: strings.Extera_Adblock_PageBlocked, font: Font.bold(22.0), textColor: theme.list.itemPrimaryTextColor, paragraphAlignment: .center)
        self.descriptionNode.attributedText = NSAttributedString(string: strings.Extera_Adblock_PageBlockedDescription, font: Font.regular(15.0), textColor: theme.list.itemSecondaryTextColor, paragraphAlignment: .center)
        self.urlNode.attributedText = NSAttributedString(string: url, font: Font.regular(15.0), textColor: theme.list.itemAccentColor, paragraphAlignment: .center)
        self.urlNode.maximumNumberOfLines = 4

        self.goBackButton.setTitle(strings.Extera_Adblock_PageBlockedGoBack, with: Font.medium(17.0), with: theme.list.itemAccentColor, for: .normal)
        self.goBackButton.setBackgroundImage(generateImage(CGSize(width: 220.0, height: 44.0), contextGenerator: { size, context in
            let bounds = CGRect(origin: CGPoint(), size: size)
            context.clear(bounds)
            context.setFillColor(theme.actionSheet.controlAccentColor.withAlphaComponent(0.12).cgColor)
            let path = UIBezierPath(roundedRect: bounds, cornerRadius: 22.0)
            context.addPath(path.cgPath)
            context.fillPath()
        }, opaque: false, scale: 2.0), for: .normal)
        self.goBackButton.addTarget(self, action: #selector(self.goBackPressed), forControlEvents: .touchUpInside)

        self.proceedButton.setTitle(strings.Extera_Adblock_PageBlockedProceed, with: Font.medium(17.0), with: theme.list.itemAccentColor, for: .normal)
        self.proceedButton.setBackgroundImage(generateImage(CGSize(width: 220.0, height: 44.0), contextGenerator: { size, context in
            let bounds = CGRect(origin: CGPoint(), size: size)
            context.clear(bounds)
            context.setFillColor(theme.actionSheet.controlAccentColor.withAlphaComponent(0.12).cgColor)
            let path = UIBezierPath(roundedRect: bounds, cornerRadius: 22.0)
            context.addPath(path.cgPath)
            context.fillPath()
        }, opaque: false, scale: 2.0), for: .normal)
        self.proceedButton.addTarget(self, action: #selector(self.proceedPressed), forControlEvents: .touchUpInside)

        self.addSubnode(self.titleNode)
        self.addSubnode(self.descriptionNode)
        self.addSubnode(self.urlNode)
        self.addSubnode(self.goBackButton)
        self.addSubnode(self.proceedButton)
    }

    @objc private func goBackPressed() {
        self.goBack?()
    }

    @objc private func proceedPressed() {
        self.proceed?()
    }

    override func layout() {
        let size = self.bounds.size
        let cardWidth: CGFloat = min(320.0, size.width - 32.0)

        var topOffset: CGFloat = size.height * 0.18
        let measureSize = CGSize(width: cardWidth, height: CGFloat.greatestFiniteMagnitude)
        let contentHeight: CGFloat = self.titleNode.measure(measureSize).height + 12.0 + self.descriptionNode.measure(measureSize).height + 8.0 + min(self.urlNode.measure(measureSize).height, 80.0)
        if topOffset + contentHeight > size.height * 0.6 {
            topOffset = max(24.0, (size.height - contentHeight - 140.0) / 2.0)
        }

        var y = topOffset
        let titleSize = self.titleNode.measure(measureSize)
        self.titleNode.frame = CGRect(origin: CGPoint(x: (size.width - titleSize.width) / 2.0, y: y), size: titleSize)
        y += titleSize.height + 12.0

        let descriptionSize = self.descriptionNode.measure(measureSize)
        self.descriptionNode.frame = CGRect(origin: CGPoint(x: (size.width - descriptionSize.width) / 2.0, y: y), size: descriptionSize)
        y += descriptionSize.height + 8.0

        let urlSize = self.urlNode.measure(measureSize)
        self.urlNode.frame = CGRect(origin: CGPoint(x: (size.width - urlSize.width) / 2.0, y: y), size: CGSize(width: min(urlSize.width, cardWidth), height: min(urlSize.height, 80.0)))

        self.goBackButton.frame = CGRect(x: (size.width - 220.0) / 2.0, y: size.height * 0.5, width: 220.0, height: 44.0)
        self.proceedButton.frame = CGRect(x: (size.width - 220.0) / 2.0, y: size.height * 0.5 + 52.0, width: 220.0, height: 44.0)
    }
}

/// The warning the fork shows when Block Ads intercepts a sponsored message: which page was
/// prevented from loading, with "Go back" (keep it blocked) and "Proceed" (show it this once).
public final class ExteraPageBlockedScreen: ViewController {
    private let theme: PresentationTheme
    private let strings: PresentationStrings
    private let url: String
    private let onProceed: () -> Void

    private var screenNode: ExteraPageBlockedScreenNode? {
        return self.displayNode as? ExteraPageBlockedScreenNode
    }

    public init(theme: PresentationTheme, strings: PresentationStrings, url: String, onProceed: @escaping () -> Void) {
        self.theme = theme
        self.strings = strings
        self.url = url
        self.onProceed = onProceed

        super.init(navigationBarPresentationData: nil)

        self.statusBar.statusBarStyle = theme.rootController.statusBarStyle.style
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadDisplayNode() {
        let node = ExteraPageBlockedScreenNode(theme: self.theme, strings: self.strings, url: self.url)
        node.goBack = { [weak self] in
            self?.dismiss()
        }
        node.proceed = { [weak self] in
            guard let self else {
                return
            }
            self.onProceed()
            self.dismiss()
        }
        self.displayNode = node
        self.displayNodeDidLoad()
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.screenNode?.frame = CGRect(origin: CGPoint(), size: layout.size)
        self.screenNode?.layoutIfNeeded()
    }
}
