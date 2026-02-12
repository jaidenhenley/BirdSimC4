//
//  MinigameOnboardingView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/10/26.
//

import SwiftUI

struct MinigameOnboardingView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Header Section
            VStack(spacing: 8) {
                Text("Instructions")
                    .font(.system(.title, design: .rounded))
                    .bold()
                
                Divider()
                    .frame(width: 60)
                    .background(Color.primary.opacity(0.3))
            }
            
            // Content Section
            Group {
                if let type = viewModel.pendingMiniGameType {
                    Text(viewModel.minigameInstructionsText(for: type))
                } else {
                    Text("Get ready!")
                }
            }
            .font(.system(.body, design: .rounded))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            
            Spacer()

            // Action Section
            VStack(spacing: 12) {
                Button(action: startMiniGame) {
                    Text("Start")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                // Adds Spacebar support
                .keyboardShortcut(.space, modifiers: [])
                // Also adds Enter/Return support
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        // Adjusts height for a nice "Sheet" look
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func startMiniGame() {
        HapticManager.shared.trigger(.medium)
        viewModel.minigameStarted = true
        viewModel.startPendingMiniGame()
        viewModel.controlsAreVisable = false
        viewModel.mapIsVisable = false
    }
}

