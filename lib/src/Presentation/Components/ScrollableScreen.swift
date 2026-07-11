//
//  ScrollableScreen.swift
//  Taylor'd Portfolio
//
//  Presentation · Components — a shared vertical-scroll wrapper for tab screens.
//

import SwiftUI

extension View {
    /// Wraps a screen's content in a vertical `ScrollView` so every control stays reachable
    /// when the window is short. Replaces the `VStack { … Spacer() }` pattern that clipped its
    /// lower controls (e.g. Search's "Fetch" button) once the stacked content exceeded the
    /// window height. The content keeps its own padding/alignment; this only adds scrolling and
    /// makes it fill the available width so left-aligned layouts read the same as before.
    ///
    /// Apply it in place of the trailing `Spacer()`, after the content's `.padding(…)`.
    func scrollableScreen() -> some View {
        ScrollView(.vertical) {
            self.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
