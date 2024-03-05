// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoodNetworking",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GoodNetworking-iOS",
            targets: ["GoodNetworking"]
        ),
        .library(
            name: "GoodNetworking-Shared-iOS",
            targets: ["GoodNetworking_Shared"]
        ),
        .library(
            name: "Mockable-iOS",
            targets: ["Mockable"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.2.0")),
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", .upToNextMajor(from: "4.2.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GoodNetworking",
            dependencies: [
                .target(name: "GoodNetworking_Shared"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "AlamofireImage", package: "AlamofireImage")
            ],
            path: "./Sources/GoodNetworking"
        ),
        .target(
            name: "GoodNetworking_Shared",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "./Sources/GoodNetworking-Shared"
        ),
        .target(
            name: "Mockable",
            dependencies: [
                .target(name: "GoodNetworking"),
                .target(name: "GoodNetworking_Shared")
            ],
            path: "./Sources/Mockable"
        ),
        .testTarget(
            name: "GoodNetworkingTests",
            dependencies: [
                .target(name: "GoodNetworking"),
                .target(name: "Mockable")
            ],
            resources: [
                .copy("Resources/EmptyElement.json"),
                .copy("Resources/ArrayNil.json"),
                .copy("Resources/IsoDate.json"),
                .copy("Resources/MilisecondsDate.json")
            ]
        ),
    ]
)
