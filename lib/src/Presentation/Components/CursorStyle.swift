//
//  CursorStyle.swift
//  Taylor'd Portfolio
//
//  Presentation · Components — shared cursor affordances (quality-of-life).
//

import SwiftUI

extension View {
    /// Shows the **pointing-hand** cursor while hovering, marking the view as clickable.
    /// Apply to buttons, links, pickers, sliders, and custom tap targets (rows, chips…).
    ///
    /// Text fields/editors keep the native **I-beam** automatically, so they don't need this.
    func clickableCursor() -> some View {
        pointerStyle(.link)
    }
}
