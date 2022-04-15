//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public struct Customer: Content, Decodable {
    public var id: String
    public var name: String
    public var location: String

    public init(id: String, name: String, location: String) {
        self.id = id
        self.name = name
        self.location = location
    }
}
