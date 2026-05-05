// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TalkerCommon",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        .library(name: "TalkerCommon", targets: ["TalkerCommon"]),
        .library(name: "TalkerCommonLogging", targets: ["TalkerCommonLogging"]),
        .library(name: "TalkerCommonSync", targets: ["TalkerCommonSync"]),
        .library(name: "TalkerCommonRouter", targets: ["TalkerCommonRouter"]),
        .library(name: "TalkerCommonError", targets: ["TalkerCommonError"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sushichop/Puppy", from: "0.8.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.19"),
        .package(url: "https://github.com/GeorgeElsham/ViewExtractor", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "TalkerCommonSync"
        ),
        .target(
            name: "TalkerCommonLogging",
            dependencies: [
                "TalkerCommonSync",
                .product(name: "Puppy", package: "Puppy"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ]
        ),
        .target(
            name: "TalkerCommonError",
            dependencies: ["TalkerCommonLogging"]
        ),
        .target(
            name: "TalkerCommonRouter",
            dependencies: ["TalkerCommonLogging"]
        ),
        .target(
            name: "TalkerCommon",
            dependencies: [
                "TalkerCommonLogging",
                "TalkerCommonSync",
                "TalkerCommonRouter",
                "TalkerCommonError",
                .product(name: "ViewExtractor", package: "ViewExtractor"),
            ]
        ),
        .testTarget(
            name: "TalkerCommonTests",
            dependencies: ["TalkerCommon"]
        ),
        .testTarget(
            name: "TalkerCommonSyncTests",
            dependencies: ["TalkerCommonSync"]
        ),
    ]
)
