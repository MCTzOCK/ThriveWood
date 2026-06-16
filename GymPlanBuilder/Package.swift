// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GymPlanBuilder",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "GymPlanBuilder", targets: ["GymPlanBuilder"]),
    ],
    targets: [
        .executableTarget(
            name: "GymPlanBuilder",
            dependencies: ["GymPlanBuilderCore"],
            path: "Sources/GymPlanBuilder",
            resources: [
                .process("Assets.xcassets"),
            ]
        ),
        .target(
            name: "GymPlanBuilderCore",
            path: "Sources/GymPlanBuilderCore"
        ),
    ]
)
