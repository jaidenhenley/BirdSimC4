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
            container = try ModelContainer(for: GameState.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainGameView(viewModel: MainGameView.ViewModel(context: container.mainContext))
                .statusBarHidden(true)
        }
        .modelContainer(container)
    }
}
