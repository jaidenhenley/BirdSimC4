//
//  EndGameView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/28/26.
//

import SwiftUI

struct EndGameView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Game Over")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)

                Button("Back to Start") {
                    
                    onExit()
//                    withAnimation {
//                        viewModel.mainScene = nil
//                        viewModel.showGameOver = false
//                        viewModel.gameStarted = false
//                        viewModel.controlsAreVisable = true
//                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(.ultraThinMaterial))
            }
            .padding()
        }
    }
}
