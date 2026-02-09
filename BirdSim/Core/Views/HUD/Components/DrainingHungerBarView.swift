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
        HStack(spacing: 4) {
            ForEach(0..<totalSegments, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color(for: index))
                    .frame(width: 20, height: 10)
                    .opacity(index < currentHunger ? 1.0 : 0.2)
                    .animation(.spring(), value: currentHunger)
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

