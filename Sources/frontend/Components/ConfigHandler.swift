//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

struct ConfigHandler: Handler {
    var jaegerUI: String

    func handle() -> ConfigResponse {
        ConfigResponse(jaeger: jaegerUI)
    }
}

struct ConfigResponse: Content {
    var jaeger: String
}
