// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StickyNotes",
    platforms: [
        // Deployment floor: macOS 14 (Sonoma). Builds with the current SDK,
        // runs on Sonoma/Sequoia/Tahoe.
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "StickyNotes",
            path: "Sources/StickyNotes"
        ),
        .testTarget(
            name: "StickyNotesTests",
            dependencies: ["StickyNotes"],
            path: "Tests/StickyNotesTests"
        )
    ]
)
