//
//  BirdSimulatorApp.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SwiftUI
import SwiftData

@main
struct BirdSimulatorApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: GameState.self, GameSettings.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentRootView(container: container)
                .statusBarHidden(true)
        }
        .modelContainer(container)
    }
}
