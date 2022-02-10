//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import AsyncHTTPClient
import NIOHTTP1
import Tracing

// Ideally, these extensions would live in an external dependency.
// Not sure if they'll ever make it into [apple/swift-nio](https://github.com/apple/swift-nio)
// and [swift-server/async-http-client](https://github.com/swift-server/async-http-client).

// MARK: - Span Attributes

extension SpanAttributes {
    var http: HTTPAttributes {
        get {
            .init(attributes: self)
        }
        set {
            self = newValue.attributes
        }
    }
}

@dynamicMemberLookup
struct HTTPAttributes: SpanAttributeNamespace {
    var attributes: SpanAttributes

    init(attributes: SpanAttributes) {
        self.attributes = attributes
    }

    struct NestedSpanAttributes: NestedSpanAttributesProtocol {
        init() {}

        var method: Key<String> { "http.method" }
        var url: Key<String> { "http.url" }
        var requestContentLength: Key<Int> { "http.request_content_length" }
        var statusCode: Key<Int> { "http.status_code" }
        var statusText: Key<String> { "http.status_text" }
        var responseContentLength: Key<Int> { "http.response_content_length" }
    }
}

// MARK: - Span Status

extension SpanStatus {
    init(responseStatus: HTTPResponseStatus) {
        switch responseStatus.code {
        case 100...399:
            self = SpanStatus(code: .ok)
        default:
            self = SpanStatus(code: .error, message: responseStatus.reasonPhrase)
        }
    }
}
