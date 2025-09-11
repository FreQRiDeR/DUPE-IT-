//
//  DUPE-IT_App.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import SwiftUI

@main
struct DUPE_IT_App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}