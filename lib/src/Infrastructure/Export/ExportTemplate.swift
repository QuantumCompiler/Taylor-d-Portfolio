//
//  ExportTemplate.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Export — selectable résumé templates (Milestone X).
//

import CoreGraphics

/// A visual template the PDF exporter can render a document against (Milestone X). Since
/// Q-B chose the Core Text renderer (not HTML), a template is just a bundle of typography
/// and layout knobs — a ``TemplateStyle`` — not a separate document engine. Text formats
/// (Markdown / plain / DOCX) are content-only and ignore the template.
enum ExportTemplate: String, CaseIterable, Sendable, Identifiable {
    /// The original look: sans-serif, black headings, roomy margins (the default, so
    /// existing exports are byte-for-byte unchanged).
    case classic
    /// Denser — smaller type, tighter margins/spacing — to help a résumé fit one page.
    case compact
    /// Serif body with a navy accent on headings, for a more formal résumé.
    case modern

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .compact: return "Compact"
        case .modern: return "Modern"
        }
    }

    /// A one-line description for the picker.
    var summary: String {
        switch self {
        case .classic: return "Sans-serif, roomy"
        case .compact: return "Dense — fits more on a page"
        case .modern: return "Serif with accent headings"
        }
    }

    /// The resolved typography + layout for this template.
    var style: TemplateStyle {
        switch self {
        case .classic:
            return TemplateStyle(
                bodySize: 11, h1Size: 22, h2Size: 16, h3Size: 13,
                margin: 54, paragraphSpacing: 4, usesSerif: false, headingColor: .black
            )
        case .compact:
            return TemplateStyle(
                bodySize: 10, h1Size: 18, h2Size: 14, h3Size: 12,
                margin: 40, paragraphSpacing: 2, usesSerif: false, headingColor: .black
            )
        case .modern:
            return TemplateStyle(
                bodySize: 11, h1Size: 23, h2Size: 16, h3Size: 13,
                margin: 54, paragraphSpacing: 4, usesSerif: true,
                headingColor: RGBColor(red: 0.11, green: 0.22, blue: 0.40)   // navy
            )
        }
    }
}

/// The concrete typography + layout an ``ExportTemplate`` resolves to. A pure value type
/// (no AppKit), so template definitions are trivially testable; the renderer converts
/// `headingColor` to an `NSColor` at draw time.
struct TemplateStyle: Sendable, Equatable {
    var bodySize: CGFloat
    var h1Size: CGFloat
    var h2Size: CGFloat
    var h3Size: CGFloat
    /// Page margin in points (US-Letter page).
    var margin: CGFloat
    var paragraphSpacing: CGFloat
    /// Whether body/headings use the system serif face (New York) rather than sans.
    var usesSerif: Bool
    /// Heading text colour (body text is always black for print legibility).
    var headingColor: RGBColor

    /// The heading point size for a Markdown level (1…), clamped to h3 for deeper levels.
    func headingSize(forLevel level: Int) -> CGFloat {
        switch level {
        case ...1: return h1Size
        case 2: return h2Size
        default: return h3Size
        }
    }
}

/// A device-independent sRGB colour, kept AppKit-free so ``TemplateStyle`` stays pure.
struct RGBColor: Sendable, Equatable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat

    static let black = RGBColor(red: 0, green: 0, blue: 0)
}
