//
//  DocxDocumentExporterTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Export — hand-rolled OOXML .docx (Q-C).
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

@Suite("OOXMLDocument")
struct OOXMLDocumentTests {
    @Test func documentXMLIsWellFormed() throws {
        let xml = OOXMLDocument.documentXML(from: "# Résumé\n\n**Bold** and *italic*\n\n- one\n- two")
        // Parses as XML → structurally valid document.xml.
        _ = try XMLDocument(data: Data(xml.utf8), options: [])
    }

    @Test func headingsAndBoldBecomeBoldRuns() {
        let xml = OOXMLDocument.documentXML(from: "# Title\n\n**strong**")
        #expect(xml.contains("<w:b/>"))            // bold run property present
        #expect(xml.contains("<w:sz w:val=\"36\"/>"))  // h1 size
        #expect(xml.contains("Title"))
    }

    @Test func bulletsGetAnIndentAndBulletGlyph() {
        let xml = OOXMLDocument.documentXML(from: "- item")
        #expect(xml.contains("<w:ind w:left=\"360\""))
        #expect(xml.contains("\u{2022}"))          // • glyph
    }

    @Test func xmlSpecialCharactersAreEscaped() {
        let xml = OOXMLDocument.documentXML(from: "A & B < C > D")
        #expect(xml.contains("A &amp; B &lt; C &gt; D"))
        #expect(!xml.contains("A & B"))            // raw ampersand would be invalid XML
    }

    @Test func thematicBreakBecomesABorderNotLiteralDashes() throws {
        let xml = OOXMLDocument.documentXML(from: "Above\n\n---\n\nBelow")
        #expect(xml.contains("<w:pBdr>"))          // rendered as a bottom-border rule
        #expect(xml.contains("<w:bottom w:val=\"single\""))
        #expect(!xml.contains(">---<"))            // never emits the literal dashes as text
        _ = try XMLDocument(data: Data(xml.utf8), options: [])   // still well-formed
    }
}

@Suite("ZipArchiveWriter")
struct ZipArchiveWriterTests {
    @Test func crc32MatchesTheKnownAnswer() {
        // The canonical CRC-32 check value for "123456789".
        #expect(ZipArchiveWriter.crc32(Data("123456789".utf8)) == 0xCBF4_3926)
    }

    @Test func archiveHasZipSignaturesAndEntryNames() {
        let data = ZipArchiveWriter.archive([
            .init(path: "a.txt", data: Data("hello".utf8)),
            .init(path: "b.txt", data: Data("world".utf8)),
        ])
        #expect(data.prefix(4).elementsEqual(Data([0x50, 0x4b, 0x03, 0x04])))  // PK\x03\x04 local header
        #expect(contains(data, Data([0x50, 0x4b, 0x05, 0x06])))               // PK\x05\x06 EOCD
        #expect(contains(data, Data("a.txt".utf8)))
        #expect(contains(data, Data("b.txt".utf8)))
    }

    private func contains(_ haystack: Data, _ needle: Data) -> Bool {
        haystack.range(of: needle) != nil
    }
}

@Suite("DocxDocumentExporter")
struct DocxDocumentExporterTests {
    private let exporter = DocxDocumentExporter()
    private let sample = "# Résumé\n\n**Senior** iOS Engineer\n\n- Swift\n- SwiftUI"

    @Test func producesAZipPackageWithTheRequiredParts() throws {
        let data = try exporter.export(markdown: sample, as: .docx)
        #expect(data.prefix(4).elementsEqual(Data([0x50, 0x4b, 0x03, 0x04])))  // it's a zip
        // The four minimal OOXML parts are present by name.
        for part in ["[Content_Types].xml", "_rels/.rels", "word/document.xml", "word/_rels/document.xml.rels"] {
            #expect(data.range(of: Data(part.utf8)) != nil, "missing part \(part)")
        }
    }

    @Test func rejectsNonDocxFormats() {
        #expect(throws: ExportError.unsupportedFormat(.pdf)) {
            _ = try exporter.export(markdown: "x", as: .pdf)
        }
    }

    /// Reads `word/document.xml` back out of the archive by parsing the ZIP central
    /// directory + local header — proving the offsets/sizes are internally consistent
    /// (not just that the signatures exist), then that the extracted part is valid XML.
    @Test func documentPartRoundTripsOutOfTheArchive() throws {
        let archive = [UInt8](try exporter.export(markdown: sample, as: .docx))
        let extracted = try #require(storedEntry(named: "word/document.xml", in: archive))
        let xml = String(decoding: extracted, as: UTF8.self)
        #expect(xml == OOXMLDocument.documentXML(from: sample))   // byte-identical to the source part
        _ = try XMLDocument(data: extracted, options: [])          // and still well-formed XML
    }

    // MARK: Minimal STORED-zip reader (test-only)

    private func storedEntry(named name: String, in bytes: [UInt8]) -> Data? {
        func le16(_ i: Int) -> Int { Int(bytes[i]) | (Int(bytes[i + 1]) << 8) }
        func le32(_ i: Int) -> Int {
            Int(bytes[i]) | (Int(bytes[i + 1]) << 8) | (Int(bytes[i + 2]) << 16) | (Int(bytes[i + 3]) << 24)
        }
        // Locate the End Of Central Directory record (PK\x05\x06), scanning from the end.
        var eocd = bytes.count - 22
        while eocd >= 0, !(bytes[eocd] == 0x50 && bytes[eocd + 1] == 0x4b && bytes[eocd + 2] == 0x05 && bytes[eocd + 3] == 0x06) {
            eocd -= 1
        }
        guard eocd >= 0 else { return nil }

        let entryCount = le16(eocd + 10)
        var p = le32(eocd + 16)   // start of central directory
        for _ in 0..<entryCount {
            guard le32(p) == 0x0201_4b50 else { return nil }   // central header signature
            let nameLen = le16(p + 28), extraLen = le16(p + 30), commentLen = le16(p + 32)
            let localOffset = le32(p + 42)
            let entryName = String(decoding: bytes[(p + 46)..<(p + 46 + nameLen)], as: UTF8.self)
            if entryName == name {
                let lNameLen = le16(localOffset + 26), lExtraLen = le16(localOffset + 28)
                let compSize = le32(localOffset + 18)
                let dataStart = localOffset + 30 + lNameLen + lExtraLen
                return Data(bytes[dataStart..<(dataStart + compSize)])
            }
            p += 46 + nameLen + extraLen + commentLen
        }
        return nil
    }
}
