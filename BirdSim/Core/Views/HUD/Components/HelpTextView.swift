//
//  HelpTextView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/29/26.
//

import SwiftUI

struct HelpTextView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    var body: some View {
        
        if viewModel.currentMessage != "" {
            Text(viewModel.currentMessage)
                .font(.system(size: 30))
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(.white.opacity(0.3))
                )
            
        }
    }
}

#Preview {
    HelpTextView(viewModel: MainGameView.ViewModel())
}
