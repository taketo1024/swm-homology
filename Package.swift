// swift-tools-version:5.3
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
            url: "https://github.com/taketo1024/SwiftyMath.git",
            from: "3.0.0"
        ),
    ],
    targets: [
        .target(
            name: "SwiftyHomology",
            dependencies: ["SwiftyMath"]
		),
        .testTarget(
            name: "SwiftyHomologyTests",
            dependencies: ["SwiftyHomology"]),
    ]
)
