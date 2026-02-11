//
//  WinGameView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/30/26.
//

import SwiftUI

struct WinGameView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    let onExit: () -> Void
    
    var body: some View {
        ZStack {
            // Brighter overlay for winning
            Color.black.opacity(0.75).ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("Victory!")
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                        .foregroundStyle(.yellow) // Gold/Yellow for winning
                    
                    Text("Final Score: \(viewModel.userScore)")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                        .foregroundStyle(.white)
                }
                
                Button(action: {
                    HapticManager.shared.trigger(.heavy) // Stronger haptic for win
                    onExit()
                }) {
                    Text("Back to Start")
                        .font(.headline)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green) // Green for "Win" theme
                // Listen for Spacebar
                .keyboardShortcut(.space, modifiers: [])
                // Support Enter/Return
                .keyboardShortcut(.defaultAction)
                
                Text("Press Space to Continue")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding()
        }
    }
}
