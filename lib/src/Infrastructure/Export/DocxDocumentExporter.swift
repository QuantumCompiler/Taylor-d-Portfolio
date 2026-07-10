//
//  DocxDocumentExporter.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Export — hand-rolled minimal OOXML (.docx) exporter (Q-C).
//

import Foundation

/// A ``DocumentExporter`` that writes a true Word `.docx` — a zipped OOXML package assembled
/// by hand, since macOS has no native `.docx` writer. Builds the four minimal parts a valid
/// document needs, maps the Markdown to `word/document.xml` (``OOXMLDocument``), and packages
/// them with ``ZipArchiveWriter``. Only `.docx` is handled; other formats throw.
nonisolated struct DocxDocumentExporter: DocumentExporter {
    nonisolated func export(markdown: String, as format: ExportFormat) throws -> Data {
        guard format == .docx else { throw ExportError.unsupportedFormat(format) }
        let entries: [ZipArchiveWriter.Entry] = [
            .init(path: "[Content_Types].xml", data: Data(Self.contentTypes.utf8)),
            .init(path: "_rels/.rels", data: Data(Self.rootRelationships.utf8)),
            .init(path: "word/document.xml", data: Data(OOXMLDocument.documentXML(from: markdown).utf8)),
            .init(path: "word/_rels/document.xml.rels", data: Data(Self.documentRelationships.utf8)),
        ]
        return ZipArchiveWriter.archive(entries)
    }

    // MARK: Static package parts

    private static let contentTypes = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\
    <Default Extension="xml" ContentType="application/xml"/>\
    <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>\
    </Types>
    """

    private static let rootRelationships = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>\
    </Relationships>
    """

    private static let documentRelationships = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"></Relationships>
    """
}
