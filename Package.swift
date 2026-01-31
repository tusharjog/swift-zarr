// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftZarr",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [.library(name: "SwiftZarr", targets: ["SwiftZarr"])],
    dependencies: [
            .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
            .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
            .package(url: "https://github.com/pvieito/PythonKit.git", branch: "master"),

        ],
    targets: [
        .target(name: "SwiftZarr", path: "Sources/SwiftZarr"),
        .executableTarget(name: "ZarrTool", dependencies: ["SwiftZarr", .product(name: "ArgumentParser", package: "swift-argument-parser")], path: "Sources/CLI"),
        .testTarget(name: "SwiftZarrTests", dependencies: ["SwiftZarr", "PythonKit"])
    ]
)
