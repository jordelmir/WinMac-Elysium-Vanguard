// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ElysiumVanguard",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "elysium-cli", targets: ["ElysiumCLI"]),
        .library(name: "ElysiumCore", targets: ["ElysiumCore"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ElysiumCore",
            dependencies: [],
            path: "Sources/ElysiumCore"
        ),
        .executableTarget(
            name: "ElysiumCLI",
            dependencies: ["ElysiumCore"],
            path: "Sources/ElysiumCLI"
        ),
        .testTarget(
            name: "ElysiumCoreTests",
            dependencies: ["ElysiumCore"],
            path: "Tests/ElysiumCoreTests"
        )
    ]
)
