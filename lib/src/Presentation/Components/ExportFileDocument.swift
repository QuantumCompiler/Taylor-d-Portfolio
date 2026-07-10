//
//  ExportFileDocument.swift
//  Taylor'd Portfolio
//
//  Presentation · Components — a tiny FileDocument wrapping exported bytes for .fileExporter.
//

import SwiftUI
import UniformTypeIdentifiers

/// Wraps already-rendered export bytes so SwiftUI's `.fileExporter` can write them. The
/// bytes come from `ExportApplicationUseCase` (via the ViewModel); this type only carries
/// them to the save panel — it does no rendering itself.
struct ExportFileDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.plainText, .pdf, .data]

    var data: Data
    var contentType: UTType

    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        contentType = .data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
