import SwiftUI

public struct BlankView: View {
    let width: CGFloat
    let height: CGFloat
    
    public init(width: CGFloat = 0, height: CGFloat = 0) {
        self.width = width
        self.height = height
    }
    
    public var body: some View {
        Color
            .clear
            .frame(width: width, height: height)
    }
}

#Preview {
    BlankView()
}
