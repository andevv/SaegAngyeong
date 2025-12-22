//
//  FeedMasonryLayout.swift
//  SaegAngyeong
//
//  Created by andev on 12/22/25.
//

import UIKit

protocol FeedMasonryLayoutDelegate: AnyObject {
    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat
}

final class FeedMasonryLayout: UICollectionViewLayout {
    weak var delegate: FeedMasonryLayoutDelegate?
    var numberOfColumns: Int = 2
    var cellPadding: CGFloat = 8
    var verticalPadding: CGFloat = 0

    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {
        collectionView?.bounds.width ?? 0
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    override func prepare() {
        guard cache.isEmpty, let collectionView else { return }

        let columnWidth = (contentWidth - (CGFloat(numberOfColumns + 1) * cellPadding)) / CGFloat(numberOfColumns)
        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(cellPadding + CGFloat(column) * (columnWidth + cellPadding))
        }
        var yOffset = Array(repeating: verticalPadding, count: numberOfColumns)
        var column = 0

        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            let height = delegate?.collectionView(collectionView, heightForItemAt: indexPath, with: columnWidth) ?? 180
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            cache.append(attributes)

            contentHeight = max(contentHeight, frame.maxY + verticalPadding)
            yOffset[column] = yOffset[column] + height + verticalPadding
            column = yOffset[0] < yOffset[1] ? 0 : 1
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cache.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        cache.first { $0.indexPath == indexPath }
    }

    override func invalidateLayout() {
        super.invalidateLayout()
        cache.removeAll()
        contentHeight = 0
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }
}
