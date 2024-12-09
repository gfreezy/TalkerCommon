//
//  SwiftUIView.swift
//
//
//  Created by feichao on 2024/6/13.
//

import SwiftUI

extension View {
    public func taskThrows(
        _ taskF: @escaping () async throws -> Void
    ) -> some View {
        return task {
            do {
                try await taskF()
            } catch {
                errorLog("taskThrows error: \(error)")
            }
        }
    }

    public func onAppearOnce(perform action: @escaping () -> Void) -> some View {
        modifier(OnAppearOnceModifier(action: action))
    }
}

private struct OnAppearOnceModifier: ViewModifier {
    @State private var hasAppeared = false
    let action: () -> Void

    func body(content: Content) -> some View {
        content.onAppear {
            if !hasAppeared {
                hasAppeared = true
                action()
            }
        }
    }
}
