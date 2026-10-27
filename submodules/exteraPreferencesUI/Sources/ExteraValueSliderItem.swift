import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import LegacyComponents

final class ExteraValueSliderItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let title: String
    let leftText: String?
    let rightText: String?
    let value: Int32
    let maximumValue: Int32
    let sectionId: ItemListSectionId
    let updated: (Int32) -> Void
    let tag: ItemListItemTag?

    init(presentationData: ItemListPresentationData, title: String, leftText: String? = nil, rightText: String? = nil, value: Int32, maximumValue: Int32, sectionId: ItemListSectionId, updated: @escaping (Int32) -> Void, tag: ItemListItemTag? = nil) {
        self.presentationData = presentationData
        self.title = title
        self.leftText = leftText
        self.rightText = rightText
        self.value = value
        self.maximumValue = maximumValue
        self.sectionId = sectionId
        self.updated = updated
        self.tag = tag
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, neighbors: ListViewItemNeighbors, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = ExteraValueSliderItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topFacet: neighbors.previous?.base(ItemListNeighborFacet.self), bottomFacet: neighbors.next?.base(ItemListNeighborFacet.self)))

            node.contentSize = layout.contentSize
            node.insets = layout.insets

            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, neighbors: ListViewItemNeighbors, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? ExteraValueSliderItemNode {
                let makeLayout = nodeValue.asyncLayout()

                async {
                    let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topFacet: neighbors.previous?.base(ItemListNeighborFacet.self), bottomFacet: neighbors.next?.base(ItemListNeighborFacet.self)))
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply()
                        })
                    }
                }
            }
        }
    }
}

final class ExteraValueSliderItemNode: ListViewItemNode, ItemListItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    private let titleNode: TextNode
    private let leftTextNode: TextNode
    private let rightTextNode: TextNode

    private var sliderView: TGPhotoEditorSliderView?

    private var item: ExteraValueSliderItem?
    private var layoutParams: ListViewItemLayoutParams?

    var tag: ItemListItemTag? {
        return self.item?.tag
    }

    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true

        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true

        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true

        self.maskNode = ASImageNode()

        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false
        self.titleNode.displaysAsynchronously = true

        self.leftTextNode = TextNode()
        self.leftTextNode.isUserInteractionEnabled = false
        self.leftTextNode.displaysAsynchronously = true

        self.rightTextNode = TextNode()
        self.rightTextNode.isUserInteractionEnabled = false
        self.rightTextNode.displaysAsynchronously = true

        super.init(layerBacked: false)

        self.addSubnode(self.titleNode)
        self.addSubnode(self.leftTextNode)
        self.addSubnode(self.rightTextNode)
    }

    override func didLoad() {
        super.didLoad()

        let sliderView = TGPhotoEditorSliderView()
        sliderView.enablePanHandling = true
        sliderView.trackCornerRadius = 2.0
        sliderView.lineSize = 4.0
        sliderView.dotSize = 8.0
        sliderView.minimumValue = 0.0
        sliderView.disablesInteractiveTransitionGestureRecognizer = true

        if let item = self.item, let params = self.layoutParams {
            sliderView.maximumValue = CGFloat(item.maximumValue)
            sliderView.value = CGFloat(item.value)
            sliderView.backColor = item.presentationData.theme.list.itemSwitchColors.frameColor
            sliderView.trackColor = item.presentationData.theme.list.itemAccentColor
            sliderView.knobImage = PresentationResourcesItemList.knobImage(item.presentationData.theme)
            sliderView.frame = CGRect(origin: CGPoint(x: params.leftInset + 16.0, y: 38.0), size: CGSize(width: params.width - params.leftInset - params.rightInset - 32.0, height: 32.0))
        }

        self.view.insertSubview(sliderView, at: 0)
        sliderView.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        self.sliderView = sliderView
    }

    @objc private func sliderValueChanged() {
        guard let sliderView = self.sliderView, let item = self.item else {
            return
        }
        item.updated(Int32(sliderView.value.rounded()))
    }

    func asyncLayout() -> (_ item: ExteraValueSliderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let currentItem = self.item

        return { [weak self] item, params, neighbors in
            let baseFontSize = item.presentationData.fontSize.itemListBaseFontSize
            let theme = item.presentationData.theme

            var themeUpdated = false
            if currentItem?.presentationData.theme !== item.presentationData.theme {
                themeUpdated = true
            }

            let textWidth = params.width - params.leftInset - params.rightInset - 32.0

            let titleLayout = TextNode.asyncLayout(self?.titleNode)
            let (titleSize, titleApply) = titleLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.title, font: Font.regular(baseFontSize), textColor: theme.list.itemPrimaryTextColor), maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: textWidth, height: 100.0), verticalAlignment: .middle))

            let leftTextLayout = TextNode.asyncLayout(self?.leftTextNode)
            let (leftTextSize, leftTextApply) = leftTextLayout(TextNodeLayoutArguments(attributedString: item.leftText.flatMap { NSAttributedString(string: $0, font: Font.regular(floor(baseFontSize * 0.8)), textColor: theme.list.itemSecondaryTextColor) }, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: textWidth / 2.0, height: 100.0), verticalAlignment: .middle))

            let rightTextLayout = TextNode.asyncLayout(self?.rightTextNode)
            let (rightTextSize, rightTextApply) = rightTextLayout(TextNodeLayoutArguments(attributedString: item.rightText.flatMap { NSAttributedString(string: $0, font: Font.regular(floor(baseFontSize * 0.8)), textColor: theme.list.itemSecondaryTextColor, alignment: .right) }, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: textWidth / 2.0, height: 100.0), verticalAlignment: .middle))

            let contentSize = CGSize(width: params.width, height: 80.0)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            let separatorHeight = UIScreenPixel

            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size

            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    strongSelf.layoutParams = params

                    strongSelf.backgroundNode.backgroundColor = theme.list.itemBlocksBackgroundColor
                    strongSelf.topStripeNode.backgroundColor = theme.list.itemBlocksSeparatorColor
                    strongSelf.bottomStripeNode.backgroundColor = theme.list.itemBlocksSeparatorColor

                    if strongSelf.backgroundNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                    }
                    if strongSelf.topStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.topStripeNode, at: 1)
                    }
                    if strongSelf.bottomStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 2)
                    }
                    if strongSelf.maskNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.maskNode, at: 3)
                    }

                    let hasCorners = itemListHasRoundedBlockLayout(params)
                    var hasTopCorners = false
                    var hasBottomCorners = false
                    switch neighbors.top {
                    case .sameSection(false):
                        strongSelf.topStripeNode.isHidden = true
                    default:
                        hasTopCorners = true
                        strongSelf.topStripeNode.isHidden = hasCorners
                    }
                    let bottomStripeInset: CGFloat
                    let bottomStripeOffset: CGFloat
                    switch neighbors.bottom {
                        case .sameSection(false):
                            bottomStripeInset = params.leftInset + 16.0
                            bottomStripeOffset = -separatorHeight
                            strongSelf.bottomStripeNode.isHidden = false
                        default:
                            bottomStripeInset = 0.0
                            bottomStripeOffset = 0.0
                            hasBottomCorners = true
                            strongSelf.bottomStripeNode.isHidden = hasCorners
                    }

                    strongSelf.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(theme, top: hasTopCorners, bottom: hasBottomCorners) : nil

                    strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                    strongSelf.maskNode.frame = strongSelf.backgroundNode.frame.inset(by: UIEdgeInsets(top: 0.0, left: params.leftInset, bottom: 0.0, right: params.rightInset))
                    strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                    strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - bottomStripeInset, height: separatorHeight))

                    let _ = titleApply()
                    strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: params.leftInset + 16.0, y: 14.0), size: titleSize)

                    let _ = leftTextApply()
                    strongSelf.leftTextNode.frame = CGRect(origin: CGPoint(x: params.leftInset + 16.0, y: contentSize.height - 12.0 - leftTextSize.height), size: leftTextSize)

                    let _ = rightTextApply()
                    strongSelf.rightTextNode.frame = CGRect(origin: CGPoint(x: params.width - params.rightInset - 16.0 - rightTextSize.width, y: contentSize.height - 12.0 - rightTextSize.height), size: rightTextSize)

                    if let sliderView = strongSelf.sliderView {
                        sliderView.maximumValue = CGFloat(item.maximumValue)
                        if sliderView.value != CGFloat(item.value) {
                            sliderView.value = CGFloat(item.value)
                        }
                        if themeUpdated {
                            sliderView.backColor = theme.list.itemSwitchColors.frameColor
                            sliderView.trackColor = theme.list.itemAccentColor
                            sliderView.knobImage = PresentationResourcesItemList.knobImage(theme)
                        }
                        sliderView.frame = CGRect(origin: CGPoint(x: params.leftInset + 16.0, y: 38.0), size: CGSize(width: textWidth, height: 32.0))
                    }
                }
            })
        }
    }
}
