import SwiftUI
import TalkerCommonLogging

/// 注意:`onFinish` 不参与 `==`/`hash` —— closure 没法 Hashable。
/// 两个 path/query 相同但 onFinish 不同的 `CmRouterPath` 在比较时视为相等,
/// `popMultiIfMatch` 等场景不要依赖 onFinish 区分。
public struct CmRouterPath: Hashable, Equatable {
    public let path: String
    public let query: [String: String]
    public let onFinish: (() -> Void)?

    public init(_ path: String, _ query: [String: String] = [:], onFinish: (() -> Void)? = nil) {
        self.path = path
        self.query = query
        self.onFinish = onFinish
    }

    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
        hasher.combine(query)
    }

    // MARK: - Equatable
    public static func == (lhs: CmRouterPath, rhs: CmRouterPath) -> Bool {
        return lhs.path == rhs.path && lhs.query == rhs.query
    }
}

public enum CmRouteAction {
    case push(CmRouterPath)
    case replace(CmRouterPath)
    case pop
    case popIfMatch(CmRouterPath)
    case popMultiIfMatch([CmRouterPath])
    case popToRoot
}

@MainActor
public protocol CmRouterDelegateProtocol: AnyObject {
    func afterPush(path: CmRouterPath)
    func afterPop(path: CmRouterPath)
}

public class CmDefaultRouterDelegate: CmRouterDelegateProtocol {
    public init() {}
    public func afterPush(path: CmRouterPath) {}
    public func afterPop(path: CmRouterPath) {}
}

@available(iOS, introduced: 17.0)
@MainActor
@Observable
public class CmRouterNew {
    fileprivate var navPath: [CmRouterPath] = []
    // navPath 在 task modifier 里面直接调用 NavigationPath 相关方法会不生效
    // 通过 navigationTrigger onChange 延迟一个周期可以解决这个问题。
    fileprivate var navigationTrigger: Int = 0

    @ObservationIgnored private var actions: [CmRouteAction] = []
    // 用于在 onChange(of: navPath) 里区分"程序触发"和"用户手势返回"
    @ObservationIgnored fileprivate var lastSyncedNavPath: [CmRouterPath] = []
    @ObservationIgnored public weak var delegate: CmRouterDelegateProtocol?

    public var isEmpty: Bool {
        navPath.isEmpty
    }

    public var isRoot: Bool {
        navPath.isEmpty
    }

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

    public func popToRoot() {
        actions.append(.popToRoot)
        navigationTrigger += 1
    }

    // Public func to replace top of stack (atomic)
    public func replace(_ path: CmRouterPath) {
        actions.append(.replace(path))
        navigationTrigger += 1
    }

    // Public func to push new view
    public func push(_ path: String, _ query: [String: String] = [:], onFinish: (() -> Void)? = nil)
    {
        push(CmRouterPath(path, query, onFinish: onFinish))
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
    public func replace(
        _ path: String, _ query: [String: String] = [:], onFinish: (() -> Void)? = nil
    ) {
        replace(CmRouterPath(path, query, onFinish: onFinish))
    }

    // Public func to push new view
    public func push(_ path: (String, [String: String]), onFinish: (() -> Void)? = nil) {
        push(CmRouterPath(path.0, path.1, onFinish: onFinish))
    }

    // Pop if the last path matches `path`
    public func popIfMatch(_ path: (String, [String: String])) {
        popIfMatch(CmRouterPath(path.0))
    }

    // Public func to pop view
    public func replace(_ path: (String, [String: String]), onFinish: (() -> Void)? = nil) {
        replace(CmRouterPath(path.0, path.1, onFinish: onFinish))
    }

    // Should only be used by NavigationStackView
    fileprivate func pushNavPath(_ path: CmRouterPath) {
        navPath.append(path)
    }

    // Should only be used by NavigationStackView
    fileprivate func takeAllNavAction() -> [CmRouteAction] {
        let old = actions
        actions = []
        return old
    }

    // Should only be used by NavigationStackView
    fileprivate func popNavPath() {
        if !navPath.isEmpty {
            _ = navPath.popLast()
        } else {
            debugLog("nav path is empty")
        }
    }

    // Should only be used by NavigationStackView
    fileprivate func popMultiNavPathsIfMatch(_ paths: [CmRouterPath]) -> Bool {
        let suffix = navPath.suffix(paths.count).map { $0.path }
        let target = Array(paths.map({ $0.path }).reversed())
        if suffix == target {
            navPath.removeLast(paths.count)
            return true
        } else {
            debugLog("nav path not match, do nothing, suffix: \(suffix), target: \(target)")
            return false
        }
    }

    // Should only be used by NavigationStackView
    fileprivate func popNavPathToRoot() {
        navPath.removeAll()
    }

    // Should only be used by NavigationStackView — atomic pop+push (single binding update)
    fileprivate func replaceNavPath(_ path: CmRouterPath) -> CmRouterPath? {
        var newNav = navPath
        let popped = newNav.popLast()
        newNav.append(path)
        navPath = newNav
        return popped
    }
}

@available(iOS, introduced: 16.0, obsoleted: 17.0)
@MainActor
public class CmRouterOld: ObservableObject {
    @Published fileprivate var navPath: [CmRouterPath] = []
    // navPath 在 task modifier 里面直接调用 NavigationPath 相关方法会不生效
    // 通过 navigationTrigger onChange 延迟一个周期可以解决这个问题。
    @Published fileprivate var navigationTrigger: Int = 0

    private var actions: [CmRouteAction] = []
    fileprivate var lastSyncedNavPath: [CmRouterPath] = []
    public weak var delegate: CmRouterDelegateProtocol?

    public var isEmpty: Bool {
        navPath.isEmpty
    }

    public var isRoot: Bool {
        navPath.isEmpty
    }

    // Public func to push new view
    public func push(_ path: CmRouterPath) {
        actions.append(.push(path))
        navigationTrigger += 1
    }

    // Public func to push new view
    public func popToRoot() {
        actions.append(.popToRoot)
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

    // Public func to replace top of stack (atomic)
    public func replace(_ path: CmRouterPath) {
        actions.append(.replace(path))
        navigationTrigger += 1
    }

    // Public func to push new view
    public func push(_ path: String, _ query: [String: String] = [:], onFinish: (() -> Void)? = nil)
    {
        push(CmRouterPath(path, query, onFinish: onFinish))
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
    public func replace(
        _ path: String, _ query: [String: String] = [:], onFinish: (() -> Void)? = nil
    ) {
        replace(CmRouterPath(path, query, onFinish: onFinish))
    }

    // Public func to push new view
    public func push(_ path: (String, [String: String]), onFinish: (() -> Void)? = nil) {
        push(CmRouterPath(path.0, path.1, onFinish: onFinish))
    }

    // Pop if the last path matches `path`
    public func popIfMatch(_ path: (String, [String: String])) {
        popIfMatch(CmRouterPath(path.0))
    }

    // Public func to pop view
    public func replace(_ path: (String, [String: String]), onFinish: (() -> Void)? = nil) {
        replace(CmRouterPath(path.0, path.1, onFinish: onFinish))
    }

    // Should only be used by NavigationStackView
    fileprivate func pushNavPath(_ path: CmRouterPath) {
        navPath.append(path)
    }

    // Should only be used by NavigationStackView
    fileprivate func takeAllNavAction() -> [CmRouteAction] {
        let old = actions
        actions = []
        return old
    }

    // Should only be used by NavigationStackView
    fileprivate func popNavPath() {
        if !navPath.isEmpty {
            _ = navPath.popLast()
        } else {
            debugLog("nav path is empty")
        }
    }

    // Should only be used by NavigationStackView
    fileprivate func popMultiNavPathsIfMatch(_ paths: [CmRouterPath]) -> Bool {
        let suffix = navPath.suffix(paths.count).map { $0.path }
        let target = Array(paths.map({ $0.path }).reversed())
        if suffix == target {
            navPath.removeLast(paths.count)
            return true
        } else {
            debugLog("nav path not match, do nothing, suffix: \(suffix), target: \(target)")
            return false
        }
    }

    // Should only be used by NavigationStackView
    fileprivate func popNavPathToRoot() {
        navPath.removeAll()
    }

    // Should only be used by NavigationStackView — atomic pop+push (single binding update)
    fileprivate func replaceNavPath(_ path: CmRouterPath) -> CmRouterPath? {
        var newNav = navPath
        let popped = newNav.popLast()
        newNav.append(path)
        navPath = newNav
        return popped
    }
}

/// 处理"用户手势返回"导致的 navPath 变化(程序触发的 push/pop 已在 trigger handler 里调用过 delegate)。
/// 通过 lastSyncedNavPath 与当前 navPath 的 diff,只对未触发过 delegate 的部分补调。
@MainActor
private func processGesturePathChanges(
    from oldSynced: [CmRouterPath],
    to newNavPath: [CmRouterPath],
    delegate: CmRouterDelegateProtocol?
) {
    let changes = calculatePathChanges(from: oldSynced, to: newNavPath)

    for path in changes.removedPaths.reversed() {
        path.onFinish?()
        delegate?.afterPop(path: path)
    }
    // 防御性处理:用户手势一般只 pop,但万一原生 NavigationLink 推了页面也兜住
    for path in changes.addedPaths {
        delegate?.afterPush(path: path)
    }
}

private func calculatePathChanges(from oldPath: [CmRouterPath], to newPath: [CmRouterPath]) -> (
    addedPaths: [CmRouterPath], removedPaths: [CmRouterPath]
) {
    var addedPaths: [CmRouterPath] = []
    var removedPaths: [CmRouterPath] = []

    // Find the common prefix length
    let commonLength = min(oldPath.count, newPath.count)
    var commonPrefixLength = 0

    for i in 0..<commonLength {
        if oldPath[i] == newPath[i] {
            commonPrefixLength = i + 1
        } else {
            break
        }
    }

    // Everything after the common prefix in oldPath is removed
    if commonPrefixLength < oldPath.count {
        removedPaths = Array(oldPath.suffix(from: commonPrefixLength))
    }

    // Everything after the common prefix in newPath is added
    if commonPrefixLength < newPath.count {
        addedPaths = Array(newPath.suffix(from: commonPrefixLength))
    }

    return (addedPaths: addedPaths, removedPaths: removedPaths)
}

@available(iOS 17.0, *)
public struct CmRouterViewNew<Content: View, Dest: View>: View {
    let view: Content

    @State var router: CmRouterNew = CmRouterNew()

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
        .task {
            router.delegate = delegate
        }
        .environment(router)
        .onChange(of: router.navigationTrigger, initial: false) { _, _ in
            for action in router.takeAllNavAction() {
                applyAction(action, router: router, delegate: delegate)
            }
            // 标记当前 navPath 已经被 delegate 处理过,后续 onChange(of: navPath)
            // 看到的相同值应直接跳过
            router.lastSyncedNavPath = router.navPath
        }
        .onChange(of: router.navPath) { _, newNavPath in
            // 程序触发的变化已经在 trigger handler 里处理过,navPath 此时等于 lastSyncedNavPath
            // 不等的话说明是用户手势返回(或其它 binding 直改),走 gesture 流程
            guard newNavPath != router.lastSyncedNavPath else { return }
            processGesturePathChanges(
                from: router.lastSyncedNavPath, to: newNavPath, delegate: delegate)
            router.lastSyncedNavPath = newNavPath
        }
    }
}

@available(iOS 17.0, *)
@MainActor
private func applyAction(
    _ action: CmRouteAction,
    router: CmRouterNew,
    delegate: CmRouterDelegateProtocol?
) {
    switch action {
    case .push(let path):
        router.pushNavPath(path)
        delegate?.afterPush(path: path)

    case .replace(let newPath):
        let popped = router.replaceNavPath(newPath)  // 一次性更新 binding
        if let p = popped {
            p.onFinish?()
            delegate?.afterPop(path: p)
        }
        delegate?.afterPush(path: newPath)

    case .pop:
        guard let last = router.navPath.last else {
            router.popNavPath()  // 仅打日志
            return
        }
        router.popNavPath()
        last.onFinish?()
        delegate?.afterPop(path: last)

    case .popIfMatch(let path):
        guard router.navPath.last == path, let last = router.navPath.last else { return }
        router.popNavPath()
        last.onFinish?()
        delegate?.afterPop(path: last)

    case .popMultiIfMatch(let paths):
        let suffix = Array(router.navPath.suffix(paths.count))
        let target = Array(paths.map { $0.path }.reversed())
        guard suffix.map({ $0.path }) == target else {
            _ = router.popMultiNavPathsIfMatch(paths)  // 仅打日志
            return
        }
        _ = router.popMultiNavPathsIfMatch(paths)
        for p in suffix.reversed() {
            p.onFinish?()
            delegate?.afterPop(path: p)
        }

    case .popToRoot:
        let toPop = router.navPath
        router.popNavPathToRoot()
        for p in toPop.reversed() {
            p.onFinish?()
            delegate?.afterPop(path: p)
        }
    }
}

@available(iOS, introduced: 16.0, obsoleted: 17.0)
public struct CmRouterViewOld<Content: View, Dest: View>: View {
    let view: Content

    @StateObject var router: CmRouterOld = CmRouterOld()

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
        .task {
            router.delegate = delegate
        }
        .environmentObject(router)
        .onChange(of: router.navigationTrigger) { _ in
            for action in router.takeAllNavAction() {
                applyActionOld(action, router: router, delegate: delegate)
            }
            router.lastSyncedNavPath = router.navPath
        }
        .onChange(of: router.navPath) { _ in
            let newNavPath = router.navPath
            guard newNavPath != router.lastSyncedNavPath else { return }
            processGesturePathChanges(
                from: router.lastSyncedNavPath, to: newNavPath, delegate: delegate)
            router.lastSyncedNavPath = newNavPath
        }
    }
}

@available(iOS, introduced: 16.0, obsoleted: 17.0)
@MainActor
private func applyActionOld(
    _ action: CmRouteAction,
    router: CmRouterOld,
    delegate: CmRouterDelegateProtocol?
) {
    switch action {
    case .push(let path):
        router.pushNavPath(path)
        delegate?.afterPush(path: path)

    case .replace(let newPath):
        let popped = router.replaceNavPath(newPath)
        if let p = popped {
            p.onFinish?()
            delegate?.afterPop(path: p)
        }
        delegate?.afterPush(path: newPath)

    case .pop:
        guard let last = router.navPath.last else {
            router.popNavPath()
            return
        }
        router.popNavPath()
        last.onFinish?()
        delegate?.afterPop(path: last)

    case .popIfMatch(let path):
        guard router.navPath.last == path, let last = router.navPath.last else { return }
        router.popNavPath()
        last.onFinish?()
        delegate?.afterPop(path: last)

    case .popMultiIfMatch(let paths):
        let suffix = Array(router.navPath.suffix(paths.count))
        let target = Array(paths.map { $0.path }.reversed())
        guard suffix.map({ $0.path }) == target else {
            _ = router.popMultiNavPathsIfMatch(paths)
            return
        }
        _ = router.popMultiNavPathsIfMatch(paths)
        for p in suffix.reversed() {
            p.onFinish?()
            delegate?.afterPop(path: p)
        }

    case .popToRoot:
        let toPop = router.navPath
        router.popNavPathToRoot()
        for p in toPop.reversed() {
            p.onFinish?()
            delegate?.afterPop(path: p)
        }
    }
}

@available(iOS 17.0, *)
public struct NavigationButtonNew<Body: View>: View {
    let destination: Body
    let path: (String, [String: String])
    let onFinish: (() -> Void)?

    @Environment(CmRouter.self) var router

    public init(
        _ path: (String, [String: String]), onFinish: (() -> Void)? = nil,
        @ViewBuilder body: () -> Body
    ) {
        self.path = path
        self.onFinish = onFinish
        self.destination = body()
    }

    public var body: some View {
        Button(action: {
            router.push(path, onFinish: onFinish)
        }) {
            destination
        }
    }
}

@available(iOS, introduced: 16.0, obsoleted: 17.0)
public struct NavigationButtonOld<Body: View>: View {
    let destination: Body
    let path: (String, [String: String])
    let onFinish: (() -> Void)?

    @EnvironmentObject var router: CmRouterOld

    public init(
        _ path: (String, [String: String]), onFinish: (() -> Void)? = nil,
        @ViewBuilder body: () -> Body
    ) {
        self.path = path
        self.onFinish = onFinish
        self.destination = body()
    }

    public var body: some View {
        Button(action: {
            router.push(path, onFinish: onFinish)
        }) {
            destination
        }
    }
}

@available(iOS 17.0, *)
public typealias NavigationButton = NavigationButtonNew
@available(iOS 17.0, *)
public typealias CmRouterView = CmRouterViewNew
@available(iOS 17.0, *)
public typealias CmRouter = CmRouterNew
