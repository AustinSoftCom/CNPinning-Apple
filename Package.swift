// swift-tools-version: 6.3
// Copyright (c) 2026 AustinSoft.com

import PackageDescription

let package = Package(
    name: "CNPinning-Apple",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "CNPinning-Apple",
            targets: ["CNPinning-Apple"]
        ),
    ],
    targets: [
        .target(
            name: "CNPinning-Apple"
        ),
        .testTarget(
            name: "CNPinning-Apple-Tests",
            dependencies: ["CNPinning-Apple"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
