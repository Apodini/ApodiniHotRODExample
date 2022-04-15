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
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "frontend",
            targets: ["frontend"]
        ),
        .executable(
            name: "customer",
            targets: ["customer"]
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
        .package(url: "https://github.com/Apodini/Apodini.git", .upToNextMinor(from: "0.9.2")),
        .package(url: "https://github.com/Apodini/ApodiniAsyncHTTPClient.git", .upToNextMinor(from: "0.3.4"))
    ],
    targets: [
        .executableTarget(
            name: "frontend",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniHTTP", package: "Apodini"),
                .product(name: "ApodiniObserve", package: "Apodini"),
                .product(name: "ApodiniObserveOpenTelemetry", package: "Apodini"),
                .product(name: "ApodiniAsyncHTTPClient", package: "ApodiniAsyncHTTPClient"),
                .target(name: "Models")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "customer",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniHTTP", package: "Apodini"),
                .product(name: "ApodiniObserve", package: "Apodini"),
                .product(name: "ApodiniObserveOpenTelemetry", package: "Apodini"),
                .target(name: "Models"),
                .target(name: "Utils")
            ]
        ),
        .executableTarget(
            name: "driver",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniHTTP", package: "Apodini"),
                .product(name: "ApodiniObserve", package: "Apodini"),
                .product(name: "ApodiniObserveOpenTelemetry", package: "Apodini"),
                .target(name: "Models"),
                .target(name: "Utils")
            ]
        ),
        .executableTarget(
            name: "route",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniHTTP", package: "Apodini"),
                .product(name: "ApodiniObserve", package: "Apodini"),
                .product(name: "ApodiniObserveOpenTelemetry", package: "Apodini"),
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
