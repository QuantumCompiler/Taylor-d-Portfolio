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
/// (Infrastructure → Data → Business → ViewModels). For now it just presents the
/// landing screen; dependency wiring arrives with the first real feature.
@main
struct Taylor_d_PortfolioApp: App {
    private let composition = Composition()

    var body: some Scene {
        WindowGroup {
            RootView(composition: composition)
        }
        .defaultSize(width: 900, height: 640)
        .windowResizability(.contentMinSize)
    }
}
