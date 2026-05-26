//
//  UserScoreView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/3/26.
//

import SwiftUI

struct UserScoreView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel

    var body: some View {
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let starSize: CGFloat = isiPad ? 30 : 20
        let fontSize: CGFloat = isiPad ? 35 : 22
        let hPad: CGFloat = isiPad ? 25 : 14
        let vPad: CGFloat = isiPad ? 10 : 6

        VStack(spacing: -5) {
            if viewModel.isNewRecord {
                Text("NEW RECORD!")
                    .font(.system(.caption, design: .monospaced, weight: .black))
                    .foregroundColor(.yellow)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 15) {
                Image(systemName: "star.fill")
                    .resizable()
                    .frame(width: starSize, height: starSize)
                    .foregroundColor(.yellow)
                    .symbolEffect(.bounce, value: viewModel.userScore)

                Text("\(viewModel.userScore)")
                    .font(.system(size: fontSize, weight: .black, design: .rounded))
                    .italic()
                    .foregroundColor(.white)
                    .contentTransition(.numericText(value: Double(viewModel.userScore)))
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .background {
                ZStack {
                    // Main Box - Mario Blue/Zelda Green
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.isNewRecord ? Color.orange : Color.blue)
                        .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 8)

                    
                    // Glossy Shine (The Arcade Feel)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [.clear, .white.opacity(0.4), .clear],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                }
                .overlay(
                    // Thick "Cartoony" Border
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white, lineWidth: 6)
                )
            }
            
            // Squash and Stretch Animation
            .scaleEffect(x: viewModel.scoreAnimating ? 1.3 : 1.0,
                         y: viewModel.scoreAnimating ? 0.8 : 1.0)
            .rotationEffect(.degrees(viewModel.scoreAnimating ? Double.random(in: -5...5) : 0))
            .animation(.spring(response: 0.25, dampingFraction: 0.3, blendDuration: 0), value: viewModel.userScore)
        }

    }
}
