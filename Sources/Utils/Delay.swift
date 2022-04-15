//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Namespace for the `sleep(_:_:)` function.
public enum Delay {
    /// Sleeps the thread using a normally distributed random delay with given mean and standard deviation.
    ///
    /// - Note: Passed values are in seconds.
    public static func sleep(_ mean: TimeInterval, _ standardDeviation: TimeInterval) {
        let delay = Double.standardNormalRandom() * standardDeviation + mean
        Thread.sleep(forTimeInterval: delay)
    }
}
