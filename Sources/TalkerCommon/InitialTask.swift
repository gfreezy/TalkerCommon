//
//  InitialTask.swift
//  iOS
//
//  Created by feichao on 2023/4/1.
//

import SwiftUI


fileprivate struct InitialTask<Content: View, T: Equatable>: View {
    @State var inited: Bool = false
    let content: Content
    let value: T?
    let priority: TaskPriority
    let action: () async throws -> Void

    var body: some View {
        if let value {
            content.task(id: value, priority: priority) {
                if !inited {
                    inited = true
                    do {
                        try await action()
                    } catch (let error) {
                        errorLog(error)
                    }
                }
            }
        } else {
            content.task(priority: priority) {
                if !inited {
                    inited = true
                    do {
                        try await action()
                    } catch (let error) {
                        errorLog(error)
                    }
                }
            }
        }
    }
}

fileprivate struct InitialTaskModifier<T: Equatable>: ViewModifier {
    let value: T?
    let priority: TaskPriority
    let action: () async throws -> Void

    func body(content: Content) -> some View {
        InitialTask(content: content, value: value, priority: priority, action: action)
    }
}

extension View {
    public func initialTask(
        priority: TaskPriority = .userInitiated, action: @MainActor @escaping () async throws -> Void
    ) -> some View {
        return self.modifier(
            InitialTaskModifier<Int>(value: nil, priority: priority, action: action))
    }

    public func initialTask<T: Equatable>(
        id: T, priority: TaskPriority = .userInitiated, action: @MainActor  @escaping () async -> Void
    ) -> some View {
        return self.modifier(InitialTaskModifier(value: id, priority: priority, action: action))
    }
}
