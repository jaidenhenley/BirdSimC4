//
//  WinGameView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/30/26.
//

import SwiftUI

struct WinGameView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    let onExit: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Game Win")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)
                
                Button("Back to Start") {
                    onExit()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(.ultraThinMaterial))
            }
            .padding()
        }
    }
}
