// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ZarrSwift",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [.library(name: "ZarrSwift", targets: ["ZarrSwift"])],
    dependencies: [
            .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
            .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),

        ],
    targets: [
        .target(name: "ZarrSwift", path: "Sources/ZarrSwift"),
        .executableTarget(name: "ZarrTool", dependencies: ["ZarrSwift"], path: "Sources/CLI"),
        .testTarget(name: "ZarrSwiftTests", dependencies: ["ZarrSwift"])
    ]
)
