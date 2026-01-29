//
//  BirdSimulatorApp.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SwiftUI

@main
struct BirdSimulatorApp: App {
    @State var gameStarted: Bool = false

    var body: some Scene {
        WindowGroup {
            MainGameView(viewModel: MainGameView.ViewModel())
                .statusBarHidden(true)
        }
    }
}
