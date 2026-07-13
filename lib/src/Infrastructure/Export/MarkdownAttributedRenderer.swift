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
/// Markdown, whose symbolic traits are merged onto the block font). Typography and layout
/// come from a ``TemplateStyle`` (Milestone X); body text is drawn **black** so the PDF
/// prints correctly regardless of the viewer's appearance, while headings may take the
/// template's accent colour.
///
/// Fidelity is intentionally modest (no tables, images, or nested lists) — the HTML-template
/// path (see ROADMAP Milestone X) would restore full fidelity if ever needed.
nonisolated enum MarkdownAttributedRenderer {

    static func attributedString(from markdown: String,
                                 style: TemplateStyle = ExportTemplate.classic.style) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            result.append(paragraph(for: line, style: style))
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        return result
    }

    // MARK: Block classification + styling

    /// Renders one source line as a single styled paragraph (no trailing newline).
    private static func paragraph(for line: String, style: TemplateStyle) -> NSAttributedString {
        switch MarkdownBlockParser.classify(line) {
        case .blank:
            return NSAttributedString(string: "")   // spacer; the caller adds the newline
        case .heading(let level, let text):
            let size = style.headingSize(forLevel: level)
            let para = NSMutableParagraphStyle()
            para.paragraphSpacingBefore = level <= 1 ? 4 : 8
            para.paragraphSpacing = 3
            return styled(text, size: size, baseTraits: .bold, color: style.headingColor.nsColor,
                          style: style, paragraph: para)
        case .bullet(let text):
            let para = NSMutableParagraphStyle()
            para.headIndent = 16
            para.tabStops = [NSTextTab(textAlignment: .left, location: 16)]
            para.paragraphSpacing = 2
            let s = NSMutableAttributedString(string: "•\t")
            s.addAttribute(.font, value: font(size: style.bodySize, traits: [], style: style),
                           range: NSRange(location: 0, length: s.length))
            s.addAttribute(.foregroundColor, value: NSColor.black,
                           range: NSRange(location: 0, length: s.length))
            s.append(styledInline(text, size: style.bodySize, baseTraits: [], color: .black, style: style))
            s.addAttribute(.paragraphStyle, value: para, range: NSRange(location: 0, length: s.length))
            return s
        case .thematicBreak:
            return thematicBreak(style: style)
        case .paragraph(let text):
            let para = NSMutableParagraphStyle()
            para.paragraphSpacing = style.paragraphSpacing
            return styled(text, size: style.bodySize, baseTraits: [], color: .black,
                          style: style, paragraph: para)
        }
    }

    /// A subtle horizontal rule for a Markdown thematic break (`---`). Drawn as an
    /// **underlined tab** that fills the text column — Core Text has no paragraph border, and
    /// this renders a real line (never literal dashes). Width matches
    /// ``PDFDocumentExporter``'s US-Letter text column (page 612pt − 2·margin).
    private static func thematicBreak(style: TemplateStyle) -> NSAttributedString {
        let columnWidth = 612 - style.margin * 2
        let para = NSMutableParagraphStyle()
        para.paragraphSpacingBefore = 6
        para.paragraphSpacing = 6
        para.tabStops = [NSTextTab(textAlignment: .right, location: columnWidth)]
        let rule = NSMutableAttributedString(string: "\t")
        let full = NSRange(location: 0, length: rule.length)
        rule.addAttribute(.paragraphStyle, value: para, range: full)
        rule.addAttribute(.font, value: font(size: style.bodySize, traits: [], style: style), range: full)
        rule.addAttribute(.foregroundColor, value: NSColor.black, range: full)
        rule.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: full)
        rule.addAttribute(.underlineColor, value: NSColor(white: 0.6, alpha: 1), range: full)
        return rule
    }

    /// A whole-paragraph inline render with a shared paragraph style applied.
    private static func styled(_ text: String, size: CGFloat,
                               baseTraits: NSFontDescriptor.SymbolicTraits,
                               color: NSColor, style: TemplateStyle,
                               paragraph: NSParagraphStyle) -> NSAttributedString {
        let s = NSMutableAttributedString(
            attributedString: styledInline(text, size: size, baseTraits: baseTraits, color: color, style: style)
        )
        s.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: s.length))
        return s
    }

    /// Parses inline Markdown in `text` and applies fonts, merging any inline bold/italic
    /// traits onto `baseTraits` at `size`. Falls back to plain text if parsing fails.
    private static func styledInline(_ text: String, size: CGFloat,
                                     baseTraits: NSFontDescriptor.SymbolicTraits,
                                     color: NSColor, style: TemplateStyle) -> NSAttributedString {
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
            ns.addAttribute(.font, value: font(size: size, traits: baseTraits.union(inlineTraits), style: style), range: range)
        }
        ns.addAttribute(.foregroundColor, value: color, range: full)
        return ns
    }

    private static func font(size: CGFloat, traits: NSFontDescriptor.SymbolicTraits,
                             style: TemplateStyle) -> NSFont {
        let base = baseFont(size: size, serif: style.usesSerif)
        guard !traits.isEmpty else { return base }
        return NSFont(descriptor: base.fontDescriptor.withSymbolicTraits(traits), size: size) ?? base
    }

    /// The unstyled face at `size` — the system serif (New York) when the template asks
    /// for it, otherwise the system sans (San Francisco).
    private static func baseFont(size: CGFloat, serif: Bool) -> NSFont {
        let system = NSFont.systemFont(ofSize: size)
        guard serif, let serifDescriptor = system.fontDescriptor.withDesign(.serif) else { return system }
        return NSFont(descriptor: serifDescriptor, size: size) ?? system
    }
}

extension RGBColor {
    /// The AppKit colour for this device-independent value (sRGB, fully opaque).
    nonisolated var nsColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }
}
