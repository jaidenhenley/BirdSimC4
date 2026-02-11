//
//  MainOnboardingView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/10/26.
//

import SwiftUI

struct MainOnboardingView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    @Environment(\.dismiss) var dismiss
    
    let type: MainGameView.ViewModel.InstructionType
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Instructions")
                    .font(.system(.title, design: .rounded))
                    .bold()
                
                // Visual separator for better hierarchy
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 4)
            }
            
            // Instruction Content
            Text(viewModel.mainInstructionText(for: type))
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true) // Prevents text clipping
            
            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button(action: handleDismiss) {
                    Text("Got it!")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue) // Different color to distinguish from "Game Start"
                .keyboardShortcut(.space, modifiers: [])
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func handleDismiss() {
        // Satisfying haptic click
        HapticManager.shared.trigger(.light)
        dismiss()
    }
}
