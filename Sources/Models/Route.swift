//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public struct Route: Content, Decodable {
    public var pickup: String
    public var dropoff: String
    public var eta: Double

    public init(pickup: String, dropoff: String, eta: Double) {
        self.pickup = pickup
        self.dropoff = dropoff
        self.eta = eta
    }
}
