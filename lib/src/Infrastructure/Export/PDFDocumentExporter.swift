//
//  PDFDocumentExporter.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Export — render a Markdown document to a paginated PDF (Q-B).
//

import Foundation
import CoreGraphics
import CoreText

/// A ``DocumentExporter`` that renders the assembled Markdown to a multi-page PDF using
/// Core Text pagination — synchronous, self-contained (no WebView, network, or bundled
/// fonts), so it composes with the `nonisolated` port. Only `.pdf` is handled; other
/// formats throw ``ExportError/unsupportedFormat(_:)``.
///
/// (Renderer choice recorded in ROADMAP Milestone Q-B: native Core Text over WebKit
/// HTML-print, because the port is sync + `nonisolated` and Core Text stays off the main
/// actor. The ``ExportTemplate`` typography/layout is applied here — Milestone X — and the
/// same pagination powers the one-page gate via ``pageCount(markdown:template:)``.)
nonisolated struct PDFDocumentExporter: DocumentExporter {
    /// US Letter at 72 dpi.
    var pageSize = CGSize(width: 612, height: 792)

    nonisolated func export(markdown: String, as format: ExportFormat, template: ExportTemplate) throws -> Data {
        guard format == .pdf else { throw ExportError.unsupportedFormat(format) }
        let style = template.style
        let attributed = MarkdownAttributedRenderer.attributedString(from: markdown, style: style)
        return Self.render(attributed, pageSize: pageSize, margin: style.margin)
    }

    /// The number of pages `markdown` occupies in `template`'s layout — the measurement
    /// behind the one-page gate (Milestone X). Never renders bytes, just paginates.
    nonisolated func pageCount(markdown: String, template: ExportTemplate) throws -> Int {
        let style = template.style
        let attributed = MarkdownAttributedRenderer.attributedString(from: markdown, style: style)
        return Self.pageRanges(attributed, pageSize: pageSize, margin: style.margin).count
    }

    /// The per-page string ranges the text flows into — shared by rendering and the page
    /// count so both agree exactly. Always returns at least one page (an empty document
    /// still yields a blank page). Guards against a page that can't advance so it never
    /// loops forever.
    static func pageRanges(_ attributed: NSAttributedString, pageSize: CGSize, margin: CGFloat) -> [CFRange] {
        let framesetter = CTFramesetterCreateWithAttributedString(attributed as CFAttributedString)
        let path = CGPath(rect: textRect(pageSize: pageSize, margin: margin), transform: nil)
        let total = attributed.length

        var ranges: [CFRange] = []
        var start = 0
        repeat {
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: start, length: 0), path, nil)
            let visible = CTFrameGetVisibleStringRange(frame)
            ranges.append(CFRange(location: start, length: max(visible.length, 0)))
            guard visible.length > 0 else { break }
            start += visible.length
        } while start < total
        return ranges
    }

    /// Paginates `attributed` into a PDF, flowing text through a fixed text rect per page.
    static func render(_ attributed: NSAttributedString, pageSize: CGSize, margin: CGFloat) -> Data {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return Data() }
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return Data() }

        let framesetter = CTFramesetterCreateWithAttributedString(attributed as CFAttributedString)
        let path = CGPath(rect: textRect(pageSize: pageSize, margin: margin), transform: nil)

        for range in pageRanges(attributed, pageSize: pageSize, margin: margin) {
            ctx.beginPDFPage(nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: range.location, length: 0), path, nil)
            CTFrameDraw(frame, ctx)
            ctx.endPDFPage()
        }

        ctx.closePDF()
        return pdfData as Data
    }

    /// The text column for a page at `margin`.
    private static func textRect(pageSize: CGSize, margin: CGFloat) -> CGRect {
        CGRect(x: margin, y: margin, width: pageSize.width - margin * 2, height: pageSize.height - margin * 2)
    }
}
