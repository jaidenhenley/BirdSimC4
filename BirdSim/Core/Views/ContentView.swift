//
//  ContentView.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SwiftUI

struct ContentView: View {
    @State private var gameStarted: Bool = false
    @State private var gameEnded: Bool = false
    
    var body: some View {
        if !gameStarted {
            StartGameView(gameStarted: $gameStarted)
        } else if gameEnded {
          //  EndGameView(gameEnded: $gameEnded)
        } else {
            MainGameView(viewModel: MainGameView.ViewModel())
        }
        
    }
}

#Preview {
    ContentView()
}
