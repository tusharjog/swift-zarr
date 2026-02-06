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
            .package(url: "https://github.com/apple/swift-system", from: "1.6.1"),
            .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
            .package(url: "https://github.com/facebook/zstd.git", from: "1.5.0"),

        ],
    targets: [
        .target(name: "SwiftZarr", dependencies: ["ZIPFoundation", .product(name: "libzstd", package: "zstd")], path: "Sources/SwiftZarr"),
        .executableTarget(name: "ZarrTool", dependencies: ["SwiftZarr", .product(name: "ArgumentParser", package: "swift-argument-parser")], path: "Sources/CLI"),
        .testTarget(name: "SwiftZarrTests", 
                    dependencies: ["SwiftZarr",
                                   "PythonKit",
                                   .product(name: "SystemPackage", package: "swift-system")],
                    path: "Tests",
                    exclude: ["__pycache__"],
                    resources: [.copy("files"), .copy("create_zarr.py")])
    ]
)
