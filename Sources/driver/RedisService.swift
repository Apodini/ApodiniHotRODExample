//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniObserve
import Foundation
import Logging
import Models
import Tracing
import Utils

enum Constants {
    static let findDelayMean: TimeInterval = 0.02 // 20 ms
    static let findDelayStandardDeviation: TimeInterval = findDelayMean / 4
    static let getDelayMean: TimeInterval = 0.01 // 10 ms
    static let getDelayStandardDeviation: TimeInterval = getDelayMean / 4
}

/// A simulator of a remote Redis cache.
final class RedisService {
    private let errorSimulator = ErrorSimulator()
    private let logger: Logger
    private let tracer: Tracer

    init(logger: Logger, tracer: Tracer) {
        self.logger = logger
        self.tracer = tracer
    }

    func findDriverIds(location: String, baggage: Baggage) -> [String] {
        tracer.withSpan("FindDriverIDs", baggage: baggage, ofKind: .client) { span in
            span.attributes["param.location"] = location

            // simulate Redis delay
            Delay.sleep(Constants.findDelayMean, Constants.findDelayStandardDeviation)

            let drivers = (0..<10)
                .map { _ in
                    String(format: "T7%05dC", Int.random(in: 0..<100000))
                }
            logger.info("Found drivers", metadata: ["drivers": .array(drivers.map({ .string($0) }))])

            return drivers
        }
    }

    func getDriver(driverId: String, baggage: Baggage) throws -> DriverLocation {
        try tracer.withSpan("GetDriver", baggage: baggage, ofKind: .client) { span in
            span.attributes["peer.service"] = "redis"
            span.attributes["param.driverID"] = driverId

            // simulate Redis delay
            Delay.sleep(Constants.getDelayMean, Constants.getDelayStandardDeviation)

            do {
                try errorSimulator.checkError()
            } catch {
                span.setStatus(.init(code: .error, message: error.standardMessage))
                throw error
            }

            return DriverLocation(
                driverId: driverId,
                location: "\(Int.random(in: 0..<1000)),\(Int.random(in: 0..<1000))"
            )
        }
    }
}

final class ErrorSimulator {
    private let lock = NSLock()
    private var countTilError = 0

    func checkError() throws {
        lock.lock()
        countTilError -= 1
        if countTilError > 0 {
            lock.unlock()
            return
        }

        countTilError = 5
        lock.unlock()

        // add more delay for "timeout"
        Delay.sleep(2 * Constants.getDelayMean, 0)

        throw ApodiniError(type: .serverError, reason: "redis timeout")
    }
}

extension Application {
    var redisService: RedisService {
        guard let redisService = self.storage[\Application.redisService] else {
            self.storage[\Application.redisService] = RedisService(logger: logger, tracer: tracer)
            return self.redisService
        }
        return redisService
    }
}
