import Foundation
import UIKit
import Display
import UniversalMediaPlayer

struct LyricsPlaybackSnapshot {
    let timestamp: Double
    let generationTimestamp: Double
    let baseRate: Double
    let isPlaying: Bool

    var playbackPosition: Double? {
        if self.isPlaying && !self.generationTimestamp.isZero {
            return self.timestamp + (CACurrentMediaTime() - self.generationTimestamp) * self.baseRate
        }
        return self.timestamp
    }
}

enum LyricsPresentationState: Equatable {
    case loading
    case timed([LrcLine])
    case plain([String])
    case instrumental(String)
    case message(String)
}

/// Scrolling synced-lyrics list rendered over the expanded player art area: every line draws a
/// dimmed copy with a fully-lit copy masked to the elapsed fraction of the active line.
final class AudioLyricsView: UIView, UIScrollViewDelegate {
    private final class Row {
        let baseLabel: UILabel
        let highlightLabel: UILabel
        let top: CGFloat
        let height: CGFloat
        let timestamp: Double?

        init(baseLabel: UILabel, highlightLabel: UILabel, top: CGFloat, height: CGFloat, timestamp: Double?) {
            self.baseLabel = baseLabel
            self.highlightLabel = highlightLabel
            self.top = top
            self.height = height
            self.timestamp = timestamp
        }
    }

    private static let sideInset: CGFloat = 28.0
    private static let rowSpacing: CGFloat = 16.0
    private static let verticalRevealInset: CGFloat = 44.0

    private let scrollView = UIScrollView()
    private let linesContainer = UIView()
    private let statusContainer = UIView()
    private let statusIndicator = UIActivityIndicatorView()
    private let statusLabel = UILabel()

    private var rows: [Row] = []
    private var activeRowIndex: Int?
    private var activeStart: Double = 0.0
    private var activeEnd: Double = .infinity
    private let activeMaskShape = CAShapeLayer()

    private(set) var presentationState: LyricsPresentationState = .loading
    private var playbackSnapshot: LyricsPlaybackSnapshot?

    private var primaryColor: UIColor = UIColor.white
    private var secondaryColor: UIColor = UIColor.white

    private var displayLink: SharedDisplayLinkDriver.Link?
    private var isUserScrolling = false
    private var didLayoutOnce = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        self.clipsToBounds = false

        self.scrollView.backgroundColor = .clear
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.delegate = self
        self.addSubview(self.scrollView)

        self.linesContainer.clipsToBounds = false
        self.scrollView.addSubview(self.linesContainer)

        self.statusContainer.backgroundColor = .clear
        self.statusContainer.isUserInteractionEnabled = false
        self.addSubview(self.statusContainer)

        self.statusIndicator.hidesWhenStopped = true
        self.statusContainer.addSubview(self.statusIndicator)

        self.statusLabel.numberOfLines = 0
        self.statusLabel.textAlignment = .center
        self.statusLabel.font = Font.medium(17.0)
        self.statusContainer.addSubview(self.statusLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.displayLink?.invalidate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let size = self.bounds.size
        guard size.width > 1.0, size.height > 1.0 else {
            return
        }
        let didResize = self.didLayoutOnce && self.scrollView.bounds.size.width > 1.0 && abs(self.scrollView.bounds.width - size.width) > 0.5
        self.scrollView.frame = CGRect(origin: CGPoint(), size: size)
        self.statusContainer.frame = CGRect(origin: CGPoint(), size: size)
        self.layoutStatusContainer(size: size)

        if !self.didLayoutOnce || didResize {
            self.didLayoutOnce = true
            let presentedState = self.presentationState
            self.rebuildRows(state: presentedState, width: size.width - AudioLyricsView.sideInset * 2.0)
            if case .timed = presentedState {
                self.refreshActiveLine()
            }
        }
    }

    func applyTheme(primaryColor: UIColor, secondaryColor: UIColor) {
        if self.primaryColor == primaryColor && self.secondaryColor == secondaryColor {
            return
        }
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor

        self.statusLabel.textColor = secondaryColor
        self.statusIndicator.color = secondaryColor
        for row in self.rows {
            row.baseLabel.textColor = self.inactiveTextColor
            row.highlightLabel.textColor = primaryColor
        }
    }

    func present(_ state: LyricsPresentationState) {
        guard state != self.presentationState else {
            return
        }
        self.presentationState = state
        if !self.didLayoutOnce {
            self.setNeedsLayout()
            return
        }

        switch state {
            case .timed, .plain:
                self.rebuildRows(state: state, width: self.bounds.width - AudioLyricsView.sideInset * 2.0)
                self.statusIndicator.stopAnimating()
                self.statusLabel.isHidden = true
            case .loading, .instrumental, .message:
                self.clearRowsAndActivatePlaceholder(state)
        }

        switch state {
            case .timed:
                self.startDisplayLink()
            default:
                self.stopDisplayLink()
        }
    }

    func updatePlaybackSnapshot(_ snapshot: LyricsPlaybackSnapshot) {
        let wasPlaying = self.playbackSnapshot?.isPlaying ?? false
        self.playbackSnapshot = snapshot
        if !snapshot.isPlaying || !wasPlaying {
            self.refreshActiveLine()
        }
    }

    /// Runs the per-frame active-line updates only while the view is shown.
    func setActive(_ active: Bool) {
        switch self.presentationState {
            case .timed:
                if active {
                    self.startDisplayLink()
                } else {
                    self.stopDisplayLink()
                }
            default:
                break
        }
    }

    private var inactiveTextColor: UIColor {
        return self.primaryColor.withAlphaComponent(0.42)
    }

    private func attributedLine(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left
        return NSAttributedString(string: text, attributes: [
            .font: Font.medium(17.0),
            .paragraphStyle: paragraphStyle
        ])
    }

    private func rebuildRows(state: LyricsPresentationState, width: CGFloat) {
        for subview in self.linesContainer.subviews {
            subview.removeFromSuperview()
        }
        self.rows.removeAll()
        self.activeRowIndex = nil
        self.activeMaskShape.path = nil

        let attributedTexts: [(NSAttributedString, Double?)]
        switch state {
            case .timed(let lines):
                attributedTexts = lines.map { (self.attributedLine($0.text), $0.timestamp) }
            case .plain(let texts):
                attributedTexts = texts.map { (self.attributedLine($0), nil) }
            default:
                return
        }
        guard !attributedTexts.isEmpty else {
            return
        }

        let boundingWidth = max(width, 1.0)
        var cursor: CGFloat = AudioLyricsView.verticalRevealInset
        for (text, timestamp) in attributedTexts {
            let measuredHeight = ceil(text.boundingRect(
                with: CGSize(width: boundingWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                context: nil
            ).height)
            let rowHeight = max(measuredHeight, 21.0)

            let baseLabel = UILabel()
            baseLabel.numberOfLines = 0
            baseLabel.attributedText = text
            baseLabel.textColor = self.inactiveTextColor
            baseLabel.frame = CGRect(x: AudioLyricsView.sideInset, y: cursor, width: boundingWidth, height: rowHeight)
            self.linesContainer.addSubview(baseLabel)

            let highlightLabel = UILabel()
            highlightLabel.numberOfLines = 0
            highlightLabel.attributedText = text
            highlightLabel.textColor = self.primaryColor
            highlightLabel.frame = baseLabel.frame
            highlightLabel.isHidden = true
            highlightLabel.isUserInteractionEnabled = false
            self.linesContainer.addSubview(highlightLabel)

            self.rows.append(Row(baseLabel: baseLabel, highlightLabel: highlightLabel, top: cursor, height: rowHeight, timestamp: timestamp))
            cursor += rowHeight + AudioLyricsView.rowSpacing
        }

        let contentHeight = cursor - AudioLyricsView.rowSpacing + AudioLyricsView.verticalRevealInset
        self.scrollView.contentSize = CGSize(width: self.bounds.width, height: contentHeight)
        self.scrollView.contentOffset = CGPoint()
    }

    private func clearRowsAndActivatePlaceholder(_ state: LyricsPresentationState) {
        for subview in self.linesContainer.subviews {
            subview.removeFromSuperview()
        }
        self.rows.removeAll()
        self.activeRowIndex = nil
        self.scrollView.contentSize = self.bounds.size

        switch state {
            case .loading:
                self.statusLabel.isHidden = true
                self.statusIndicator.startAnimating()
            case .instrumental(let marker), .message(let marker):
                self.statusIndicator.stopAnimating()
                self.statusLabel.text = marker
                self.statusLabel.isHidden = false
            default:
                break
        }
        self.layoutStatusContainer(size: self.bounds.size)
    }

    private func layoutStatusContainer(size: CGSize) {
        self.statusIndicator.frame = CGRect(origin: CGPoint(x: floor((size.width - 24.0) / 2.0), y: floor(size.height / 2.0) - 12.0), size: CGSize(width: 24.0, height: 24.0))
        let availableWidth = size.width - AudioLyricsView.sideInset * 4.0
        let fittedSize = self.statusLabel.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
        self.statusLabel.frame = CGRect(
            x: floor((size.width - fittedSize.width) / 2.0),
            y: floor((size.height - fittedSize.height) / 2.0),
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    private func startDisplayLink() {
        if self.displayLink == nil {
            self.displayLink = SharedDisplayLinkDriver.shared.add(framesPerSecond: .fps(60)) { [weak self] _ in
                self?.refreshActiveLine()
            }
        }
        self.displayLink?.isPaused = false
    }

    private func stopDisplayLink() {
        self.displayLink?.isPaused = true
        self.deactivateCurrentRow()
    }

    private func deactivateCurrentRow() {
        guard let rowIndex = self.activeRowIndex, rowIndex < self.rows.count else {
            return
        }
        let row = self.rows[rowIndex]
        row.highlightLabel.isHidden = true
        row.highlightLabel.layer.mask = nil
        self.activeRowIndex = nil
        self.activeMaskShape.path = nil
    }

    private func refreshActiveLine() {
        guard case .timed = self.presentationState, !self.rows.isEmpty else {
            return
        }
        guard let snapshot = self.playbackSnapshot, let position = snapshot.playbackPosition else {
            return
        }

        var foundIndex: Int?
        for (index, row) in self.rows.enumerated() where row.timestamp != nil && row.timestamp! <= position {
            foundIndex = index
        }
        guard let newActiveIndex = foundIndex, newActiveIndex < self.rows.count, self.rows[newActiveIndex].timestamp != nil else {
            self.deactivateCurrentRow()
            self.activeStart = 0.0
            self.activeEnd = .infinity
            return
        }

        if newActiveIndex != self.activeRowIndex {
            self.activate(rowAt: newActiveIndex, resetScroll: !self.isUserScrolling)
        }
        self.updateActiveMask(position: position)
    }

    private func activate(rowAt index: Int, resetScroll: Bool) {
        self.deactivateCurrentRow()
        self.activeRowIndex = index
        let row = self.rows[index]

        row.highlightLabel.layer.mask = self.activeMaskShape
        self.activeMaskShape.frame = row.highlightLabel.bounds
        row.highlightLabel.isHidden = false

        let rowTimestamp = row.timestamp ?? 0.0
        self.activeStart = rowTimestamp
        if index + 1 < self.rows.count, let nextTimestamp = self.rows[index + 1].timestamp, nextTimestamp > rowTimestamp {
            self.activeEnd = nextTimestamp
        } else {
            self.activeEnd = rowTimestamp + 8.0
        }

        if resetScroll && !self.isUserScrolling {
            let targetOffset = row.top - max((self.scrollView.bounds.height - row.height) / 2.0, 0.0)
            let clampedTarget = max(0.0, min(targetOffset, max(self.scrollView.contentSize.height - self.scrollView.bounds.height, 0.0)))
            self.scrollView.setContentOffset(CGPoint(x: 0.0, y: clampedTarget), animated: true)
        }
    }

    private func updateActiveMask(position: Double) {
        guard let rowIndex = self.activeRowIndex, rowIndex < self.rows.count, self.activeEnd > self.activeStart else {
            return
        }
        let row = self.rows[rowIndex]
        let fraction = max(0.0, min(1.0, (position - self.activeStart) / (self.activeEnd - self.activeStart)))
        self.activeMaskShape.frame = row.highlightLabel.bounds
        self.activeMaskShape.path = CGPath(
            roundedRect: CGRect(origin: CGPoint(), size: CGSize(width: row.highlightLabel.bounds.width * fraction, height: row.highlightLabel.bounds.height)),
            cornerWidth: 0.0,
            cornerHeight: 0.0,
            transform: nil
        )
    }

    // MARK: UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isUserScrolling = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.isUserScrolling = false
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isUserScrolling = false
    }
}
