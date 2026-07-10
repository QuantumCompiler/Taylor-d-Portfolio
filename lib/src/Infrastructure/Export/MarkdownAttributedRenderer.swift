//
//  MarkdownAttributedRenderer.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Export — render a Markdown document to a styled NSAttributedString.
//

import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Turns the assembled Markdown document into a styled `NSAttributedString` for PDF
/// rendering (Q-B). Handles the subset the résumé / cover letter use: heading levels,
/// bullet lists, and inline **bold** / *italic* / `code` (parsed by Foundation's inline
/// Markdown, whose symbolic traits are merged onto the block font). Text is drawn **black**
/// so the PDF prints correctly regardless of the viewer's appearance.
///
/// Fidelity is intentionally modest (no tables, images, or nested lists) — the HTML-template
/// path (see ROADMAP Milestone X) would restore full fidelity if ever needed.
nonisolated enum MarkdownAttributedRenderer {
    private static let bodySize: CGFloat = 11

    static func attributedString(from markdown: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            result.append(paragraph(for: line))
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        return result
    }

    // MARK: Block classification + styling

    /// Renders one source line as a single styled paragraph (no trailing newline).
    private static func paragraph(for line: String) -> NSAttributedString {
        switch MarkdownBlockParser.classify(line) {
        case .blank:
            return NSAttributedString(string: "")   // spacer; the caller adds the newline
        case .heading(let level, let text):
            let size: CGFloat = level <= 1 ? 22 : (level == 2 ? 16 : 13)
            let style = NSMutableParagraphStyle()
            style.paragraphSpacingBefore = level <= 1 ? 4 : 8
            style.paragraphSpacing = 3
            return styled(text, size: size, baseTraits: .bold, paragraph: style)
        case .bullet(let text):
            let style = NSMutableParagraphStyle()
            style.headIndent = 16
            style.tabStops = [NSTextTab(textAlignment: .left, location: 16)]
            style.paragraphSpacing = 2
            let s = NSMutableAttributedString(string: "•\t")
            s.addAttribute(.font, value: font(size: bodySize, traits: []),
                           range: NSRange(location: 0, length: s.length))
            s.addAttribute(.foregroundColor, value: NSColor.black,
                           range: NSRange(location: 0, length: s.length))
            s.append(styledInline(text, size: bodySize, baseTraits: []))
            s.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: s.length))
            return s
        case .paragraph(let text):
            let style = NSMutableParagraphStyle()
            style.paragraphSpacing = 4
            return styled(text, size: bodySize, baseTraits: [], paragraph: style)
        }
    }

    /// A whole-paragraph inline render with a shared paragraph style applied.
    private static func styled(_ text: String, size: CGFloat,
                               baseTraits: NSFontDescriptor.SymbolicTraits,
                               paragraph: NSParagraphStyle) -> NSAttributedString {
        let s = NSMutableAttributedString(attributedString: styledInline(text, size: size, baseTraits: baseTraits))
        s.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: s.length))
        return s
    }

    /// Parses inline Markdown in `text` and applies fonts, merging any inline bold/italic
    /// traits onto `baseTraits` at `size`. Falls back to plain text if parsing fails.
    private static func styledInline(_ text: String, size: CGFloat,
                                     baseTraits: NSFontDescriptor.SymbolicTraits) -> NSAttributedString {
        let parsed: NSAttributedString
        if let p = try? NSAttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace),
            baseURL: nil
        ) {
            parsed = p
        } else {
            parsed = NSAttributedString(string: text)
        }
        let ns = NSMutableAttributedString(attributedString: parsed)
        let full = NSRange(location: 0, length: ns.length)
        ns.enumerateAttribute(.font, in: full) { value, range, _ in
            let inlineTraits = (value as? NSFont)?.fontDescriptor.symbolicTraits ?? []
            ns.addAttribute(.font, value: font(size: size, traits: baseTraits.union(inlineTraits)), range: range)
        }
        ns.addAttribute(.foregroundColor, value: NSColor.black, range: full)
        return ns
    }

    private static func font(size: CGFloat, traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let base = NSFont.systemFont(ofSize: size)
        guard !traits.isEmpty else { return base }
        return NSFont(descriptor: base.fontDescriptor.withSymbolicTraits(traits), size: size) ?? base
    }
}
