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
            
            VStack {
                Text("Bird Inventory")
                    .font(.headline)
                    .padding()
                HStack(spacing: 15) {
                    ForEach(viewModel.inventory.sorted(by: >), id: \.key) { name, count in
                        // ONLY show the row if the count is greater than zero
                        if count > 0 {
                            HStack {
                                // Map the name to a custom icon
                                if name == "stick" {
                                    Text("🪵")
                                } else if name == "leaf" {
                                    Text("🍃")
                                } else if name == "spiderweb" {
                                    
                                    Text("🕸️")
                                } else if name == "dandelion" {
                                    Text("🌼")
                                }
                                
                                Text(name.capitalized)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("x\(count)")
                                    .bold()
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: 500, maxHeight: 100)
            .background(VisualEffectBlur(blurStyle: .systemMaterialDark))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
    }
}
