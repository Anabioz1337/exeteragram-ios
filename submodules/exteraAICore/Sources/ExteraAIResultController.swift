import Foundation
import UIKit
import Display
import TelegramPresentationData

public final class ExteraAIResultController: UIViewController {
    private let theme: PresentationTheme
    private let strings: PresentationStrings
    private let titleText: String

    private let backdropView = UIView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let reasoningLabel = UILabel()
    private let resultTextView = UITextView()
    private let statusLabel = UILabel()
    private let insertButton = UIButton()
    private let copyButton = UIButton()
    private let closeButton = UIButton()

    private var contentText: String = ""
    private var reasoningText: String = ""
    private var isGenerating: Bool = true

    public var onInsert: ((String) -> Void)?
    public var onCopy: ((String) -> Void)?
    public var onClose: (() -> Void)?

    public init(theme: PresentationTheme, strings: PresentationStrings, title: String) {
        self.theme = theme
        self.strings = strings
        self.titleText = title

        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .clear

        self.backdropView.backgroundColor = self.theme.list.itemBlocksBackgroundColor.withAlphaComponent(0.55)
        self.backdropView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.closePressed)))
        self.view.addSubview(self.backdropView)

        self.cardView.backgroundColor = self.theme.actionSheet.opaqueItemBackgroundColor
        self.cardView.layer.cornerRadius = 16.0
        self.cardView.layer.masksToBounds = true
        self.view.addSubview(self.cardView)

        self.titleLabel.text = self.titleText
        self.titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        self.titleLabel.textColor = self.theme.actionSheet.primaryTextColor
        self.cardView.addSubview(self.titleLabel)

        self.reasoningLabel.numberOfLines = 3
        self.reasoningLabel.font = UIFont.italicSystemFont(ofSize: 13.0)
        self.reasoningLabel.textColor = self.theme.list.itemSecondaryTextColor
        self.cardView.addSubview(self.reasoningLabel)

        self.resultTextView.backgroundColor = .clear
        self.resultTextView.isEditable = false
        self.resultTextView.alwaysBounceVertical = true
        self.resultTextView.font = UIFont.systemFont(ofSize: 16.0)
        self.resultTextView.textColor = self.theme.actionSheet.primaryTextColor
        self.cardView.addSubview(self.resultTextView)

        self.statusLabel.text = self.strings.ExteraAI_ResultGenerating
        self.statusLabel.font = UIFont.systemFont(ofSize: 13.0)
        self.statusLabel.textColor = self.theme.list.itemSecondaryTextColor
        self.cardView.addSubview(self.statusLabel)

        self.configureButton(self.insertButton, title: self.strings.ExteraAI_ResultInsertQuote, emphasized: true, action: #selector(self.insertPressed))
        self.cardView.addSubview(self.insertButton)

        self.configureButton(self.copyButton, title: self.strings.ExteraAI_ResultCopy, emphasized: false, action: #selector(self.copyPressed))
        self.cardView.addSubview(self.copyButton)

        self.configureButton(self.closeButton, title: self.strings.ExteraAI_ResultClose, emphasized: false, action: #selector(self.closePressed))
        self.cardView.addSubview(self.closeButton)

        self.applyState()
    }

    private func configureButton(_ button: UIButton, title: String, emphasized: Bool, action: Selector) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(emphasized ? self.theme.actionSheet.controlAccentColor : self.theme.actionSheet.primaryTextColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: emphasized ? .semibold : .regular)
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    public func update(content: String, reasoning: String, isGenerating: Bool) {
        self.contentText = content
        self.reasoningText = reasoning
        self.isGenerating = isGenerating
        if self.isViewLoaded {
            self.applyState()
        }
    }

    public func fail(title: String, info: String) {
        self.isGenerating = false
        self.statusLabel.text = title + "\n" + info
        self.statusLabel.textColor = self.theme.list.itemDestructiveColor
        self.statusLabel.isHidden = false
        self.insertButton.isEnabled = !self.contentText.isEmpty
        self.copyButton.isEnabled = !self.contentText.isEmpty
    }

    private func applyState() {
        self.resultTextView.text = self.contentText
        self.reasoningLabel.text = self.reasoningText.isEmpty ? nil : self.reasoningText
        self.reasoningLabel.isHidden = self.reasoningText.isEmpty
        self.statusLabel.isHidden = !self.isGenerating || !self.contentText.isEmpty
        self.insertButton.isEnabled = !self.contentText.isEmpty
        self.copyButton.isEnabled = !self.contentText.isEmpty
        self.view.setNeedsLayout()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let bounds = self.view.bounds
        self.backdropView.frame = bounds

        let margin: CGFloat = 24.0
        let cardWidth = min(bounds.width - margin * 2.0, 420.0)
        let cardHeight: CGFloat = min(bounds.height * 0.6, 420.0)
        let cardFrame = CGRect(
            x: floor((bounds.width - cardWidth) / 2.0),
            y: floor((bounds.height - cardHeight) / 2.0),
            width: cardWidth,
            height: cardHeight
        )
        self.cardView.frame = cardFrame

        let inset: CGFloat = 16.0
        let contentWidth = cardFrame.width - inset * 2.0
        var y = inset

        self.titleLabel.frame = CGRect(origin: CGPoint(x: inset, y: y), size: self.titleLabel.sizeThatFits(CGSize(width: contentWidth, height: .greatestFiniteMagnitude)))
        y = self.titleLabel.frame.maxY + 8.0

        if !self.reasoningLabel.isHidden {
            self.reasoningLabel.frame = CGRect(origin: CGPoint(x: inset, y: y), size: self.reasoningLabel.sizeThatFits(CGSize(width: contentWidth, height: .greatestFiniteMagnitude)))
            y = self.reasoningLabel.frame.maxY + 8.0
        }

        let buttonHeight: CGFloat = 44.0
        let textHeight = cardFrame.height - y - inset - buttonHeight - 8.0
        self.resultTextView.frame = CGRect(x: inset, y: y, width: contentWidth, height: max(textHeight, 40.0))
        y = self.resultTextView.frame.maxY + 8.0

        self.statusLabel.frame = CGRect(origin: CGPoint(x: inset, y: y), size: self.statusLabel.sizeThatFits(CGSize(width: contentWidth, height: .greatestFiniteMagnitude)))

        let buttonY = cardFrame.height - inset - buttonHeight
        let buttonWidth = floor((contentWidth - 16.0) / 3.0)
        self.insertButton.frame = CGRect(x: inset, y: buttonY, width: buttonWidth, height: buttonHeight)
        self.copyButton.frame = CGRect(x: inset + buttonWidth + 8.0, y: buttonY, width: buttonWidth, height: buttonHeight)
        self.closeButton.frame = CGRect(x: inset + (buttonWidth + 8.0) * 2.0, y: buttonY, width: buttonWidth, height: buttonHeight)
    }

    @objc private func insertPressed() {
        self.onInsert?(self.contentText)
        self.closePressed()
    }

    @objc private func copyPressed() {
        UIPasteboard.general.string = self.contentText
        self.onCopy?(self.contentText)
    }

    @objc private func closePressed() {
        self.onClose?()
        self.dismiss(animated: true)
    }
}
