//
//  ContentView.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SwiftUI

struct ContentView: View {
    @State private var gameStarted: Bool = false
    
    var body: some View {
        if !gameStarted {
            StartGameView(gameStarted: $gameStarted)
        } else {
            MainGameView(viewModel: MainGameViewModel())
        }
        
    }
}

#Preview {
    ContentView()
}
