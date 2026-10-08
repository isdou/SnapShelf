// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Zancunjia",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Zancunjia", targets: ["Zancunjia"])
    ],
    targets: [
        .target(
            name: "ZancunjiaCore",
            path: "Sources/ZancunjiaCore",
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
        .executableTarget(
            name: "Zancunjia",
            dependencies: ["ZancunjiaCore"],
            path: "Sources/Zancunjia"
        ),
        .testTarget(
            name: "ZancunjiaCoreTests",
            dependencies: ["ZancunjiaCore"],
            path: "Tests/ZancunjiaCoreTests"
        ),
    ]
)
