//
//  UserScoreView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/3/26.
//

import SwiftUI

struct UserScoreView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    @State private var shineOffset: CGFloat = -200

    var body: some View {
        VStack(spacing: -5) {
            if viewModel.isNewRecord {
                Text("NEW RECORD!")
                    .font(.system(.caption, design: .monospaced, weight: .black))
                    .foregroundColor(.yellow)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 15) {
                // The Bouncing Mario Star
                Image(systemName: "star.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.yellow)
                    // Hard "Zelda" outline
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                    .symbolEffect(.bounce, value: viewModel.userScore)
                
                // The Chunky Score
                Text("\(viewModel.userScore)")
                    .font(.system(size: 35, weight: .black, design: .rounded))
                    .italic()
                    .foregroundColor(.white)
                    // Layered shadows create a "sticker" or "game logo" effect
                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                    .contentTransition(.numericText(value: Double(viewModel.userScore)))
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 10)
            .background {
                ZStack {
                    // Main Box - Mario Blue/Zelda Green
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.isNewRecord ? Color.orange : Color.blue)
                    
                    // Glossy Shine (The Arcade Feel)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [.clear, .white.opacity(0.4), .clear],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                        .offset(x: shineOffset)
                }
                .overlay(
                    // Thick "Cartoony" Border
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white, lineWidth: 6)
                )
                .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 8)
            }
            // Squash and Stretch Animation
            .scaleEffect(x: viewModel.scoreAnimating ? 1.3 : 1.0,
                         y: viewModel.scoreAnimating ? 0.8 : 1.0)
            .rotationEffect(.degrees(viewModel.scoreAnimating ? Double.random(in: -5...5) : 0))
            .animation(.spring(response: 0.25, dampingFraction: 0.3, blendDuration: 0), value: viewModel.userScore)
        }
        .onChange(of: viewModel.userScore) { _ in
            withAnimation(.linear(duration: 0.4)) {
                shineOffset = 200
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    shineOffset = -200
                }
            }
        }
    }
}
