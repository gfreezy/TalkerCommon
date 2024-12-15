//
//  ReadHeightExtension.swift
//  iOS
//
//  Created by feichao on 2024/3/29.
//

import SwiftUI

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? {
        nil
    }

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

struct SizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct ReadHeightModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
    }

    func body(content: Content) -> some View {
        content.overlay(sizeView)
    }
}

private struct ReadSizeModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
        }
    }

    func body(content: Content) -> some View {
        content.overlay(sizeView)
    }
}

private struct PresentationAutoHeightModifier: ViewModifier {
    @State var height: CGFloat = 0
    let dragIndicatorVisibility: Visibility
    let track: Bool
    let maxHeight: CGFloat

    init(track: Bool, maxHeight: CGFloat, dragIndicatorVisibility: Visibility) {
        self.dragIndicatorVisibility = dragIndicatorVisibility
        self.track = track
        self.maxHeight = maxHeight
    }

    func body(content: Content) -> some View {
        if track {
            content
                .trackAndReadHeight { h in
                    height = h
                }
                .presentationDetents([.height(min(height, maxHeight))])
                .presentationDragIndicator(dragIndicatorVisibility)
        } else {
            content
                .readHeight { h in
                    height = h
                }
                .presentationDetents([.height(min(height, maxHeight))])
                .presentationDragIndicator(dragIndicatorVisibility)
        }
    }
}

extension View {
    public func trackHeight() -> some View {
        self
            .modifier(ReadHeightModifier())
    }

    public func readHeight(callback: @MainActor @escaping (CGFloat) -> Void) -> some View {
        self
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                if let height {
                    Task { @MainActor in
                        callback(height)
                    }
                }
            }
    }

    public func trackAndReadHeight(callback: @MainActor @escaping (CGFloat) -> Void) -> some View {
        self
            .modifier(ReadHeightModifier())
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                if let height {
                    Task { @MainActor in
                        callback(height)
                    }
                }
            }
    }

    public func trackSize() -> some View {
        self
            .modifier(ReadSizeModifier())
    }

    public func readSize(callback: @MainActor @escaping (CGSize) -> Void) -> some View {
        self
            .onPreferenceChange(SizePreferenceKey.self) { size in
                Task { @MainActor in
                    callback(size)
                }
            }
    }

    public func trackAndReadSize(callback: @MainActor @escaping (CGSize) -> Void) -> some View {
        self
            .modifier(ReadSizeModifier())
            .onPreferenceChange(SizePreferenceKey.self) { size in
                Task { @MainActor in
                    callback(size)
                }
            }
    }

    public func presentationAutoHeight(
        maxHeight: CGFloat = .infinity, dragIndicator: Visibility = .automatic
    ) -> some View {
        self
            .modifier(
                PresentationAutoHeightModifier(
                    track: true, maxHeight: maxHeight, dragIndicatorVisibility: dragIndicator))
    }

    public func presentationAutoHeightOfDecendents(
        maxHeight: CGFloat = .infinity, dragIndicator: Visibility = .automatic
    ) -> some View {
        self
            .modifier(
                PresentationAutoHeightModifier(
                    track: false, maxHeight: maxHeight, dragIndicatorVisibility: dragIndicator))
    }
}
