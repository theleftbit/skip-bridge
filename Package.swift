// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "skip-bridge",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(
            name: "SkipBridge",
            type: .dynamic,
            targets: ["SkipBridge"]
        ),
        .library(
            name: "SkipBridgeKt",
            type: .dynamic,
            targets: ["SkipBridgeKt"]
        ),
        .library(
            name: "SkipBridgeToKotlinSamples",
            type: .dynamic,
            targets: ["SkipBridgeToKotlinSamples"]
        ),
        .library(
            name: "SkipBridgeToKotlinSamplesHelpers",
            type: .dynamic,
            targets: ["SkipBridgeToKotlinSamplesHelpers"]
        ),
        .library(
            name: "SkipBridgeToKotlinCompatSamples",
            type: .dynamic,
            targets: ["SkipBridgeToKotlinCompatSamples"]
        ),
        .library(
            name: "SkipBridgeToSwiftSamples",
            type: .dynamic,
            targets: ["SkipBridgeToSwiftSamples"]
        ),
        .library(
            name: "SkipBridgeToSwiftSamplesHelpers",
            type: .dynamic,
            targets: ["SkipBridgeToSwiftSamplesHelpers"]
        ),
        .library(
            name: "SkipBridgeToSwiftSamplesTestsSupport",
            type: .dynamic,
            targets: ["SkipBridgeToSwiftSamplesTestsSupport"]
        ),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.2.22"),
        .package(url: "https://source.skip.tools/skip-lib.git", from: "1.3.2"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.2.12"),
    ],
    targets: [
        .target(name: "CJNI"),
        .target(name: "SkipBridge",
            dependencies: ["CJNI", .product(name: "SkipLib", package: "skip-lib")],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipBridgeKt",
            dependencies: ["SkipBridge"],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipBridgeToKotlinSamples",
            dependencies: ["SkipBridgeToKotlinSamplesHelpers"],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipBridgeToKotlinSamplesHelpers",
            dependencies: ["SkipBridgeKt", .product(name: "SkipFoundation", package: "skip-foundation")],
                plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipBridgeToKotlinCompatSamples",
            dependencies: ["SkipBridgeKt", .product(name: "SkipFoundation", package: "skip-foundation")],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipBridgeToSwiftSamples",
            dependencies: ["SkipBridgeToSwiftSamplesHelpers"],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipBridgeToSwiftSamplesHelpers",
            dependencies: ["SkipBridgeKt", .product(name: "SkipFoundation", package: "skip-foundation")],
                plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipBridgeToSwiftSamplesTestsSupport",
            dependencies: ["SkipBridgeToSwiftSamples"],
                plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipBridgeToKotlinSamplesTests",
            dependencies: ["SkipBridgeToKotlinSamples", .product(name: "SkipTest", package: "skip")],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipBridgeToKotlinCompatSamplesTests",
            dependencies: ["SkipBridgeToKotlinCompatSamples", .product(name: "SkipTest", package: "skip")],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipBridgeToSwiftSamplesTestsSupportTests",
            dependencies: ["SkipBridgeToSwiftSamplesTestsSupport", .product(name: "SkipTest", package: "skip")],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
