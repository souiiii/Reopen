// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Reopen",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Reopen", targets: ["Reopen"])
    ],
    targets: [
        .executableTarget(
            name: "Reopen",
            path: "Reopen",
            exclude: ["Resources"]
        )
    ]
)
