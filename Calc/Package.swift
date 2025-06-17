// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftCalculator",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "SwiftCalculator", targets: ["SwiftCalculator"])
    ],
    targets: [
        .target(
            name: "SwiftCalculator",
            path: "."
        )
    ]
)
