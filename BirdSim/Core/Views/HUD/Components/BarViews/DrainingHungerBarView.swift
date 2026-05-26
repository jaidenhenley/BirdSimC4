//
//  HealthBarView.swift
//  BirdSim
//
//  Created by George Clinkscales on 1/27/26.
//

import SpriteKit
import SwiftUI
import Combine

struct DrainingHungerBarView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    
    let totalSegments = 5
    @Binding var currentHunger: Int
    let isIPad: Bool
    
    
    var body: some View {
        let screen = UIScreen.main.bounds
        let longEdge = max(screen.width, screen.height)
        let shortEdge = min(screen.width, screen.height)
        let barWidth = longEdge * (isIPad ? 0.22 : 0.14)
        let barHeight = shortEdge * 0.08
        let segmentWidth = barWidth * 0.08
        let segmentHeight = barHeight * 0.3
        
        ZStack {
            Color.black.opacity(0.6)
                .frame(width: barWidth, height: barHeight)
                .cornerRadius(8)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                }
            
            HStack(spacing: 4) {
                
                Image(.hungerBarBird)
                    .resizable()
                    .scaledToFit()
                    .frame(width: barHeight * 0.7, height: barHeight * 0.7)
                
                if isIPad {
                    Image(.hungerBarWord)
                        .resizable()
                        .scaledToFit()
                        .frame(width: barWidth * 0.28, height: barHeight * 0.5)
                }
                
                ForEach(0..<totalSegments, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(for: index))
                        .frame(width: segmentWidth, height: segmentHeight)
                        .opacity(index < currentHunger ? 1.0 : 0.2)
                        .animation(.spring(), value: currentHunger)
                }
            }
        }        .onAppear {
            if currentHunger <= 0 {
                viewModel.showGameOver = true
                viewModel.currentDeathMessage = "You died from Hunger"
                viewModel.submitScore(value: viewModel.userScore) // Ensure score is submitted even on loss

            }
        }
        .onChange(of: currentHunger) { _, newValue in
            if newValue <= 0 {
                viewModel.showGameOver = true
                viewModel.currentDeathMessage = "You died from Hunger"
                viewModel.submitScore(value: viewModel.userScore) // Ensure score is submitted even on loss


            }
        }
    }
        
    
    private func color(for index: Int) -> Color {
        switch currentHunger {
        case 0...1:
            return .red
        case 2...3:
            return .yellow
        default:
            return .green
        }
    }
}

