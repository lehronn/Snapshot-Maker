// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnapshotMaker",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SnapshotMaker", targets: ["SnapshotMaker"])
    ],
    targets: [
        .executableTarget(
            name: "SnapshotMaker",
            path: "Sources",
            resources: [
                .process("Localization")
            ]
        )
    ]
)
