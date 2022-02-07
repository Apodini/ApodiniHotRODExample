// swift-tools-version:5.5

//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "ApodiniHotRODExample",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "WebService",
            targets: ["WebService"]
        ),
        .executable(
            name: "driver",
            targets: ["driver"]
        ),
        .executable(
            name: "route",
            targets: ["route"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Apodini/Apodini.git", branch: "feature/tracing")
    ],
    targets: [
        .executableTarget(
            name: "WebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniOpenAPI", package: "Apodini"),
                .product(name: "ApodiniObserve", package: "Apodini")
            ]
        ),
        .testTarget(
            name: "WebServiceTests",
            dependencies: [
                .target(name: "WebService")
            ]
        ),
        .executableTarget(
            name: "driver",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniHTTP", package: "Apodini"),
                .product(name: "ApodiniObserve", package: "Apodini"),
                .target(name: "Models"),
                .target(name: "Utils")
            ]
        ),
        .executableTarget(
            name: "route",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniHTTP", package: "Apodini"),
                .target(name: "Models"),
                .target(name: "Utils")
            ]
        ),

        .target(
            name: "Models",
            dependencies: [
                .product(name: "Apodini", package: "Apodini")
            ]
        ),
        .target(name: "Utils")
    ]
)
