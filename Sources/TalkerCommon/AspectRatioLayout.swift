import Combine
import SwiftUI

struct AspectRatioLayout: Layout {
    var aspectRatio: CGFloat
    var isWidthBased: Bool

    init(aspectRatio: CGFloat, isWidthBased: Bool = true) {
        self.aspectRatio = aspectRatio
        self.isWidthBased = isWidthBased
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        guard let subview = subviews.first else {
            return .zero
        }

        if isWidthBased {
            let proposedWidth = proposal.width ?? subview.sizeThatFits(proposal).width
            let height = proposedWidth / aspectRatio
            return CGSize(width: proposedWidth, height: height)
        } else {
            let proposedHeight = proposal.height ?? subview.sizeThatFits(proposal).height
            let width = proposedHeight * aspectRatio
            return CGSize(width: width, height: proposedHeight)
        }
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void
    ) {
        guard let subview = subviews.first else { return }

        let size: CGSize
        if isWidthBased {
            let width = bounds.width
            let height = width / aspectRatio
            size = CGSize(width: width, height: height)
        } else {
            let height = bounds.height
            let width = height * aspectRatio
            size = CGSize(width: width, height: height)
        }

        let x = bounds.minX + (bounds.width - size.width) / 2
        let y = bounds.minY + (bounds.height - size.height) / 2

        subview.place(
            at: CGPoint(x: x, y: y),
            proposal: ProposedViewSize(size)
        )
    }
}

extension View {
    public func aspectRatioLayout(_ aspectRatio: CGFloat, isWidthBased: Bool = true) -> some View {
        AspectRatioLayout(aspectRatio: aspectRatio, isWidthBased: isWidthBased) {
            self
        }
    }
}
