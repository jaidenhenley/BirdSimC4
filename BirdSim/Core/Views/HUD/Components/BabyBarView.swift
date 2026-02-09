//
//  BabyBarView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/9/26.
//

import SwiftUI

struct BabyBarView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel

    let totalSegments = 5
    
    @Binding var currentBabies: Int
    
    
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
                
                Image(.babyBirdNest)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                
                Image(.babyBirdWord)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                
                ForEach(0..<totalSegments, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.blue)
                        .frame(width: 30, height: 15)
                        .opacity(index < currentBabies ? 1.0 : 0.2)
                        .animation(.spring(), value: currentBabies)
                }
            }
        }
    }
}

