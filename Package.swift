// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ElysiumVanguard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "elysium-cli", targets: ["ElysiumCLI"]),
        .executable(name: "elysium-app", targets: ["ElysiumApp"]),
        .library(name: "ElysiumCore", targets: ["ElysiumCore"]),
        .library(name: "ElysiumUI", targets: ["ElysiumUI"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ElysiumCore",
            dependencies: [],
            path: "Sources/ElysiumCore"
        ),
        .target(
            name: "ElysiumUI",
            dependencies: ["ElysiumCore"],
            path: "Sources/ElysiumUI",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "ElysiumCLI",
            dependencies: ["ElysiumCore", "ElysiumUI"],
            path: "Sources/ElysiumCLI"
        ),
        .executableTarget(
            name: "ElysiumApp",
            dependencies: ["ElysiumCore", "ElysiumUI"],
            path: "Sources/ElysiumApp"
        ),
        .testTarget(
            name: "ElysiumCoreTests",
            dependencies: ["ElysiumCore"],
            path: "Tests/ElysiumCoreTests"
        )
    ]
)
