//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniObserve
import ApodiniOpenAPI
import ApodiniREST
import ArgumentParser
import Logging
import OpenTelemetry
import OtlpGRPCSpanExporting


@main
struct ExampleWebService: WebService {
    @Option(help: "The port the web service is offered at")
    var port: Int = 80
    
    
    var configuration: Configuration {
        HTTPConfiguration(port: port)
        REST {
            OpenAPI()
        }

        TracingConfiguration(
            // Export to OpenTelemetry collector via gRPC and the OpenTelemetry protocol (OTLP)
            .defaultOpenTelemetry,

            // Expose configuration options from opentelemetry-swift
            .openTelemetryWithConfig(
                resourceDetection: .automatic(additionalDetectors: []),
                idGenerator: OTel.RandomIDGenerator(),
                sampler: OTel.ConstantSampler(isOn: true),
                processor: { group in
                    OTel.SimpleSpanProcessor(
                        exportingTo: OtlpGRPCSpanExporter(config: .init(eventLoopGroup: group))
                    )
                },
                propagator: OTel.W3CPropagator(),
                logger: Logger(label: "ApodiniOTel")
            )

            // Any other instrument conforming to swift-distributed-tracing's `Instrument`
            // InstrumentConfiguration(MyAwesomeInstrument())
        )
    }
    
    var content: some Component {
        Greeter()
    }
}
