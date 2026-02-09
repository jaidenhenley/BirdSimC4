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
    var body: some View {
        if viewModel.controlsAreVisable {
            
            
            ZStack {
                
                HStack(spacing: 16) {
                    Image(.inventoryWord)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                    
                    ZStack {
                        Image(.inventoryBackground)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        if (viewModel.inventory["leaf"] ?? 0) > 0 {
                            
                            Image(.leaf)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        }
                    }
                    ZStack {
                        Image(.inventoryBackground)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        if (viewModel.inventory["stick"] ?? 0) > 0 {
                            
                            Image(.stick)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        }
                    }
                    ZStack {
                        Image(.inventoryBackground)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        
                        if (viewModel.inventory["dandelion"] ?? 0) > 0 {
                            Image(.dandelion)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        }
                    }
                    ZStack {
                        Image(.inventoryBackground)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        
                        if (viewModel.inventory["spiderweb"] ?? 0) > 0 {
                            Image(.spiderweb)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        }
                    }
                }
            }
            .frame(maxWidth: 500, maxHeight: 70)
            .background(VisualEffectBlur(blurStyle: .systemMaterialDark))
            .cornerRadius(8)
            .shadow(radius: 8)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            }
        }
    }
}

