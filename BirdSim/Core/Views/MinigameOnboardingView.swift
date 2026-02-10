//
//  MinigameOnboardingView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/10/26.
//

import SwiftUI

struct MinigameOnboardingView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
//    let timer: Timer
    
    var body: some View {
        VStack(spacing: 16) {
            if let type = viewModel.pendingMiniGameType {
                Text("Instructions")
                    .font(.system(.title, design: .rounded)).bold()
                Text(viewModel.instructionsText(for: type))
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                Text("Instructions")
                    .font(.system(.title, design: .rounded)).bold()
                Text("Get ready!")
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding()
            }

            HStack(spacing: 20) {

                Button {
                    viewModel.startPendingMiniGame()
                    viewModel.controlsAreVisable = false
                    viewModel.mapIsVisable = false
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
