// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swm-homology",
    products: [
        .library(
            name: "SwmHomology",
            targets: ["SwmHomology"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/taketo1024/swm-core.git",
            from: "1.0.1"
        ),
    ],
    targets: [
        .target(
            name: "SwmHomology",
            dependencies: [
                .product(name: "SwmCore", package: "swm-core"),
            ]
		),
        .testTarget(
            name: "SwmHomologyTests",
            dependencies: ["SwmHomology"]),
    ]
)
