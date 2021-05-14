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
            url: "https://github.com/taketo1024/SwiftyMath.git",
            from: "2.1.1"
        ),
        .package(
            name: "SwiftyEigen",
            url: "../SwiftyEigen",
            from: "0.1.0"
        ),
        .package(
            name: "SwiftySolver",
            url: "../SwiftySolver",
            from: "1.1.0"
        ),
    ],
    targets: [
        .target(
            name: "SwiftyHomology",
            dependencies: ["SwiftyMath", "SwiftyEigen", "SwiftySolver"],
			path: "Sources/SwiftyHomology"),
        .testTarget(
            name: "SwiftyHomologyTests",
            dependencies: ["SwiftyHomology"]),
    ]
)
