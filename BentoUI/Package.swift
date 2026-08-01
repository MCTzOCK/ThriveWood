// swift-tools-version: 5.10

#if canImport(PackageDescription)

import PackageDescription

let package = Package(
    name: "BentoUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BentoUI",
            targets: ["BentoUI"]
        )
    ],
    targets: [
        .target(
            name: "BentoUI"
        )
    ]
)

#endif
