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
			name: "SwiftySolver",
			url: "https://github.com/taketo1024/SwiftyMath-solver.git",
			from: "1.1.0"
		),
    ],
    targets: [
        .target(
            name: "SwiftyHomology",
            dependencies: ["SwiftyMath", "SwiftySolver"],
			path: "Sources/SwiftyHomology"),
        .testTarget(
            name: "SwiftyHomologyTests",
            dependencies: ["SwiftyHomology"]),
    ]
)
