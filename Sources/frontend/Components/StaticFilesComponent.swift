//
// This source file is part of the Apodini HotROD example open source project
//
// SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniNetworking
import Foundation

struct StaticFilesComponent: Component {
    @PathParameter
    var fileName: String

    var content: some Component {
        Group($fileName) {
            StaticFilesHandler(fileName: $fileName)
        }
    }
}

struct StaticFilesHandler: Handler {
    @Binding
    var fileName: String

    @Throws(.notFound)
    var notFound

    @Throws(.serverError, reason: "unsupported file type")
    var unsupportedFileType

    func handle() throws -> Blob {
        let fileName = fileName.isEmpty ? "index.html" : fileName

        guard fileName == "index.html" || fileName == "jquery-3.1.1.min.js" else {
            throw notFound
        }
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "") else {
            throw notFound
        }
        guard let content = try? Data(contentsOf: url) else {
            throw notFound
        }

        let mimeType: HTTPMediaType
        switch URL(fileURLWithPath: fileName).pathExtension {
        case "html":
            mimeType = .html
        case "js":
            mimeType = HTTPMediaType(type: "application", subtype: "javascript")
        default:
            throw unsupportedFileType
        }

        return Blob(content, type: mimeType)
    }
}
