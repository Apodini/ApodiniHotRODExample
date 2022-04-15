//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public struct DriverLocation: Content, Decodable {
    public var driverId: String
    public var location: String

    public init(driverId: String, location: String) {
        self.driverId = driverId
        self.location = location
    }
}
