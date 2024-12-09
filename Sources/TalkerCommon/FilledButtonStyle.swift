//
//  File.swift
//  
//
//  Created by feichao on 2024/5/25.
//
import SwiftUI


public struct FilledButtonStyle<T: ShapeStyle>: ButtonStyle {
    let foregroundColor: Color
    let padding: EdgeInsets
    let cornerRadius: CGFloat
    let background: T
    let strokeColor: Color?
    let maxWidth: CGFloat?
    @Environment(\.isEnabled) var isEnabled
    
    public init(foregroundColor: Color = Color.white, background: T = Color.accentColor, padding: EdgeInsets = EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40), cornerRadius: CGFloat = 15, strokeColor: Color? = nil, maxWidth: CGFloat? = .infinity) {
        self.foregroundColor = foregroundColor
        self.background = background
        self.cornerRadius = cornerRadius
        self.strokeColor = strokeColor
        self.padding = padding
        self.maxWidth = maxWidth
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.medium)
            .foregroundColor(foregroundColor)
            .padding(padding)
            .frame(maxWidth: maxWidth)
            .background(background.opacity(isEnabled ? 1 : 0.25))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor ?? .white, lineWidth: strokeColor != nil ? 1: 0)
            )
    }
}
