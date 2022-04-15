//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniHTTP
import ApodiniObserve
import ApodiniObserveOpenTelemetry
import ArgumentParser
import Foundation

@main
struct CustomerWebService: WebService {
    @Option(help: "Port for customer service")
    var port: Int = 8081

    var configuration: Configuration {
        HTTP()
        HTTPConfiguration(bindAddress: .interface("0.0.0.0", port: port))

        TracingConfiguration(
            InstrumentConfiguration(JaegerBaggageExtractorInstrument()),
            .defaultOpenTelemetry(
                serviceName: "customer",
                otlpHost: ProcessInfo.processInfo.environment["OTLP_HOST"],
                otlpPort: UInt(ProcessInfo.processInfo.environment["OTLP_PORT"] ?? "")
            )
        )
    }

    var content: some Component {
        Group("customer") {
            CustomerHandler()
        }
        .trace()
    }
}
