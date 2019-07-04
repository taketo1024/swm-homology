// swift-tools-version:5.0
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
        .package(url: "https://github.com/taketo1024/SwiftyMath.git", from: "1.0.24"),
//        .package(url: "../core/", .branch("HEAD")),
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
