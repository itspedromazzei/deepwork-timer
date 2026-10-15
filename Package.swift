// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeepworkTimer",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "DeepworkCore"),
        .executableTarget(name: "DeepworkTimer", dependencies: ["DeepworkCore"]),
        .testTarget(name: "DeepworkCoreTests", dependencies: ["DeepworkCore"]),
    ],
    swiftLanguageModes: [.v5]
)
