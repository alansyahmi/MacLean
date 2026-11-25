// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacLean",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "maclean", targets: ["MacLeanCLI"])
    ],
    targets: [
        .executableTarget(name: "MacLeanCLI")
    ]
)
