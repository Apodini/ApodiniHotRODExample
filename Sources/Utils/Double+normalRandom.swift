//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension Double {
    /// Standard normally distributed random number.
    ///
    /// Generated from a uniform distributed using the Box-Muller transformation.
    ///
    /// - Source: https://stackoverflow.com/a/218600/2657815
    public static func standardNormalRandom() -> Double {
        /// Uniformly distributed random number in (0, 1].
        func uniformRandom() -> Double {
            Double.random(in: 0.nextUp...1)
        }

        let u1 = 1.0 - uniformRandom() // swiftlint:disable:this identifier_name
        let u2 = 1.0 - uniformRandom() // swiftlint:disable:this identifier_name
        return abs(sqrt(-2 * log(u1)) * sin(2 * .pi * u2))
    }
}
