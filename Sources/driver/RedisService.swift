//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Foundation
import Logging
import Models
import Utils

enum Constants {
    static let findDelayMean: TimeInterval = 0.02 // 20 ms
    static let findDelayStandardDeviation: TimeInterval = findDelayMean / 4
    static let getDelayMean: TimeInterval = 0.01 // 10 ms
    static let getDelayStandardDeviation: TimeInterval = getDelayMean / 4
}

final class RedisService {
    private let errorSimulator = ErrorSimulator()
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func findDriverIds(location: String) -> [String] {
        // simulate Redis delay
        Delay.sleep(Constants.findDelayMean, Constants.findDelayStandardDeviation)

        let drivers = (0..<10)
            .map { _ in
                String(format: "T7%05dC", Int.random(in: 0..<100000))
            }
        logger.info("Found drivers", metadata: ["drivers": .array(drivers.map({ .string($0) }))])

        return drivers
    }

    func getDriver(driverId: String) throws -> DriverLocation {
        // simulate Redis delay
        Delay.sleep(Constants.getDelayMean, Constants.getDelayStandardDeviation)

        try errorSimulator.checkError()

        return DriverLocation(
            driverId: driverId,
            location: "\(Int.random(in: 0..<1000)),\(Int.random(in: 0..<1000))"
        )
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
            self.storage[\Application.redisService] = RedisService(logger: logger)
            return self.redisService
        }
        return redisService
    }
}
