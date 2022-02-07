//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Foundation
import Models
import Utils

enum Constants {
    static let calculationDelayMean = 0.05 // 50 milliseconds
    static let calculationDelayStandardDeviation: TimeInterval = calculationDelayMean / 4
    static let etaMean: TimeInterval = 300 // 5 minutes
    static let etaStandardDeviation: TimeInterval = 180 // 3 minutes
    static let etaMinimum: TimeInterval = 120 // 2 minutes
}

struct RouteHandler: Handler {
    @Parameter var pickup: String
    @Parameter var dropoff: String

    func handle() -> Route {
        // simulate expensive calculation
        Delay.sleep(Constants.calculationDelayMean, Constants.calculationDelayStandardDeviation)

        let eta = max(Constants.etaMinimum, Double.standardNormalRandom() * Constants.etaStandardDeviation + Constants.etaMean)

        return Route(
            pickup: pickup,
            dropoff: dropoff,
            eta: eta
        )
    }
}
