//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniAsyncHTTPClient
import Foundation
import Logging
import Models

final class BestETAService {
    private let httpClient: HTTPClient
    private let logger: Logger

    init(httpClient: HTTPClient, logger: Logger) {
        self.httpClient = httpClient
        self.logger = logger
    }

    func get(customerId: String) async throws -> ETAResponse {
        let customer = try await getCustomer(customerId: customerId)
        logger.info("Found customer", metadata: ["customer": .string(customer.name)])

        // TODO: Set customer to span

        let drivers = try await getNearestDrivers(location: customer.location)
        logger.info("Found drivers", metadata: ["drivers": .array(drivers.map({ .string($0.driverId) }))])

        let results = try await getRoutes(customer: customer, drivers: drivers)
        logger.info("Found routes", metadata: ["routes": .array(results.map({ .stringConvertible($0.route.eta) }))])

        guard let response = results.sorted(by: \.route.eta).first else {
            throw ApodiniError(type: .serverError, reason: "no routes found")
        }

        logger.info("Dispatch successful", metadata: ["driver": .string(response.driver), "eta": .stringConvertible(response.route.eta)])

        return ETAResponse(
            eta: Int(response.route.eta * 1000000 * 1000), // frontend expects nanoseconds
            driver: response.driver
        )
    }
}

struct ETAResponse: Content {
    var eta: Int
    var driver: String

    enum CodingKeys: String, CodingKey {
        case eta = "ETA"
        case driver = "Driver"
    }
}

extension BestETAService {
    private func getCustomer(customerId: String) async throws -> Customer {
        try await httpClient
            .get(url: "http://0.0.0.0:8081/customer?customer=\(customerId)")
            .flatMapThrowing { response -> Customer in
//                span.set(Int(response.status.code), forKey: "status-code")
                guard (200..<300).contains(response.status.code) else {
                    throw ApodiniError(type: .notFound, reason: "\(response.status)")
                }
                guard let body = response.body else {
                    throw ApodiniError(type: .notFound, reason: "Response was empty")
                }
//                span.set(Data(buffer: body), forKey: "body")
                return try JSONDecoder().decode(Customer.self, from: body)
            }
            .get()
    }
}

extension BestETAService {
    private func getNearestDrivers(location: String) async throws -> [DriverLocation] {
        struct FindNearestResponse: Decodable {
            var locations: [DriverLocation]
        }

        return try await httpClient
            .get(url: "http://0.0.0.0:8082/driver?location=\(location)")
            .flatMapThrowing { response -> [DriverLocation] in
//                span.set(Int(response.status.code), forKey: "status-code")
                guard (200..<300).contains(response.status.code) else {
                    throw ApodiniError(type: .notFound, reason: "\(response.status)")
                }
                guard let body = response.body else {
                    throw ApodiniError(type: .notFound, reason: "Response was empty")
                }
//                span.set(Data(buffer: body), forKey: "body")
                return try JSONDecoder().decode(FindNearestResponse.self, from: body).locations
            }
            .get()
    }
}

extension BestETAService {
    private func getRoutes(customer: Customer, drivers: [DriverLocation]) async throws -> [RouteResult] {
        let futures = drivers
            .map { driver in
                getRoute(pickup: driver.location, dropoff: customer.location)
                    .map { RouteResult(driver: driver.driverId, route: $0) }
                    .inspectFailure { error in
                        self.logger.error(
                            "Failed to get route",
                            metadata: [
                                "driver_id": .string(driver.driverId),
                                "customer_id": .string(customer.id),
                                "error": .string(String(describing: error))
                            ]
                        )
                    }
            }

        return try await EventLoopFuture<RouteResult>
            .whenAllComplete(futures, on: httpClient.eventLoopGroup.next())
            .map { results -> [RouteResult] in
                results.compactMap { result -> RouteResult? in
                    // somehow we always get one failure with a connection closed by peer error
                    // ignore it for now
                    guard case let .success(routeResult) = result else { return nil }
                    return routeResult
                }
            }
//            .whenAllSucceed(futures, on: httpClient.eventLoopGroup.next())
            .get()
    }

    private func getRoute(pickup: String, dropoff: String) -> EventLoopFuture<Route> {
        httpClient
            .get(url: "http://0.0.0.0:8083/route?pickup=\(pickup)&dropoff=\(dropoff)")
            .flatMapThrowing { response -> Route in
//                span.set(Int(response.status.code), forKey: "status-code")
                self.logger.info("Route response", metadata: ["status_code": .stringConvertible(response.status.code)])
                guard (200..<300).contains(response.status.code) else {
                    throw ApodiniError(type: .notFound, reason: "\(response.status)")
                }
                guard let body = response.body else {
                    throw ApodiniError(type: .notFound, reason: "Response was empty")
                }
//                span.set(Data(buffer: body), forKey: "body")
                return try JSONDecoder().decode(Route.self, from: body)
            }
    }

    struct RouteResult: Content {
        var driver: String
        var route: Route
    }
}

extension Application {
    var bestETAService: BestETAService {
        guard let bestETAService = self.storage[\Application.bestETAService] else {
            self.storage[\Application.bestETAService] = BestETAService(httpClient: httpClient, logger: logger)
            return self.bestETAService
        }
        return bestETAService
    }
}
