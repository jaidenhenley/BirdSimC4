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
                .fixedSize(horizontal: false, vertical: true)
            
            // Image Gallery Logic
            let resources = viewModel.mainInstructionImage(for: type)
            
            HStack(spacing: 12) {
                ForEach(0..<resources.count, id: \.self) { index in
                    // The actual image
                    Image(resources[index])
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: resources.count > 1 ? 100 : 180)
                        .frame(maxHeight: 120)
                    
                    // Optional: Add a "+" sign between multiple images
                    if index < resources.count - 1 {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            Spacer()
            
            // Action Button
            Button {
                dismiss()
            } label: {
                Text("Start")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.space, modifiers: [])
        }
        .padding(30)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
