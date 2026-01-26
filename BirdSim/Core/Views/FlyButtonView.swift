//
//  FlyButtonView.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SwiftUI

struct FlyButtonView: View {
    @ObservedObject var viewModel: MainGameViewModel

        var body: some View {
            Button(action: {
                // 2. Animate the change
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.isFlying.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6)) // background color
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "chevron.up")
                        .font(.system(size: 30))
                        .bold()
                        .foregroundStyle(.black)
                        .rotationEffect(.degrees(viewModel.isFlying ? 0 : 180))
                }
            }
        }
}

#Preview {
    FlyButtonView(viewModel: MainGameViewModel())
}
