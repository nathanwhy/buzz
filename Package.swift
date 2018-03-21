// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "buzz",
    dependencies: [
        .package(url: "https://github.com/johnsundell/files.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "buzz", dependencies: ["buzzCore"]),
        .target(name: "buzzCore", dependencies: ["Files", "CommandLineKit"]),
        .target(name: "CommandLineKit", dependencies: []),
        .testTarget(name: "buzzTests", dependencies: ["buzzCore", "Files"])
    ]
)
