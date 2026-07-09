//
//  App.swift
//  Taylor'd Portfolio
//
//  Presentation · App — the composition root.
//

import SwiftUI

/// Entry point and composition root for Taylor'd Portfolio.
///
/// This is the one place allowed to reference every layer and wire them together
/// (Infrastructure → Data → Business → ViewModels). It opens straight to the main
/// tabs, starting on the Portfolio tab.
@main
struct Taylor_d_PortfolioApp: App {
    private let composition = Composition()

    var body: some Scene {
        WindowGroup {
            RootView(composition: composition)
                .frame(minWidth: 800, minHeight: 500)
        }
        .defaultSize(width: 800, height: 500)
        .windowResizability(.contentMinSize)
    }
}
