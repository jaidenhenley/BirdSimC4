//
//  StartGameView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/27/26.
//

import SwiftUI

struct StartGameView: View {
    @Binding var gameStarted: Bool
    @Binding var scene: GameScene
    var body: some View {
        NavigationStack {
            ZStack {
                Color.red.ignoresSafeArea()
                VStack {
                    Button("Start Game") {
                        startGame()
                    }
                }
            }
        }
    }
    func startGame() {
        gameStarted = true
        scene.initializeGame()
    }
}
