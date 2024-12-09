//
//  LoadingView.swift
//  iOS
//
//  Created by feichao on 2024/6/2.
//

import SwiftUI
@_exported import Processed


public struct LoadingView<T: Sendable, Content: View>: View {
    @Loadable<T> var data
    let content: (T) -> Content
    let task: @MainActor (Loadable<T>.Binding) async -> Void
    @State var inited: Bool = false
    
    public init(@ViewBuilder content: @escaping (T) -> Content, task: @MainActor @escaping (Loadable<T>.Binding) async -> Void) {
        self.content = content
        self.task = task
    }
    
    public init(@ViewBuilder content: @escaping (T) -> Content, task: @MainActor @escaping () async throws -> T) {
        self.content = content
        self.task = { @MainActor (loader: Loadable<T>.Binding) async -> Void in
            await loader.load {
                try await task()
            }
        }
    }
    
    public var body: some View {
        Group {
            switch data {
            case .absent, .loading:
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white.opacity(0.3))
            case .error(let error):
                VStack {
                    Spacer()
                    Text("Error: \(error)")
                    Button("Retry") {
                        Task {
                            await task($data)
                        }
                    }
                    Spacer()
                }
            case .loaded(let d):
                content(d)
            }
        }
        .task {
            if !inited {
                await task($data)
                inited = true
            }
        }
    }
}



public struct LoadingDataView<T: Sendable, Content: View>: View {
    let content: (T) -> Content
    let state: LoadableState<T>
    let task: @MainActor () async -> Void
    @State var inited: Bool = false
    
    public init(_ state: LoadableState<T>, task: @MainActor @escaping () async -> Void, @ViewBuilder content: @escaping (T) -> Content) {
        self.state = state
        self.content = content
        self.task = task
    }
    
    public var body: some View {
        Group {
            switch state {
            case .absent, .loading:
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(0.3)
            case .error(let error):
                VStack {
                    Spacer()
                    Text("Error: \(error)")
                    Button("Retry") {
                        Task {
                            await task()
                        }
                    }
                    Spacer()
                }
            case .loaded(let d):
                content(d)
            }
        }
        .task {
            if !inited {
                await task()
                inited = true
            }
        }
    }
}
