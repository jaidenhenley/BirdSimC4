//
//  ContentView.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainGameView(viewModel: MainGameViewModel())
    }
}

#Preview {
    ContentView()
}
