//
//  HTMLStripperTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Text — HTML → plain text.
//

import Testing
@testable import Taylor_d_Portfolio

@Suite("HTMLStripper")
struct HTMLStripperTests {

    @Test func stripsTagsAndKeepsText() {
        #expect(HTMLStripper.plainText("<p>Build <b>native</b> apps.</p>") == "Build native apps.")
    }

    @Test func turnsBreaksAndBlocksIntoNewlines() {
        #expect(HTMLStripper.plainText("Line one<br>Line two<br/>Line three") == "Line one\nLine two\nLine three")
    }

    @Test func decodesCommonEntities() {
        #expect(HTMLStripper.plainText("R&amp;D &lt;tags&gt; &quot;quoted&quot; it&#39;s") == "R&D <tags> \"quoted\" it's")
    }

    @Test func collapsesBlankLinesAndTrims() {
        #expect(HTMLStripper.plainText("<div>A</div><div></div><div></div><div>B</div>") == "A\n\nB")
    }

    @Test func dropsScriptAndStyleContents() {
        let html = "<style>.a{color:red}</style><p>Real</p><script>alert('x')</script> text"
        let out = HTMLStripper.plainText(html)
        #expect(out.contains("Real"))
        #expect(!out.contains("color"))
        #expect(!out.contains("alert"))
    }

    @Test func plainTextPassesThroughUnchanged() {
        #expect(HTMLStripper.plainText("Just plain text.") == "Just plain text.")
    }
}
