//
//  OOXMLDocument.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Export — map the assembled Markdown to word/document.xml (OOXML).
//

import Foundation

/// Builds the `word/document.xml` part of a `.docx` from Markdown. Uses **direct run
/// formatting** (bold + font size) rather than referencing a `styles.xml`, so the package
/// stays minimal (Q-C). Fidelity is the subset the résumé / cover letter use: heading levels
/// (bold + larger size), bullet lists (a literal bullet + indent, no `numbering.xml`), and
/// inline **bold** / *italic*. Everything is XML-escaped.
nonisolated enum OOXMLDocument {
    /// Sizes are in half-points (OOXML `w:sz`). 22 = 11pt body.
    private static let bodyHalfPoints = 22

    static func documentXML(from markdown: String) -> String {
        var body = ""
        for block in MarkdownBlockParser.blocks(from: markdown) {
            switch block {
            case .blank:
                body += "<w:p/>"
            case .heading(let level, let text):
                let size = level <= 1 ? 36 : (level == 2 ? 28 : 24)
                body += paragraph(text: text, headingBold: true, sizeHalfPoints: size, bullet: false)
            case .bullet(let text):
                body += paragraph(text: text, headingBold: false, sizeHalfPoints: bodyHalfPoints, bullet: true)
            case .paragraph(let text):
                body += paragraph(text: text, headingBold: false, sizeHalfPoints: bodyHalfPoints, bullet: false)
            }
        }
        return xmlDeclaration + documentOpen + "<w:body>" + body + sectPr + "</w:body></w:document>"
    }

    // MARK: Paragraph + run building

    private static func paragraph(text: String, headingBold: Bool, sizeHalfPoints: Int, bullet: Bool) -> String {
        var runs = ""
        if bullet {
            runs += run(text: "\u{2022}\t", bold: false, italic: false, sizeHalfPoints: sizeHalfPoints)
        }
        for inline in MarkdownInline.runs(from: text) {
            runs += run(text: inline.text, bold: headingBold || inline.bold, italic: inline.italic, sizeHalfPoints: sizeHalfPoints)
        }
        let pPr = bullet ? "<w:pPr><w:ind w:left=\"360\" w:hanging=\"180\"/></w:pPr>" : ""
        return "<w:p>" + pPr + runs + "</w:p>"
    }

    private static func run(text: String, bold: Bool, italic: Bool, sizeHalfPoints: Int) -> String {
        var rPr = "<w:rPr>"
        if bold { rPr += "<w:b/>" }
        if italic { rPr += "<w:i/>" }
        rPr += "<w:sz w:val=\"\(sizeHalfPoints)\"/><w:szCs w:val=\"\(sizeHalfPoints)\"/></w:rPr>"
        return "<w:r>" + rPr + "<w:t xml:space=\"preserve\">" + escape(text) + "</w:t></w:r>"
    }

    /// Escapes the XML text-content metacharacters (ampersand first).
    static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    // MARK: Static fragments

    private static let xmlDeclaration = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"
    private static let documentOpen =
        "<w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">"
    /// US Letter (12240×15840 twips) with 0.75″ (1080 twip) margins.
    private static let sectPr =
        "<w:sectPr><w:pgSz w:w=\"12240\" w:h=\"15840\"/>"
        + "<w:pgMar w:top=\"1080\" w:right=\"1080\" w:bottom=\"1080\" w:left=\"1080\" "
        + "w:header=\"720\" w:footer=\"720\" w:gutter=\"0\"/></w:sectPr>"
}
