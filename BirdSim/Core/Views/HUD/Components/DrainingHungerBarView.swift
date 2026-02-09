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
    
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .frame(width: 400, height: 60)
                .cornerRadius(8)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                }
            HStack(spacing: 4) {
                
                Image(.hungerBarBird)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                
                Image(.hungerBarWord)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                
                ForEach(0..<totalSegments, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(for: index))
                        .frame(width: 30, height: 15)
                        .opacity(index < currentHunger ? 1.0 : 0.2)
                        .animation(.spring(), value: currentHunger)
                }
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

