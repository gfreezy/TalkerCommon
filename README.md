# TalkerCommon

A Swift package containing common utilities and components for iOS apps.

## Package Structure

包被拆成 5 个 library,可以按需引入,避免不必要的依赖编译。

| Library | 职责 | 三方依赖 |
|---|---|---|
| `TalkerCommonSync` | `Lock<T>` / `OneShotChannel` / `UncheckedSendable` / `Task` 扩展 | 无 |
| `TalkerCommonLogging` | `Logger` / `timeLog` / `LogTimer` | Puppy, ZIPFoundation |
| `TalkerCommonError` | `TalkerError` + 错误工具函数 | 无(传递依赖 Logging) |
| `TalkerCommonRouter` | `CmRouter` 导航路由 | 无(传递依赖 Logging) |
| `TalkerCommon` | UI 组件、Color、KeychainStore、Analytics 等其余全部 | Processed, ViewExtractor |

依赖图:

```
TalkerCommonSync         (无内部/外部依赖)
   ↑
TalkerCommonLogging
   ↑           ↑           ↑
TalkerCommonError  TalkerCommonRouter  TalkerCommon
```

`TalkerCommon` 通过 `@_exported import` 重新导出其它 4 个 library —— 只 `import TalkerCommon` 就能直接用 `Lock`、`debugLog`、`CmRouter`、`TalkerError` 等所有类型(保持向后兼容)。需要细粒度引入时单独 import:

```swift
// Package.swift
.target(
    name: "MyApp",
    dependencies: [
        // 全量(向后兼容)
        .product(name: "TalkerCommon", package: "TalkerCommon"),

        // 或按需:只想要日志,不拉 Processed/ViewExtractor
        // .product(name: "TalkerCommonLogging", package: "TalkerCommon"),
        // .product(name: "TalkerCommonSync", package: "TalkerCommon"),
    ]
)
```

## Features

### CmRouter - Navigation Router

A navigation router that provides:

- Programmatic navigation with path and query parameters
- Navigation stack management (push, pop, replace)
- Navigation delegate hooks for custom behavior
- Support for iOS 16+ and iOS 17+ with SwiftUI navigation
- Type-safe routing with `@Routable` macro, github: [TalkerMacro](https://github.com/gfreezy/TalkerMacro)
- **onFinish callbacks** - Execute closures when pages are closed

### 定义页面路由

```swift
import SwiftUI
import TalkerMacro

struct HomeView: View {
    // View implementation
    @Routable("/pages/home")
    init() {
        // View initialization
    }

    var body: some View {
        Text("Home")
        Button("Go to Calorie") {
            router.push(CalorieView.route(id: "123"))
        }
    }
}

struct CalorieView: View {
    @Environment(Router.self) var router: Router

    @Routable("/pages/calorie")
    init(id: String) {
        // View initialization
    }

    var body: some View {
        Button("Go to Home") {
            router.pop()
        }
    }
}

struct RouterView: View {
    var body: some View {
        RouterView {
            HomeView()
        }
    }
}
```

### 使用 onFinish 回调

```swift
// 使用便利方法
router.push("profile", ["id": "123"]) {
    print("Profile page was closed")
}

// 使用 CmRouterPath
let path = CmRouterPath("settings", ["tab": "general"]) {
    print("Settings page was closed")
}
router.push(path)

// 使用 NavigationButton
NavigationButton(("profile", ["id": "123"]), onFinish: {
    print("Profile page was closed")
}) {
    Text("Go to Profile")
}

// 使用 replace 方法
router.replace("home") {
    print("Previous page was replaced")
}
```

### 定义 RouterView

```swift
import SwiftUI
import TalkerCommon
import TalkerMacro

typealias Router = CmRouter
typealias RouterButton = NavigationButton

struct RouterView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    #routeViews(HomePage.self, CaloriePage.self)

    var body: some View {
        CmRouterView {
            InjectView {
                content
            }
        } destView: { path, query in
            view(path, query: query)
        }
    }
}

#Preview {
    RouterView {
        Text("Hello, World!")
    }
}

```

## Error Utilities

### 命名方式

| Name | Description |
|------|-------------|
| log | 不改变函数签名，直接打印日志 |
| capture | 捕获错误，去掉函数签名中的 throws，去掉返回值，并打印日志 |
| toast | 发送错误消息，不改变函数签名，并打印日志 |
| task | 去掉函数签名中的 async，去掉返回值，并打印日志 |

### 函数列表

| Utility function | Description |
|-------|-------------|
|logError| 不改变函数签名，直接打印日志 |
|captureError| 捕获错误，去掉函数签名中的 throws，去掉返回值，并打印日志 |
|toastError| 发送错误消息，不改变函数签名，并打印日志 |
|taskCaptureError| 捕获错误，去掉函数签名中的 async，去掉返回值，并打印日志 |
|taskToastError| 发送错误消息，去掉函数签名中的 async，去掉返回值，并打印日志 |
|taskLogError| 不改变函数签名，直接打印日志 |
|toastCaptureError| 捕获错误，去掉函数签名中的 async，去掉返回值，并打印日志 |

## Logger Utilities

| Function | Description |
|----------|-------------|
|setupLogger| 设置日志记录器 |
|exportLogs| 导出日志文件 |
|debugLog| 记录调试日志 |
|infoLog| 记录信息日志 |
|errorLog| 记录错误日志 |
|timeLog| 闭包计时,自动记录耗时,sync / async 双重载 |
|LogTimer| 多段计时类,支持 `lap` / `stop` |

### 计时示例

`timeLog` —— 用闭包包住要计时的代码,抛错也能正确记录耗时:

```swift
// 同步
let user = timeLog("parseUser") { try parse(data) }

// 异步
let user = await timeLog("fetchUser") { try await api.fetch() }

// 自定义日志级别
timeLog("expensive-op", logLevel: .info) { compute() }
```

输出形如:`fetchUser ⏱ 234.5ms`(沿用现有 emoji + `file:line` 前缀)。

`LogTimer` —— 需要分段记录时用,API 跟 `infoLog` 同款(变参 items + 自动捕获 `#file/#line`):

```swift
let t = LogTimer("import-pipeline")
parse();    t.lap("parsed", count)
validate(); t.lap("validated")
save();     t.stop("saved", id)
```

输出形如:

```
import-pipeline ⏱ +120ms total=120ms ["parsed", 1024]
import-pipeline ⏱ +30ms total=150ms ["validated"]
import-pipeline ⏱ done 350ms ["saved", "abc-123"]
```

时钟用 `ContinuousClock`,单调,不受 NTP 校时影响。
