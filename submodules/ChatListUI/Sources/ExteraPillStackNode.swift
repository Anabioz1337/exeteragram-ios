import Foundation
import UIKit
import AsyncDisplayKit
import SwiftSignalKit
import Display
import TelegramPresentationData

private let pillHeight: CGFloat = 30.0
private let pillSpacing: CGFloat = 6.0
private let pillHorizontalPadding: CGFloat = 14.0
private let pillRowPadding: CGFloat = 12.0
private let reorderHoldInterval: TimeInterval = 0.35

public struct ExteraPill {
    public let kind: String
    public let title: String

    public init(kind: String, title: String) {
        self.kind = kind
        self.title = title
    }
}

public protocol ExteraPillStackNodeInteraction: AnyObject {
    /// A pill was tapped; `selected` tells whether it was already applied and a second tap clears the filter.
    func exteraPillStackTappedPill(kind: String, selected: Bool)
    /// A hold-and-drag finished; the kinds come in their new display order.
    func exteraPillStackReorderedPills(kinds: [String])
}

/// The horizontally scrolling capsule row above the chat search results. A tap applies the
/// pill's filter, a hold-and-drag reorders it (persisted through the interaction), and with
/// infinite scrolling enabled the pills are laid out twice with the content offset wrapping,
/// so the strip never runs out.
public final class ExteraPillStackNode: ASDisplayNode, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private var theme: PresentationTheme
    private var pills: [ExteraPill] = []
    private var selectedKind: String?
    private var pillViewsByRun: [[String: UIView]] = []
    private var kindByView: [UIView: String] = [:]
    private var infiniteScrolling = false

    public weak var interaction: ExteraPillStackNodeInteraction?

    private var reorderActive = false
    private var draggingView: UIView?
    private var draggingKind: String?

    public init(theme: PresentationTheme) {
        self.theme = theme
        super.init()
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.backgroundColor = .clear
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.delegate = self
        self.view.addSubview(self.scrollView)

        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleHold(_:)))
        recognizer.minimumPressDuration = reorderHoldInterval
        recognizer.delegate = self
        self.scrollView.addGestureRecognizer(recognizer)
    }

    public func updateTheme(_ theme: PresentationTheme) {
        self.theme = theme
        for run in self.pillViewsByRun {
            for (kind, view) in run {
                self.applyAppearance(to: view, selected: self.selectedKind == kind)
            }
        }
    }

    public func update(pills: [ExteraPill], selectedKind: String?, transition: ContainedViewLayoutTransition) {
        self.selectedKind = selectedKind
        self.pills = pills

        while self.pillViewsByRun.count > self.pillViewRunCount() {
            if let run = self.pillViewsByRun.popLast() {
                for (_, view) in run {
                    view.removeFromSuperview()
                    self.kindByView.removeValue(forKey: view)
                }
            }
        }
        while self.pillViewsByRun.count < self.pillViewRunCount() {
            self.pillViewsByRun.append([:])
        }
        let validKinds = Set(pills.map({ $0.kind }))
        for runViews in self.pillViewsByRun {
            for (kind, view) in runViews where !validKinds.contains(kind) {
                view.removeFromSuperview()
                self.kindByView.removeValue(forKey: view)
                runViews.removeValue(forKey: kind)
            }
        }
        for runViews in self.pillViewsByRun {
            for pill in pills {
                if let view = runViews[pill.kind] {
                    if let label = view.subviews.compactMap({ $0 as? UILabel }).first, label.text != pill.title {
                        label.text = pill.title
                    }
                } else {
                    let view = self.makePillView(pill)
                    runViews[pill.kind] = view
                    self.kindByView[view] = pill.kind
                    self.scrollView.addSubview(view)
                }
                self.applyAppearance(to: runViews[pill.kind]!, selected: self.selectedKind == pill.kind)
            }
        }
        self.layoutPills()
    }

    /// Infinite scrolling lays the pills out twice so the offset can wrap seamlessly.
    private func pillViewRunCount() -> Int {
        return self.infiniteScrolling && !self.pills.isEmpty ? 2 : 1
    }

    public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        self.scrollView.frame = CGRect(origin: CGPoint(), size: size)
        self.layoutPills()
    }

    private func makePillView(_ pill: ExteraPill) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = true

        let label = UILabel()
        label.font = Font.regular(14.0)
        label.text = pill.title
        label.isUserInteractionEnabled = false
        view.addSubview(label)

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }

    private func applyAppearance(to view: UIView, selected: Bool) {
        view.backgroundColor = selected ? self.theme.rootController.navigationBar.controlBackgroundColor : self.theme.rootController.navigationSearchBar.inputFillColor
        view.layer.cornerRadius = pillHeight / 2.0
        view.layer.masksToBounds = true
        if let label = view.subviews.compactMap({ $0 as? UILabel }).first {
            label.textColor = self.theme.rootController.navigationBar.primaryTextColor
        }
    }

    private func titleWidth(_ title: String) -> CGFloat {
        return ceil((title as NSString).size(withAttributes: [.font: Font.regular(14.0)]).width) + 2.0 * pillHorizontalPadding
    }

    /// One run's width: the pills plus the trailing padding, so content laid out twice wraps seamlessly.
    private func runWidth() -> CGFloat {
        var width = pillRowPadding
        for pill in self.pills {
            width += self.titleWidth(pill.title) + pillSpacing
        }
        return width
    }

    private func layoutPills() {
        let runWidth = max(self.runWidth(), self.scrollView.bounds.width)
        for (run, runViews) in self.pillViewsByRun.enumerated() {
            var offsetX = pillRowPadding + CGFloat(run) * runWidth
            for pill in self.pills {
                guard let view = runViews[pill.kind] else {
                    continue
                }
                let width = self.titleWidth(pill.title)
                view.frame = CGRect(x: offsetX, y: (self.scrollView.bounds.height - pillHeight) / 2.0, width: width, height: pillHeight)
                if let label = view.subviews.compactMap({ $0 as? UILabel }).first {
                    label.frame = view.bounds
                }
                offsetX += width + pillSpacing
            }
        }
        let contentWidth = CGFloat(max(1, self.pillViewsByRun.count)) * runWidth
        if self.scrollView.contentSize.width != contentWidth {
            self.scrollView.contentSize = CGSize(width: contentWidth, height: self.scrollView.bounds.height)
        }
    }

    // MARK: Infinite scrolling

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self.pillViewsByRun.count > 1, !self.pills.isEmpty, !self.reorderActive else {
            return
        }
        let runWidth = self.runWidth()
        guard runWidth > self.scrollView.bounds.width + 1.0 else {
            return
        }
        var offset = scrollView.contentOffset.x
        let wrapWindow = runWidth * 2.0 - scrollView.bounds.width
        if offset < 0.0 {
            offset += runWidth
        } else if offset > wrapWindow {
            offset -= runWidth
        } else {
            return
        }
        scrollView.contentOffset = CGPoint(x: max(offset, 0.0), y: 0.0)
    }

    // MARK: Tap

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended, !self.reorderActive else {
            return
        }
        guard let view = recognizer.view, let kind = self.kindByView[view] else {
            return
        }
        self.interaction?.exteraPillStackTappedPill(kind: kind, selected: self.selectedKind == kind)
    }

    // MARK: Drag reorder

    @objc private func handleHold(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            guard let view = self.pillView(at: recognizer.location(in: self.scrollView)) else {
                return
            }
            self.reorderActive = true
            self.draggingView = view
            self.draggingKind = self.kindByView[view]
            self.scrollView.isScrollEnabled = false
            view.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
            view.layer.zPosition = 1000.0
        case .changed:
            self.updateReorder(at: recognizer.location(in: self.scrollView).x)
        case .ended, .cancelled:
            self.endReorder()
        default:
            break
        }
    }

    private func pillView(at location: CGPoint) -> UIView? {
        for run in self.pillViewsByRun {
            for pill in self.pills {
                guard let view = run[pill.kind] else {
                    continue
                }
                if view.bounds.contains(view.convert(location, from: self.scrollView)) {
                    return view
                }
            }
        }
        return nil
    }

    private func updateReorder(at location: CGFloat) {
        guard let view = self.draggingView else {
            return
        }
        view.frame = view.frame.offsetBy(dx: location - view.frame.midX, dy: 0.0)

        // The insertion index: how many neighbors' centers sit to the left of the dragged pill.
        guard let fromIndex = self.pills.firstIndex(where: { $0.kind == self.draggingKind }) else {
            return
        }
        var passedCount = 0
        var offsetX = pillRowPadding
        for (index, pill) in self.pills.enumerated() {
            let width = self.titleWidth(pill.title)
            let center = offsetX + width / 2.0
            if index != fromIndex && location > center {
                passedCount += 1
            }
            offsetX += width + pillSpacing
        }
        let toIndex = max(0, min(passedCount, self.pills.count - 1))
        guard toIndex != fromIndex else {
            return
        }
        var reordered = self.pills
        let moved = reordered.remove(at: fromIndex)
        reordered.insert(moved, at: toIndex)
        self.pills = reordered
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction], animations: {
            self.layoutPills()
        })
    }

    private func endReorder() {
        guard let view = self.draggingView, let kind = self.draggingKind else {
            self.reorderActive = false
            return
        }
        view.transform = CGAffineTransform()
        self.reorderActive = false
        self.scrollView.isScrollEnabled = true
        self.draggingView = nil
        self.draggingKind = nil
        self.layoutPills()
        if self.pills.contains(where: { $0.kind == kind }) {
            self.interaction?.exteraPillStackReorderedPills(kinds: self.pills.map({ $0.kind }))
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
