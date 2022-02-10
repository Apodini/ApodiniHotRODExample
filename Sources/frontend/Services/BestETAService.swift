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
import Tracing

final class BestETAService {
    private let httpClient: HTTPClient
    private let logger: Logger
    private let instrument: Instrument
    private let tracer: Tracer

    private let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()

    init(
        httpClient: HTTPClient,
        logger: Logger,
        tracer: Tracer,
        instrument: Instrument
    ) {
        self.httpClient = httpClient
        self.logger = logger
        self.instrument = instrument
        self.tracer = tracer
    }

    func get(customerId: String, span: Span) async throws -> ETAResponse {
        let customer = try await getCustomer(customerId: customerId, baggage: span.baggage)
        logger.info("Found customer", metadata: ["customer": .string(customer.name)])

        // can't set add the customer to the baggage because it's read-only in swift-distributed-tracing
        let drivers = try await getNearestDrivers(location: customer.location, baggage: span.baggage)
        logger.info("Found drivers", metadata: ["drivers": .array(drivers.map({ .string($0.driverId) }))])

        let results = try await getRoutes(customer: customer, drivers: drivers, baggage: span.baggage)
        logger.info("Found routes", metadata: ["routes": .array(results.map({ .stringConvertible($0.route.eta) }))])

        guard let response = results.min(by: \.route.eta) else {
            throw ApodiniError(type: .serverError, reason: "no routes found")
        }

        logger.info("Dispatch successful", metadata: ["driver": .string(response.driver), "eta": .string(format(timeInterval: response.route.eta))])

        // manually record span event
        // in the example, logs are automatically recorded as span events
        span.addEvent(.init(
            name: "Dispatch successful",
            attributes: [
                "driver": .string(response.driver),
                "eta": .string(format(timeInterval: response.route.eta))
            ]
        ))

        return ETAResponse(
            eta: Int(response.route.eta * 1000000 * 1000), // frontend expects nanoseconds
            driver: response.driver
        )
    }
}

struct ETAResponse: Content {
    enum CodingKeys: String, CodingKey {
        case eta = "ETA"
        case driver = "Driver"
    }

    var eta: Int
    var driver: String
}

extension BestETAService {
    private func getCustomer(customerId: String, baggage: Baggage) async throws -> Customer {
        try await getRequest(to: "http://0.0.0.0:8081/customer?customer=\(customerId)", baggage: baggage)
            .flatMapThrowing { response -> Customer in
                guard (200..<300).contains(response.status.code) else {
                    throw ApodiniError(type: .notFound, reason: "\(response.status)")
                }
                guard let body = response.body else {
                    throw ApodiniError(type: .notFound, reason: "Response was empty")
                }
                return try JSONDecoder().decode(Customer.self, from: body)
            }
            .get()
    }
}

extension BestETAService {
    private func getNearestDrivers(location: String, baggage: Baggage) async throws -> [DriverLocation] {
        struct FindNearestResponse: Decodable {
            var locations: [DriverLocation]
        }

        return try await getRequest(to: "http://0.0.0.0:8082/driver?location=\(location)", baggage: baggage)
            .flatMapThrowing { response -> [DriverLocation] in
                guard (200..<300).contains(response.status.code) else {
                    throw ApodiniError(type: .notFound, reason: "\(response.status)")
                }
                guard let body = response.body else {
                    throw ApodiniError(type: .notFound, reason: "Response was empty")
                }
                return try JSONDecoder().decode(FindNearestResponse.self, from: body).locations
            }
            .get()
    }
}

extension BestETAService {
    struct RouteResult: Content {
        var driver: String
        var route: Route
    }

    private func getRoutes(customer: Customer, drivers: [DriverLocation], baggage: Baggage) async throws -> [RouteResult] {
        let futures = try drivers
            .map { driver in
                try getRoute(pickup: driver.location, dropoff: customer.location, baggage: baggage)
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
                    guard case let .success(routeResult) = result else {
                        return nil
                    }
                    return routeResult
                }
            }
            // .whenAllSucceed(futures, on: httpClient.eventLoopGroup.next())
            .get()
    }

    private func getRoute(pickup: String, dropoff: String, baggage: Baggage) throws -> EventLoopFuture<Route> {
        try getRequest(to: "http://0.0.0.0:8083/route?pickup=\(pickup)&dropoff=\(dropoff)", baggage: baggage)
            .flatMapThrowing { response -> Route in
                self.logger.info("Route response", metadata: ["status_code": .stringConvertible(response.status.code)])
                guard (200..<300).contains(response.status.code) else {
                    throw ApodiniError(type: .notFound, reason: "\(response.status)")
                }
                guard let body = response.body else {
                    throw ApodiniError(type: .notFound, reason: "Response was empty")
                }
                return try JSONDecoder().decode(Route.self, from: body)
            }
    }
}

extension BestETAService {
    func getRequest(to url: String, baggage: Baggage) throws -> EventLoopFuture<HTTPClient.Response> {
        var request = try HTTPClient.Request(url: url)

        let span = tracer.startSpan("HTTP \(request.method.rawValue)", baggage: baggage, ofKind: .client)
        span.attributes["component"] = "AsyncHTTPClient"
        span.attributes.http.method = request.method.rawValue
        span.attributes.http.url = request.url.absoluteString
        instrument.inject(span.baggage, into: &request.headers, using: HTTPHeadersInjector())

        return httpClient
            .execute(request: request)
            .always { result in
                switch result {
                case let .success(response):
                    span.setStatus(.init(responseStatus: response.status))
                    span.attributes.http.statusCode = Int(response.status.code)
                    span.attributes.http.statusText = response.status.reasonPhrase
                    span.attributes.http.responseContentLength = response.body?.readableBytes ?? 0
                case let .failure(error):
                    span.recordError(error)
                    span.setStatus(.init(code: .error, message: error.localizedDescription))
                }
                span.end()
            }
    }
}

extension BestETAService {
    func format(timeInterval: TimeInterval) -> String {
        formatter.string(from: timeInterval) ?? "n/a"
    }
}

extension Application {
    var bestETAService: BestETAService {
        guard let bestETAService = self.storage[\Application.bestETAService] else {
            self.storage[\Application.bestETAService] = BestETAService(httpClient: httpClient, logger: logger, tracer: tracer, instrument: instrument)
            return self.bestETAService
        }
        return bestETAService
    }
}
