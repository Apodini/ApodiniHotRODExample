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
struct FrontendWebService: WebService {
    @Option(help: "Port for frontend service")
    var port: Int = 8080

    @Option(name: .shortAndLong, help: "Address of Jaeger UI to create [find trace] links")
    var jaegerUI: String = "http://localhost:16686"

    @Option(name: .long, help: "Address of customer service")
    var customerService: String = "http://localhost:8081"

    @Option(name: .long, help: "Address of driver service")
    var driverService: String = "http://localhost:8082"

    @Option(name: .long, help: "Address of route service")
    var routeService: String = "http://localhost:8083"

    var configuration: Configuration {
        HTTP()
        HTTPConfiguration(bindAddress: .interface("0.0.0.0", port: port))

        TracingConfiguration(
            InstrumentConfiguration(JaegerBaggageExtractorInstrument()),
            .defaultOpenTelemetry(
                serviceName: "frontend",
                otlpHost: ProcessInfo.processInfo.environment["OTLP_HOST"],
                otlpPort: UInt(ProcessInfo.processInfo.environment["OTLP_PORT"] ?? "")
            )
        )

//        EnvironmentValue(jaegerUI, \Application.jaegerUI)
    }

    var content: some Component {
        Group("dispatch") {
            DispatchHandler()
        }
        .trace()
        Group("config") {
            ConfigHandler(jaegerUI: jaegerUI)
        }
        .trace()
        StaticFilesComponent()
        StaticFilesHandler(fileName: .constant(""))
    }
}
