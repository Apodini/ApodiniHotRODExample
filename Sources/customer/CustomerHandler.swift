//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Models
import Tracing

struct CustomerHandler: Handler {
    @Parameter var customer: String

    @Environment(\.databaseService)
    var databaseService

    @EnvironmentObject
    var span: Span

    func handle() throws -> Customer {
        let customer = try databaseService.get(customerId: customer, baggage: span.baggage)
        return customer
    }
}
