import SwiftUI

public struct CmRouterPath: Hashable, Equatable {
    public let path: String
    public let query: [String: String]

    public init(_ path: String, _ query: [String: String] = [:]) {
        self.path = path
        self.query = query
    }
}

public enum CmRouteAction {
    case push(CmRouterPath)
    case pop
    case popIfMatch(CmRouterPath)
    case popMultiIfMatch([CmRouterPath])
}

@MainActor
public protocol CmRouterDelegateProtocol: AnyObject {
    func beforePush(path: CmRouterPath) -> CmRouterPath
    func afterPush(path: CmRouterPath)
    func beforePop(path: CmRouterPath)
    func afterPop(path: CmRouterPath)
}

public class CmDefaultRouterDelegate: CmRouterDelegateProtocol {
    public func beforePush(path: CmRouterPath) -> CmRouterPath {
        path
    }
    public func afterPush(path: CmRouterPath) {

    }
    public func beforePop(path: CmRouterPath) {
    }

    public func afterPop(path: CmRouterPath) {

    }
}

#if canImport(Observation)

    @available(iOS 17.0, *)
    @MainActor
    @Observable
    public class CmRouter {
        fileprivate var navPath: [CmRouterPath] = []
        // navPath 在 task modifier 里面直接调用 NavigationPath 相关方法会不生效
        // 通过 navigationTrigger onChange 延迟一个周期可以解决这个问题。
        fileprivate var navigationTrigger: Int = 0

        @ObservationIgnored private var actions: [CmRouteAction] = []
        public var delegate: CmRouterDelegateProtocol?

        // Public func to push new view
        public func push(_ path: CmRouterPath) {
            actions.append(.push(path))
            navigationTrigger += 1
        }

        // Public func to pop view
        public func pop() {
            actions.append(.pop)
            navigationTrigger += 1
        }

        // Pop if the last path matches `path`
        public func popIfMatch(_ path: CmRouterPath) {
            actions.append(.popIfMatch(path))
            navigationTrigger += 1
        }

        // Pop if the last path matches `path`
        public func popMultiIfMatch(_ paths: [CmRouterPath]) {
            actions.append(.popMultiIfMatch(paths))
            navigationTrigger += 1
        }

        // Public func to pop view
        public func replace(_ path: CmRouterPath) {
            pop()
            push(path)
        }

        // Public func to push new view
        public func push(_ path: String, _ query: [String: String] = [:]) {
            push(CmRouterPath(path, query))
        }

        // Pop if the last path matches `path`
        public func popIfMatch(_ path: String) {
            popIfMatch(CmRouterPath(path))
        }

        // Pop if the last path matches `path`
        public func popMultiIfMatch(_ paths: [String]) {
            popMultiIfMatch(paths.map { CmRouterPath($0) })
        }

        // Public func to pop view
        public func replace(_ path: String, _ query: [String: String] = [:]) {
            replace(CmRouterPath(path, query))
        }

        // Public func to push new view
        public func push(_ path: (String, [String: String])) {
            push(CmRouterPath(path.0, path.1))
        }

        // Pop if the last path matches `path`
        public func popIfMatch(_ path: (String, [String: String])) {
            popIfMatch(CmRouterPath(path.0))
        }

        // Public func to pop view
        public func replace(_ path: (String, [String: String])) {
            replace(CmRouterPath(path.0, path.1))
        }

        // Should only be used by NavigationStackView
        fileprivate func pushNavPath(_ path: CmRouterPath) {
            let newPath = delegate?.beforePush(path: path) ?? path
            navPath.append(newPath)
            delegate?.afterPush(path: newPath)
        }

        // Should only be used by NavigationStackView
        fileprivate func takeAllNavAction() -> [CmRouteAction] {
            let old = actions
            actions = []
            return old
        }

        // Should only be used by NavigationStackView
        fileprivate func popNavPath() {
            if let path = navPath.last {
                delegate?.beforePop(path: path)
                _ = navPath.popLast()
                delegate?.afterPop(path: path)
            } else {
                debugLog("nav path is empty")
            }
        }

        // Should only be used by NavigationStackView
        fileprivate func popNavPathIfMatch(_ path: CmRouterPath) {
            popMultiIfMatch([path])
        }

        // Should only be used by NavigationStackView
        fileprivate func popMultiNavPathsIfMatch(_ paths: [CmRouterPath]) {
            let suffix = navPath.suffix(paths.count).map { $0.path }
            let target = Array(paths.map({ $0.path }).reversed())
            if suffix == target {
                for path in paths {
                    delegate?.beforePop(path: path)
                }
                navPath.removeLast(paths.count)
                for path in paths {
                    delegate?.afterPop(path: path)
                }
            } else {
                debugLog("nav path not match, do nothing, suffix: \(suffix), target: \(target)")
            }
        }
    }

    @available(iOS 17.0, *)
    public struct CmRouterView<Content: View, Dest: View>: View {
        let view: Content

        @State var router: CmRouter = CmRouter()

        let destinationView: (CmRouterPath) -> Dest
        let delegate: CmRouterDelegateProtocol?

        public init(
            delegate: CmRouterDelegateProtocol? = nil, @ViewBuilder content: () -> Content,
            @ViewBuilder destView: @escaping (CmRouterPath) -> Dest
        ) {
            self.delegate = delegate
            self.view = content()
            self.destinationView = destView
        }

        public init(
            delegate: CmRouterDelegateProtocol? = nil, @ViewBuilder content: () -> Content,
            @ViewBuilder destView: @escaping (String, [String: String]) -> Dest
        ) {
            self.delegate = delegate
            self.view = content()
            self.destinationView = { path in
                destView(path.path, path.query)
            }
        }

        public var body: some View {
            NavigationStack(path: $router.navPath) {
                view
                    .navigationDestination(for: CmRouterPath.self) { path in
                        destinationView(path)
                    }
            }
            .onAppear {
                router.delegate = delegate
            }
            .environment(router)
            .onChange(of: router.navigationTrigger, initial: false) { _, _ in
                for action in router.takeAllNavAction() {
                    switch action {
                    case .push(let path):
                        router.pushNavPath(path)
                    case .pop:
                        router.popNavPath()
                    case .popIfMatch(let path):
                        router.popNavPathIfMatch(path)
                    case .popMultiIfMatch(let paths):
                        router.popMultiNavPathsIfMatch(paths)
                    }
                }
            }
        }
    }

    @available(iOS 17.0, *)
    public struct NavigationButton<Body: View>: View {
        let destination: Body
        let path: (String, [String: String])

        @Environment(CmRouter.self) var router

        public init(_ path: (String, [String: String]), @ViewBuilder body: () -> Body) {
            self.path = path
            self.destination = body()
        }

        public var body: some View {
            Button(action: {
                router.push(path)
            }) {
                destination
            }
        }
    }

#else

    @MainActor
    public class CmRouter: ObservableObject {
        @Published fileprivate var navPath: [CmRouterPath] = []
        // navPath 在 task modifier 里面直接调用 NavigationPath 相关方法会不生效
        // 通过 navigationTrigger onChange 延迟一个周期可以解决这个问题。
        @Published fileprivate var navigationTrigger: Int = 0

        private var actions: [CmRouteAction] = []
        public var delegate: CmRouterDelegateProtocol?

        // Public func to push new view
        public func push(_ path: CmRouterPath) {
            actions.append(.push(path))
            navigationTrigger += 1
        }

        // Public func to pop view
        public func pop() {
            actions.append(.pop)
            navigationTrigger += 1
        }

        // Pop if the last path matches `path`
        public func popIfMatch(_ path: CmRouterPath) {
            actions.append(.popIfMatch(path))
            navigationTrigger += 1
        }

        // Pop if the last path matches `path`
        public func popMultiIfMatch(_ paths: [CmRouterPath]) {
            actions.append(.popMultiIfMatch(paths))
            navigationTrigger += 1
        }

        // Public func to pop view
        public func replace(_ path: CmRouterPath) {
            pop()
            push(path)
        }

        // Public func to push new view
        public func push(_ path: String, _ query: [String: String] = [:]) {
            push(CmRouterPath(path, query))
        }

        // Pop if the last path matches `path`
        public func popIfMatch(_ path: String) {
            popIfMatch(CmRouterPath(path))
        }

        // Pop if the last path matches `path`
        public func popMultiIfMatch(_ paths: [String]) {
            popMultiIfMatch(paths.map { CmRouterPath($0) })
        }

        // Public func to pop view
        public func replace(_ path: String, _ query: [String: String] = [:]) {
            replace(CmRouterPath(path, query))
        }

        // Public func to push new view
        public func push(_ path: (String, [String: String])) {
            push(CmRouterPath(path.0, path.1))
        }

        // Pop if the last path matches `path`
        public func popIfMatch(_ path: (String, [String: String])) {
            popIfMatch(CmRouterPath(path.0))
        }

        // Public func to pop view
        public func replace(_ path: (String, [String: String])) {
            replace(CmRouterPath(path.0, path.1))
        }

        // Should only be used by NavigationStackView
        fileprivate func pushNavPath(_ path: CmRouterPath) {
            let newPath = delegate?.beforePush(path: path) ?? path
            navPath.append(newPath)
            delegate?.afterPush(path: newPath)
        }

        // Should only be used by NavigationStackView
        fileprivate func takeAllNavAction() -> [CmRouteAction] {
            let old = actions
            actions = []
            return old
        }

        // Should only be used by NavigationStackView
        fileprivate func popNavPath() {
            if let path = navPath.last {
                delegate?.beforePop(path: path)
                _ = navPath.popLast()
                delegate?.afterPop(path: path)
            } else {
                debugLog("nav path is empty")
            }
        }

        // Should only be used by NavigationStackView
        fileprivate func popNavPathIfMatch(_ path: CmRouterPath) {
            popMultiIfMatch([path])
        }

        // Should only be used by NavigationStackView
        fileprivate func popMultiNavPathsIfMatch(_ paths: [CmRouterPath]) {
            let suffix = navPath.suffix(paths.count).map { $0.path }
            let target = Array(paths.map({ $0.path }).reversed())
            if suffix == target {
                for path in paths {
                    delegate?.beforePop(path: path)
                }
                navPath.removeLast(paths.count)
                for path in paths {
                    delegate?.afterPop(path: path)
                }
            } else {
                debugLog("nav path not match, do nothing, suffix: \(suffix), target: \(target)")
            }
        }
    }

    public struct CmRouterView<Content: View, Dest: View>: View {
        let view: Content

        @StateObject var router: CmRouter = CmRouter()

        let destinationView: (CmRouterPath) -> Dest
        let delegate: CmRouterDelegateProtocol?

        public init(
            delegate: CmRouterDelegateProtocol? = nil, @ViewBuilder content: () -> Content,
            @ViewBuilder destView: @escaping (CmRouterPath) -> Dest
        ) {
            self.delegate = delegate
            self.view = content()
            self.destinationView = destView
        }

        public init(
            delegate: CmRouterDelegateProtocol? = nil, @ViewBuilder content: () -> Content,
            @ViewBuilder destView: @escaping (String, [String: String]) -> Dest
        ) {
            self.delegate = delegate
            self.view = content()
            self.destinationView = { path in
                destView(path.path, path.query)
            }
        }

        public var body: some View {
            NavigationStack(path: $router.navPath) {
                view
                    .navigationDestination(for: CmRouterPath.self) { path in
                        destinationView(path)
                    }
            }
            .onAppear {
                router.delegate = delegate
            }
            .environmentObject(router)
            .onChange(of: router.navigationTrigger) {
                _ in
                for action in router.takeAllNavAction() {
                    switch action {
                    case .push(let path):
                        router.pushNavPath(path)
                    case .pop:
                        router.popNavPath()
                    case .popIfMatch(let path):
                        router.popNavPathIfMatch(path)
                    case .popMultiIfMatch(let paths):
                        router.popMultiNavPathsIfMatch(paths)
                    }
                }
            }
        }
    }

    public struct NavigationButton<Body: View>: View {
        let destination: Body
        let path: (String, [String: String])

        @EnvironmentObject var router: CmRouter

        public init(_ path: (String, [String: String]), @ViewBuilder body: () -> Body) {
            self.path = path
            self.destination = body()
        }

        public var body: some View {
            Button(action: {
                router.push(path)
            }) {
                destination
            }
        }
    }

#endif
