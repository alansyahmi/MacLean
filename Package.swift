// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacLean",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "maclean", targets: ["MacLeanCLI"])
    ],
    targets: [
        .target(name: "MacLeanCore"),
        .target(name: "MacLeanPlatformMacOS", dependencies: ["MacLeanCore"]),
        .executableTarget(
            name: "MacLeanCLI",
            dependencies: ["MacLeanCore", "MacLeanPlatformMacOS"]
        ),
        .testTarget(
            name: "MacLeanCoreTests",
            dependencies: ["MacLeanCore"],
            path: "tests/MacLeanCoreTests"
        ),
        .testTarget(
            name: "MacLeanPlatformMacOSTests",
            dependencies: ["MacLeanCore", "MacLeanPlatformMacOS"],
            path: "tests/MacLeanPlatformMacOSTests",
            resources: [.copy("Fixtures")]
        )
    ]
)
