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
    static let getDelayMean: TimeInterval = 0.3 // 300 ms
    static let getDelayStandardDeviation: TimeInterval = getDelayMean / 10
}

fileprivate let customers: [String: Customer] = [
    "123": Customer(
        id: "123",
        name: "Rachel's Floral Designs",
        location: "115,277"
    ),
    "567": Customer(
        id: "567",
        name: "Amazing Coffee Roasters",
        location: "211,653"
    ),
    "392": Customer(
        id: "392",
        name: "Trom Chocolatier",
        location: "577,322"
    ),
    "731": Customer(
        id: "731",
        name: "Japanese Desserts",
        location: "728,326"
    )
]

/// The DatabaseService simulates a Customer repository implemented on top of an SQL database.
final class DatabaseService {
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func get(customerId: String) throws -> Customer {
        logger.info("Loading customer", metadata: ["customer_id": .string(customerId)])

        // TODO: Simulate SQL Span

        // simulate SQL delay
        Delay.sleep(Constants.getDelayMean, Constants.getDelayStandardDeviation)

        guard let customer = customers[customerId] else {
            throw ApodiniError(type: .notFound, reason: "invalid customer id")
        }

        return customer
    }
}

extension Application {
    var databaseService: DatabaseService {
        guard let databaseService = self.storage[\Application.databaseService] else {
            self.storage[\Application.databaseService] = DatabaseService(logger: logger)
            return self.databaseService
        }
        return databaseService
    }
}
