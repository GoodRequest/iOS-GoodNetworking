// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoodNetworking",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GoodNetworking",
            targets: ["GoodNetworking"]
        ),
        .library(
            name: "Mockable",
            targets: ["Mockable"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.9.1")),
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", .upToNextMajor(from: "4.2.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GoodNetworking",
            dependencies: [
                .target(name: "GoodNetworkingAlamofire")
            ],
            path: "./Sources/GoodNetworking",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "GoodNetworkingAlamofire",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "AlamofireImage", package: "AlamofireImage")
            ],
            path: "./Sources/GoodNetworkingAlamofire",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "Mockable",
            dependencies: ["GoodNetworking"],
            path: "./Sources/Mockable",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GoodNetworkingTests",
            dependencies: ["GoodNetworking", "Mockable"],
            resources:
                [
                    .copy("Resources/EmptyElement.json"),
                    .copy("Resources/ArrayNil.json"),
                    .copy("Resources/IsoDate.json"),
                    .copy("Resources/MilisecondsDate.json")
                ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
