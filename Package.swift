// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SupportKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "SupportKit", targets: ["SupportKit"]),
    ],
    targets: [
        .target(
            name: "SupportKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SupportKitTests",
            dependencies: ["SupportKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
