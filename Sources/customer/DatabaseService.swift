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
import Tracing
import Utils

enum Constants {
    static let getDelayMean: TimeInterval = 0.3 // 300 ms
    static let getDelayStandardDeviation: TimeInterval = getDelayMean / 10
}

/// The DatabaseService simulates a Customer repository implemented on top of an SQL database.
final class DatabaseService {
    private let customers: [String: Customer] = [
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

    private let logger: Logger
    private let tracer: Tracer

    init(logger: Logger, tracer: Tracer) {
        self.logger = logger
        self.tracer = tracer
    }

    func get(customerId: String, baggage: Baggage) throws -> Customer {
        logger.info("Loading customer", metadata: ["customer_id": .string(customerId)])

        return try tracer.withSpan("SQL SELECT", baggage: baggage, ofKind: .client) { span in
            span.attributes.peer.service = "mysql"
            span.attributes.sql.query = "SELECT * FROM customer WHERE customer_id=\(customerId)"

            // simulate SQL delay
            Delay.sleep(Constants.getDelayMean, Constants.getDelayStandardDeviation)

            guard let customer = customers[customerId] else {
                throw ApodiniError(type: .notFound, reason: "invalid customer id")
            }

            return customer
        }
    }
}

// MARK: - Application

extension Application {
    var databaseService: DatabaseService {
        guard let databaseService = self.storage[\Application.databaseService] else {
            self.storage[\Application.databaseService] = DatabaseService(logger: logger, tracer: tracer)
            return self.databaseService
        }
        return databaseService
    }
}

// MARK: - Tracing

// These span attributes mimic the original HotROD example
// They don't follow the recommendations for the OpenTelemetry spec: https://github.com/open-telemetry/opentelemetry-specification/tree/main/specification/trace/semantic_conventions

extension SpanAttributes {
    var peer: PeerSpanAttributes {
        get { .init(attributes: self) }
        set { self = newValue.attributes }
    }
}

@dynamicMemberLookup
struct PeerSpanAttributes: SpanAttributeNamespace {
    struct NestedSpanAttributes: NestedSpanAttributesProtocol {
        init() {}

        var service: Key<String> {
            "peer.service"
        }
    }

    var attributes: SpanAttributes
}

extension SpanAttributes {
    var sql: SQLSpanAttributes {
        get { .init(attributes: self) }
        set { self = newValue.attributes }
    }
}

@dynamicMemberLookup
struct SQLSpanAttributes: SpanAttributeNamespace {
    struct NestedSpanAttributes: NestedSpanAttributesProtocol {
        init() {}

        var query: Key<String> {
            "sql.query"
        }
    }

    var attributes: SpanAttributes
}
