// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyHomology",
    products: [
        .library(
            name: "SwiftyHomology",
            targets: ["SwiftyHomology"]),
    ],
    dependencies: [
        .package(
            name: "SwiftyMath",
            url: "../SwiftyMath",
            .branch("matrix-improve")
        ),
    ],
    targets: [
        .target(
            name: "SwiftyHomology",
            dependencies: ["SwiftyMath"],
			path: "Sources/SwiftyHomology"),
        .testTarget(
            name: "SwiftyHomologyTests",
            dependencies: ["SwiftyHomology"]),
    ]
)
