// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swm-homology",
    products: [
        .library(
            name: "SwmHomology",
            targets: ["SwmHomology"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/taketo1024/swm-core.git",
            from: "1.2.3"
//            path: "../swm-core/"
        ),
        .package(
            url: "https://github.com/taketo1024/swm-matrix-tools.git",
            from: "1.1.3"
//            path: "../swm-matrix-tools/"
        ),
        .package(
            url: "https://github.com/taketo1024/swm-eigen.git",
            from: "0.2.1"
//            path: "../swm-eigen/"
        )
    ],
    targets: [
        .target(
            name: "SwmHomology",
            dependencies: [
                .product(name: "SwmCore", package: "swm-core"),
                .product(name: "SwmMatrixTools", package: "swm-matrix-tools"),
                .product(name: "SwmEigen", package: "swm-eigen", condition: .when(platforms: [.macOS])),
            ],
            swiftSettings: [
                .define("USE_EIGEN")
            ]
        ),
        .testTarget(
            name: "SwmHomologyTests",
            dependencies: ["SwmHomology"]
        ),
    ]
)
