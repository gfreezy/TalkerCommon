// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TalkerCommon",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TalkerCommon",
            targets: ["TalkerCommon"])
    ],
    dependencies: [
        .package(url: "https://github.com/sushichop/Puppy", from: "0.7.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.19"),
        .package(url: "https://github.com/SwiftedMind/Processed", from: "2.2.0"),
        .package(url: "https://github.com/GeorgeElsham/ViewExtractor", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TalkerCommon",
            dependencies: [
                .product(name: "Puppy", package: "Puppy"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "Processed", package: "Processed"),
                .product(name: "ViewExtractor", package: "ViewExtractor"),
            ]
        ),
        .testTarget(
            name: "TalkerCommonTests",
            dependencies: ["TalkerCommon"]
        ),
    ]
)
