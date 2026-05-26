//
//  InventoryView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/27/26.
//

import SwiftUI

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

struct InventoryView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    let isIPad: Bool

    var body: some View {
        if viewModel.controlsAreVisable {
            let screen = UIScreen.main.bounds
            let longEdge = max(screen.width, screen.height)
            let slotSize = longEdge * 0.045
            let wordWidth = longEdge * 0.12
            let barHeight = screen.height * 0.08
            
            
            HStack(spacing: screen.width * 0.008) {
                if isIPad {
                    Image(.inventoryWord)
                        .resizable()
                        .scaledToFit()
                        .frame(width: wordWidth)
                }
                
                Divider()
                    .frame(height: barHeight * 0.6)
                    .overlay(Color.white.opacity(0.3))
                
                ForEach(["leaf", "stick", "dandelion", "spiderweb"], id: \.self) { item in
                    ZStack {
                        Image(.inventoryBackground)
                            .resizable()
                            .scaledToFit()
                            .frame(width: slotSize, height: slotSize)
                        
                        if (viewModel.inventory[item] ?? 0) > 0 {
                            Image(ImageResource(name: item, bundle: .main))
                                .resizable()
                                .scaledToFit()
                                .frame(width: slotSize * 0.85, height: slotSize * 0.85)
                        }
                    }
                }
            }
            .padding(.horizontal, screen.width * 0.012)
            .padding(.vertical, screen.height * 0.01)
            .background(VisualEffectBlur(blurStyle: .systemMaterialDark))
            .cornerRadius(8)
            .shadow(radius: 8)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            }        }
    }
}

