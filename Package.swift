// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Cal",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "Cal", targets: ["Cal"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Cal",
            dependencies: [],
            path: "Sources/Cal",
            sources: [
                "main.swift",
                "Calculator.swift",
                "UI.swift",
                "FileManager.swift",
                "Extensions.swift",
                "CommandProcessor.swift"
            ]
        ),
        .testTarget(
            name: "CalTests",
            dependencies: ["Cal"],
            path: "Tests/CalTests"
        )
    ]
) 