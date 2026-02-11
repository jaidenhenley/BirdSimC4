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
        VStack(spacing: 16) {
                Text("Instructions")
                    .font(.system(.title, design: .rounded)).bold()
                Text(viewModel.mainInstructionText(for: type))
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding()

            HStack(spacing: 20) {

                Button {
                    dismiss()
                } label: {
                    Text("Start")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .presentationDetents([.medium, .large])
        
    }
}
