//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Instrumentation
import NIOHTTP1

/// `Injector` used to inject values into `HTTPHeaders`.
///
/// - Note: Ideally, this injector would live in an external dependency.
///         Not sure if it'll ever make it into [apple/swift-nio](https://github.com/apple/swift-nio),
///         maybe something like `swift-nio-instrumentation`.
struct HTTPHeadersInjector: Injector {
    init() {}
    
    func inject(_ value: String, forKey key: String, into carrier: inout HTTPHeaders) {
        carrier.replaceOrAdd(name: key, value: value)
    }
}
