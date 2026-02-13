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
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("Game Over")
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                        .foregroundStyle(.white)
                    
                    Text(viewModel.currentDeathMessage)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                }

                Button(action: {
                    HapticManager.shared.trigger(.medium)
                    onExit()
                }) {
                    Text("Back to Start")
                        .font(.headline)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red) // Red for "End Game" theme
                // Key addition: Listen for Spacebar
                .keyboardShortcut(.space, modifiers: [])
                // Also support Enter/Return
                .keyboardShortcut(.defaultAction)
                
                VStack(spacing: 4) {
                    Text("Press Space to Restart")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding()
        }
    }
}
