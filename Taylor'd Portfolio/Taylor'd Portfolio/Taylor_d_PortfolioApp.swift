//
//  Taylor_d_PortfolioApp.swift
//  Taylor'd Portfolio
//
//  Created by Taylor Larrechea on 7/6/26.
//

import SwiftUI
import CoreData

@main
struct Taylor_d_PortfolioApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
