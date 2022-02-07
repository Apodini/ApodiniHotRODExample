//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

struct DispatchHandler: Handler {
    @Parameter var customer: String

    @Environment(\.bestETAService)
    var bestETAService

    func handle() async throws -> ETAResponse {
        let etaResponse = try await bestETAService.get(customerId: customer)
        return etaResponse
    }
}
