//
//  Flags_ChallengeApp.swift
//  Flags Challenge
//
//  Created by adithyan na on 5/8/25.
//

import SwiftUI

@main
struct Flags_ChallengeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(context: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.light)
        }
    }
}
