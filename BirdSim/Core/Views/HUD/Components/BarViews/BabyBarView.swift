//
//  BabyBarView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/9/26.
//

import SwiftUI

struct BabyBarView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    @Binding var currentBabies: Int
    let totalSegments = 5
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
                
                Image(.babyBirdNest)
                    .resizable()
                    .scaledToFit()
                    .frame(width: barHeight * 0.7, height: barHeight * 0.7)
                if isIPad {
                    Image(.babyBirdWord)
                        .resizable()
                        .scaledToFit()
                        .frame(width: barWidth * 0.28, height: barHeight * 0.5)
                }
                
                ForEach(0..<totalSegments, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.blue)
                        .frame(width: segmentWidth, height: segmentHeight)
                        .opacity(index < currentBabies ? 1.0 : 0.2)
                        .animation(.spring(), value: currentBabies)
                }
            }
        }
    }
}

