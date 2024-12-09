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

Example usage:

```swift
struct HomeView: View {
    // View implementation
    @Routable("home")
    init() {
        // View initialization
    }
}
```
