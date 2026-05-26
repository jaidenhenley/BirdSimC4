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
            let isiPad = UIDevice.current.userInterfaceIdiom == .pad
            Text(viewModel.currentMessage)
                .font(.system(size: isiPad ? 30 : 16))
                .padding(isiPad ? 20 : 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(.white.opacity(0.3))
                )
            
        }
    }
}
