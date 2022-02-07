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
import ArgumentParser
import Logging

@main
struct DriverWebService: WebService {
    @Option(help: "Port for driver service")
    var port: Int = 8082

    var configuration: Configuration {
        HTTP()
        HTTPConfiguration(bindAddress: .interface("0.0.0.0", port: port))

        LoggerConfiguration(logHandlers: StreamLogHandler.standardError, logLevel: .info)
    }

    var content: some Component {
        Group("driver") {
            FindNearestHandler()
        }
    }
}
