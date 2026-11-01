// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PairwiseKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PairwiseCore", targets: ["PairwiseCore"]),
        .library(name: "PairwiseWindowSystem", targets: ["PairwiseWindowSystem"]),
        .library(name: "PairwiseUI", targets: ["PairwiseUI"]),
        .library(name: "PairwiseTestSupport", targets: ["PairwiseTestSupport"]),
    ],
    targets: [
        .target(name: "PairwiseCore"),
        .target(
            name: "PairwiseWindowSystem",
            dependencies: ["PairwiseCore"]
        ),
        .target(
            name: "PairwiseUI",
            dependencies: ["PairwiseCore", "PairwiseWindowSystem"]
        ),
        .target(
            name: "PairwiseTestSupport",
            dependencies: ["PairwiseCore"]
        ),
        .testTarget(
            name: "PairwiseCoreTests",
            dependencies: ["PairwiseCore", "PairwiseTestSupport"]
        ),
        .testTarget(
            name: "PairwiseWindowSystemTests",
            dependencies: ["PairwiseWindowSystem", "PairwiseTestSupport"]
        ),
        .testTarget(
            name: "PairwiseUITests",
            dependencies: ["PairwiseUI", "PairwiseTestSupport"]
        ),
        .testTarget(
            name: "PairwiseTestSupportTests",
            dependencies: ["PairwiseTestSupport"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
