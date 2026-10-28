import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData

/// Transcript surfaced over the chat: a floating card above the message it belongs to,
/// with the recognized text selectable and a one-tap copy action.
public final class ExteraSpeechTranscriptPopupNode: ASDisplayNode {
    private let transcript: String

    private let backdropView: UIView
    private let cardContainerView: UIView
    private let cardBackground: BlurredBackgroundView
    private let titleLabel: UILabel
    private let transcriptView: UITextView
    private let copyButton: UIButton

    private var onCopy: () -> Void = {}
    private var requestDismiss: () -> Void = {}

    public init(presentationData: PresentationData, transcript: String, titleText: String, copyText: String, onCopy: @escaping () -> Void, requestDismiss: @escaping () -> Void) {
        self.transcript = transcript

        let theme = presentationData.theme.actionSheet
        self.backdropView = UIView()
        self.backdropView.backgroundColor = theme.dimColor
        self.backdropView.alpha = 0.0

        self.cardContainerView = UIView()
        self.cardContainerView.clipsToBounds = true

        self.cardBackground = BlurredBackgroundView(color: theme.itemBackgroundColor)
        self.cardBackground.layer.cornerRadius = 16.0
        self.cardContainerView.insertSubview(self.cardBackground, at: 0)

        self.titleLabel = UILabel()
        self.titleLabel.text = titleText.uppercased()
        self.titleLabel.font = Font.regular(11.0)
        self.titleLabel.textColor = theme.secondaryTextColor

        self.transcriptView = UITextView()
        self.transcriptView.isEditable = false
        self.transcriptView.isSelectable = true
        self.transcriptView.alwaysBounceVertical = true
        self.transcriptView.showsVerticalScrollIndicator = true
        self.transcriptView.font = Font.regular(16.0)
        self.transcriptView.textColor = theme.primaryTextColor
        self.transcriptView.backgroundColor = .clear
        self.transcriptView.text = transcript
        self.transcriptView.isAccessibilityElement = true
        self.transcriptView.accessibilityLabel = transcript

        self.copyButton = UIButton(type: .system)
        self.copyButton.setTitle(copyText.uppercased(), for: [])
        self.copyButton.setTitleColor(theme.controlAccentColor, for: [])
        self.copyButton.contentHorizontalAlignment = .right
        self.copyButton.addTarget(self, action: #selector(self.copyPressed), for: .touchUpInside)

        super.init()

        self.backdropView.addSubview(self.cardContainerView)
        self.cardContainerView.addSubview(self.titleLabel)
        self.cardContainerView.addSubview(self.transcriptView)
        self.cardContainerView.addSubview(self.copyButton)

        self.onCopy = onCopy
        self.requestDismiss = requestDismiss
    }

    override public func didLoad() {
        super.didLoad()
        self.view.addSubview(self.backdropView)
        let backdropTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.backdropTapped(_:)))
        self.backdropView.addGestureRecognizer(backdropTapRecognizer)
    }

    @objc private func copyPressed() {
        UIPasteboard.general.string = self.transcript
        self.onCopy()
        self.requestDismiss()
    }

    @objc private func backdropTapped(_ recognizer: UITapGestureRecognizer) {
        if !self.cardContainerView.frame.contains(recognizer.location(in: self.backdropView)) {
            self.requestDismiss()
        }
    }

    public func containerLayoutUpdated(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.backdropView.frame = CGRect(origin: CGPoint(), size: layout.size)

        let contentInsets = UIEdgeInsets(top: 14.0, left: 16.0, bottom: 10.0, right: 16.0)
        let titleHeight: CGFloat = 12.0
        let rowSpacing: CGFloat = 10.0
        let buttonHeight: CGFloat = 30.0
        let maxTextHeight = floor(layout.size.height * 0.55 - contentInsets.top - contentInsets.bottom - titleHeight - rowSpacing * 2.0 - buttonHeight)
        let measuredTextHeight = self.transcriptView.sizeThatFits(CGSize(width: layout.size.width - contentInsets.left - contentInsets.right, height: .greatestFiniteMagnitude)).height
        let textHeight = max(44.0, min(measuredTextHeight + 2.0, max(80.0, maxTextHeight)))

        let cardSize = CGSize(width: min(440.0, max(280.0, layout.size.width - 32.0)), height: contentInsets.top + titleHeight + rowSpacing + textHeight + rowSpacing + buttonHeight + contentInsets.bottom)
        let safeBottomInset = layout.safeInsets.bottom
        let cardFrame = CGRect(
            origin: CGPoint(x: floor((layout.size.width - cardSize.width) / 2.0), y: floor(max(contentInsets.top, layout.size.height - safeBottomInset - 12.0 - cardSize.height))),
            size: cardSize
        )

        transition.updateFrame(view: self.cardContainerView, frame: cardFrame)
        self.cardBackground.update(size: cardSize, cornerRadius: 16.0, transition: transition)
        transition.updateAlpha(layer: self.backdropView.layer, alpha: 1.0)
        transition.animateView(allowUserInteraction: true) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.titleLabel.frame = CGRect(origin: CGPoint(x: contentInsets.left, y: contentInsets.top), size: CGSize(width: cardSize.width - contentInsets.left - contentInsets.right, height: titleHeight))
            strongSelf.transcriptView.frame = CGRect(origin: CGPoint(x: contentInsets.left, y: contentInsets.top + titleHeight + rowSpacing), size: CGSize(width: cardSize.width - contentInsets.left - contentInsets.right, height: textHeight))
            strongSelf.copyButton.sizeToFit()
            let buttonSize = strongSelf.copyButton.bounds.size
            strongSelf.copyButton.frame = CGRect(
                origin: CGPoint(x: cardSize.width - contentInsets.right - buttonSize.width - 8.0, y: strongSelf.transcriptView.frame.maxY + rowSpacing),
                size: CGSize(width: buttonSize.width + 16.0, height: buttonHeight)
            )
            strongSelf.backdropView.alpha = 1.0
        }
    }

    public func animateIn(asReplacement: Bool) {
        let duration: Double = asReplacement ? 0.15 : 0.28
        self.cardContainerView.layer.animatePosition(from: CGPoint(x: 0.0, y: 48.0), to: CGPoint(), duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, additive: true)
        self.cardContainerView.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration, removeOnCompletion: false)
        self.backdropView.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25, removeOnCompletion: false)
    }

    public func animateOut(completion: (() -> Void)? = nil) {
        self.cardContainerView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.22, timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, removeOnCompletion: false, completion: { _ in
            completion?()
        })
        self.backdropView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.25, removeOnCompletion: false)
    }
}

public final class ExteraSpeechTranscriptPopupController: ViewController {
    private let presentationData: PresentationData
    private let transcript: String
    private let presentCopyFeedback: () -> Void
    private var didPlayPresentationAnimation = false

    public init(
        presentationData: PresentationData,
        transcript: String,
        presentCopyFeedback: @escaping () -> Void
    ) {
        self.presentationData = presentationData
        self.transcript = transcript
        self.presentCopyFeedback = presentCopyFeedback

        super.init(navigationBarPresentationData: nil)
        self.statusBar.statusBarStyle = .Ignore
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var popupNode: ExteraSpeechTranscriptPopupNode {
        return self.displayNode as! ExteraSpeechTranscriptPopupNode
    }

    override public func loadDisplayNode() {
        self.displayNode = ExteraSpeechTranscriptPopupNode(
            presentationData: self.presentationData,
            transcript: self.transcript,
            titleText: self.presentationData.strings.Extera_Speech_Popup_Title,
            copyText: self.presentationData.strings.Extera_Speech_Popup_Copy,
            onCopy: { [weak self] in
                self?.presentCopyFeedback()
            },
            requestDismiss: { [weak self] in
                self?.dismiss()
            }
        )
        self.displayNodeDidLoad()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.didPlayPresentationAnimation {
            self.didPlayPresentationAnimation = true
            self.popupNode.animateIn(asReplacement: false)
        }
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.popupNode.containerLayoutUpdated(layout: layout, transition: transition)
    }

    override public func dismiss(completion: (() -> Void)? = nil) {
        guard self.displayNode is ExteraSpeechTranscriptPopupNode else {
            return
        }
        self.popupNode.animateOut(completion: { [weak self] in
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
            completion?()
        })
    }
}
