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
    dependencies: [
        .package(url: "https://github.com/nicklockwood/Expression", from: "0.13.0")
    ],
    targets: [
        .executableTarget(
            name: "Cal",
            dependencies: ["Expression"],
            path: "Sources/Cal",
            sources: [
                "main.swift",
                "Calculator.swift",
                "ExpressionBridge.swift",
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