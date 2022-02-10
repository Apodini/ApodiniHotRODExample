//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniObserve
import Models
import Tracing

struct FindNearestHandler: Handler {
    @Parameter var location: String

    @Environment(\.redisService)
    var redisService

    @Throws(.serverError)
    var internalServerError

    @ApodiniLogger
    var logger

    @EnvironmentObject
    var span: Span

    func handle() throws -> FindNearestResponse {
        logger.info("Searching for nearby drivers", metadata: ["location": .string(location)])
        let driverIds = redisService.findDriverIds(location: location, baggage: span.baggage)

        let result = try driverIds
            .compactMap { driverId -> DriverLocation? in
                var result: Result<DriverLocation, Error>?
                for i in 0..<3 {
                    do {
                        let driver = try redisService.getDriver(driverId: driverId, baggage: span.baggage)
                        result = .success(driver)
                        break
                    } catch {
                        result = .failure(error)
                        logger.error("Retrying GetDriver after error", metadata: ["retry_no": .stringConvertible(i + 1)])
                    }
                }

                guard let result = result else { throw internalServerError }

                switch result {
                case let .failure(error):
                    logger.error("Failed to get driver after 3 attempts")
                    span.recordError(error)
                    span.setStatus(.init(code: .error, message: error.standardMessage))
                    return nil
                case let .success(driver):
                    return driver
                }
            }

        logger.info("Search successful", metadata: ["num_drivers": .stringConvertible(result.count)])
        return FindNearestResponse(locations: result)
    }
}

struct FindNearestResponse: Content {
    var locations: [DriverLocation]
}
