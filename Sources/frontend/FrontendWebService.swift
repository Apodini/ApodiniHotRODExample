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

@main
struct FrontendWebService: WebService {
    @Option(help: "Port for frontend service")
    var port: Int = 8080

    @Option(name: .shortAndLong, help: "Address of Jaeger UI to create [find trace] links")
    var jaegerUI: String = "http://localhost:16686"

    var configuration: Configuration {
        HTTP()
        HTTPConfiguration(bindAddress: .interface("0.0.0.0", port: port))

        TracingConfiguration(
            InstrumentConfiguration(JaegerBaggageExtractorInstrument()),
            .defaultOpenTelemetry(serviceName: "frontend")
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


