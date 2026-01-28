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
        VStack {
            Text("Bird Inventory")
                .font(.headline)
                .padding()
            
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(viewModel.inventory.sorted(by: >), id: \.key) { name, count in
                        HStack {
                            //Map the name to an custom icon currently an emoji
                            Text(name == "stick" ? "🪵" : "🍃")
                                .font(.system(size: 40))
                            
                            Text(name.capitalized)
                                .font(.body)
                            
                            Spacer()
                            
                            Text("x\(count)")
                                .bold()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                    }
                }
                .padding()
            }
            
            Button("Close") {
                viewModel.showInventory = false
            }
            .padding()
        }
        .frame(maxWidth: 300, maxHeight: 400)
        .background(VisualEffectBlur(blurStyle: .systemMaterialDark))
        .cornerRadius(20)
        .shadow(radius: 20)
    }
}
