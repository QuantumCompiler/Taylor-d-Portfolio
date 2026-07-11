//
//  MarkdownText.swift
//  Taylor'd Portfolio
//
//  Presentation · Components — render Markdown as styled, selectable SwiftUI text (S-A).
//

import SwiftUI
import Foundation

/// Renders a Markdown document (a generated résumé / cover letter) as **styled** SwiftUI
/// text instead of raw markup: heading levels, bullet lists, and inline **bold** / *italic*.
///
/// Reuses the same tested parsers the exporters use — `MarkdownBlockParser` for block
/// structure and `MarkdownInline` for inline runs — so the on-screen rendering stays in step
/// with the PDF/DOCX output. Selectable, so the user can still copy any span.
struct MarkdownText: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(MarkdownBlockParser.blocks(from: markdown).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .blank:
            EmptyView()   // vertical spacing comes from the VStack

        case .heading(let level, let text):
            Text(inline(text))
                .font(headingFont(level)).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, level <= 2 ? 6 : 2)

        case .bullet(let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("•")
                Text(inline(text)).frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.callout)

        case .paragraph(let text):
            Text(inline(text))
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Builds one line into an `AttributedString`, carrying inline bold/italic as
    /// presentation intents (rendered by `Text`). The run text is already parsed, so it's
    /// appended verbatim — never re-interpreted as markdown.
    private func inline(_ line: String) -> AttributedString {
        var result = AttributedString()
        for run in MarkdownInline.runs(from: line) {
            var piece = AttributedString(run.text)
            var intent: InlinePresentationIntent = []
            if run.bold { intent.insert(.stronglyEmphasized) }
            if run.italic { intent.insert(.emphasized) }
            if !intent.isEmpty { piece.inlinePresentationIntent = intent }
            result.append(piece)
        }
        return result
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title2
        case 2: return .title3
        default: return .headline
        }
    }
}

#if DEBUG
#Preview("Résumé") {
    ScrollView {
        MarkdownText(markdown: """
        # Jane Dev
        **Senior iOS Engineer** · fintech

        ## Experience
        - Led **SwiftUI** rewrite of the flagship app
        - Shipped *offline-first* sync

        ## Skills
        Swift, SwiftUI, Combine
        """)
        .padding()
    }
    .frame(width: 460, height: 360)
}

#Preview("Cover letter") {
    ScrollView {
        MarkdownText(markdown: """
        ## About Me
        I build delightful, reliable iOS apps.

        ## Why Acme
        Your **offline-first** product matches my strengths.

        ## Why Me
        I ship fast and care about craft.
        """)
        .padding()
    }
    .frame(width: 460, height: 320)
}
#endif
