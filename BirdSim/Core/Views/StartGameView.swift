//
//  StartGameView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/27/26.
//

import SwiftUI

struct StartGameView: View {
    @Binding var gameStarted: Bool
    var body: some View {
        NavigationStack {
            ZStack {
                Color.red.ignoresSafeArea()
                VStack {
                    Button("Start Game") {
                        gameStarted = true
                    }
                }
            }
        }
    }
}
