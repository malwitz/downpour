// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Downpour",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Downpour", targets: ["Downpour"])
    ],
    targets: [
        .executableTarget(name: "Downpour"),
        .testTarget(name: "DownpourTests", dependencies: ["Downpour"])
    ]
)
