//
//  InlinePicker.swift
//  TalkerCommon
//
//  Created by feichao on 2024/8/31.
//
import SwiftUI
import ViewExtractor

public struct InlinePickerStyleConfiguration {
    public let isSelected: Bool
    public let label: AnyView
}

public struct ResolvedInlinePickerStyle<Style: InlinePickerStyle>: View {
    var configuration: Style.Configuration
    var style: Style

    public var body: Style.Body {
        style.makeBody(configuration: configuration)
    }
}

extension InlinePickerStyle {
    func resolve(configuration: Configuration) -> some View {
        ResolvedInlinePickerStyle(configuration: configuration, style: self)
    }
}

@MainActor
public protocol InlinePickerStyle: DynamicProperty {
    associatedtype Body: View

    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body

    typealias Configuration = InlinePickerStyleConfiguration
}

struct InlinePickerStyleKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: any InlinePickerStyle = DefaultInlinePickerStyle()
}

extension EnvironmentValues {
    var inliePickerStyle: any InlinePickerStyle {
        get { self[InlinePickerStyleKey.self] }
        set { self[InlinePickerStyleKey.self] = newValue }
    }
}

extension View {
    public func inlinePickerStyle(_ style: some InlinePickerStyle) -> some View {
        environment(\.inliePickerStyle, style)
    }
}

public struct DefaultInlinePickerStyle: InlinePickerStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundStyle(configuration.isSelected ? .white : .primary)
            .background(configuration.isSelected ? Color.accentColor : Color.clear)
    }
}

extension InlinePickerStyle where Self == DefaultInlinePickerStyle {
    static var `automic`: DefaultInlinePickerStyle {
        DefaultInlinePickerStyle()
    }
}

public struct InlinePicker<Content: View, Selection: Hashable & Equatable>: View {
    let content: Content
    @Binding var selection: Selection
    @Environment(\.inliePickerStyle) var style

    public init(selection: Binding<Selection>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self._selection = selection
    }

    public var body: some View {
        HStack {
            ExtractMulti(content) { views in
                ForEach(views) { view in
                    let tag = view.id(as: Selection.self)
                    let configuration = InlinePickerStyleConfiguration(
                        isSelected: tag == selection, label: AnyView(view))

                    Button {
                        if let tag {
                            selection = tag
                        }
                    } label: {
                        AnyView(style.makeBody(configuration: configuration))
                    }
                    .contentShape(Rectangle())
                }
            }
        }
    }
}

private struct Preview: View {
    @State var selection = Color.clear

    var body: some View {
        VStack {
            Text(verbatim: "Selected: \(selection)")
                .foregroundStyle(selection)
            InlinePicker(selection: $selection) {
                Color.red
                    .containerShape(Capsule())
                    .id(Color.red)
                Color.blue
                    .containerShape(Capsule())
                    .id(Color.blue)
                Color.green
                    .containerShape(Capsule())
                    .id(Color.green)
            }
            .inlinePickerStyle(.automic)

            Text(Color.white == Color(hex: "#ffffff") ? "true2" : "false2")
        }
    }
}

#Preview {
    Preview()
}
