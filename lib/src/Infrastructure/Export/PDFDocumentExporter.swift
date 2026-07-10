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
/// actor. Trade-off: coarser layout / a harder one-page gate for Milestone X.)
nonisolated struct PDFDocumentExporter: DocumentExporter {
    /// US Letter at 72 dpi.
    var pageSize = CGSize(width: 612, height: 792)
    /// 0.75" margins.
    var margin: CGFloat = 54

    nonisolated func export(markdown: String, as format: ExportFormat) throws -> Data {
        guard format == .pdf else { throw ExportError.unsupportedFormat(format) }
        let attributed = MarkdownAttributedRenderer.attributedString(from: markdown)
        return Self.render(attributed, pageSize: pageSize, margin: margin)
    }

    /// Paginates `attributed` into a PDF, flowing text through a fixed text rect per page.
    static func render(_ attributed: NSAttributedString, pageSize: CGSize, margin: CGFloat) -> Data {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return Data() }
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return Data() }

        let framesetter = CTFramesetterCreateWithAttributedString(attributed as CFAttributedString)
        let textRect = CGRect(
            x: margin, y: margin,
            width: pageSize.width - margin * 2,
            height: pageSize.height - margin * 2
        )
        let path = CGPath(rect: textRect, transform: nil)
        let total = attributed.length

        var start = 0
        repeat {
            ctx.beginPDFPage(nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: start, length: 0), path, nil)
            CTFrameDraw(frame, ctx)
            let visible = CTFrameGetVisibleStringRange(frame)
            ctx.endPDFPage()
            // Guard against a page that can't advance (e.g. an over-wide glyph) so we never loop forever.
            guard visible.length > 0 else { break }
            start += visible.length
        } while start < total

        ctx.closePDF()
        return pdfData as Data
    }
}
