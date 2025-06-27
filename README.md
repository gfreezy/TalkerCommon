# TalkerCommon

A Swift package containing common utilities and components for iOS apps.

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
