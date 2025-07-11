import Combine
import SwiftUI

public struct AspectRatioLayout: Layout {
    var aspectRatio: CGFloat
    var isWidthBased: Bool

    public init(aspectRatio: CGFloat, isWidthBased: Bool = true) {
        self.aspectRatio = aspectRatio
        self.isWidthBased = isWidthBased
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize
    {
        guard let subview = subviews.first else {
            return .zero
        }

        let expectedSize: CGSize
        if isWidthBased {
            let proposedWidth: CGFloat
            if let w = proposal.width, w != .infinity {
                proposedWidth = w
            } else {
                let size = subview.sizeThatFits(proposal)
                proposedWidth = size.width
            }
            expectedSize = CGSize(width: proposedWidth, height: proposedWidth / aspectRatio)
        } else {
            let proposedHeight: CGFloat
            if let h = proposal.height, h != .infinity {
                proposedHeight = h
            } else {
                let size = subview.sizeThatFits(proposal)
                proposedHeight = size.height
            }
            expectedSize = CGSize(width: proposedHeight * aspectRatio, height: proposedHeight)
        }
        return expectedSize
    }

    public func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache
    ) {
        guard let subview = subviews.first else { return }

        let expectedSize = sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        let subviewProposal = ProposedViewSize(width: expectedSize.width, height: expectedSize.height)
        let subviewSize = subview.sizeThatFits(subviewProposal)

        // Center the subview
        let x = bounds.minX + (bounds.width - subviewSize.width) / 2
        let y = bounds.minY + (bounds.height - subviewSize.height) / 2

        subview.place(
            at: CGPoint(x: x, y: y),
            proposal: subviewProposal
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


#Preview {
    Rectangle()
        .fill(.red)
        .aspectRatioLayout(3 / 4)
        .border(.blue)
        .padding(10)
}

#Preview {
    AsyncImage(url: URL(string: "https://picsum.photos/100/300")!) { phase in
        if let img = phase.image {
            VStack {
                img
                    .resizable()
                    .scaledToFill()
                    .aspectRatioLayout(3 / 4)
                    .frame(width: 200, height: 200)
                    .clipped()
                    .padding(10)

                img
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
    }
    .padding()
}
