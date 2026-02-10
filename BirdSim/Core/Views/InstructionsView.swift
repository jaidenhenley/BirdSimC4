//
//  InstructionPage.swift
//  BirdSim
//
//  Created by George Clinkscales on 2/6/26.
//

import SwiftUI

struct InstructionsView: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How to Play")
                            .font(.system(.largeTitle, design: .rounded))
                            .bold()
                        
                        Text("Survive, build, and protect your nest.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Core Mechanics
                    VStack(spacing: 16) {
                        InstructionRow(icon: "heart.fill", color: .red, title: "Stay Fed", description: "Your hunger bar is constantly draining. Find worms to stay alive!", image: .caterpiller)
                        
                        InstructionRow(icon: "bird.fill", color: .orange, title: "Watch Out", description: "Avoid red birds! They are predators. You must avoid or defeat them to survive.", image: .Predator.predator)
                        
                        InstructionRow(icon: "hammer.fill", color: .blue, title: "Build a Nest", description: "Collect spiderwebs, sticks, leaves, and dandelions. Take them to a nesting tree.", image: .nest)
                        
                        // Updated to use the Inventory Backgrounds
                        MultiImageInstructionRow(
                            icon: "hand.wave",
                            color: .cyan,
                            title: "Collect Materials",
                            description: "Gather these four items to begin building your nest.",
                            images: [.dandelion, .spiderweb, .stick, .leaf]
                        )
                        
                        InstructionRow(icon: "heart.text.square.fill", color: .blue, title: "Raise Your Young", description: "Find a mate and feed the baby bird twice until it's strong enough to fly.", image: .Predator.maleBird)
                        
                        InstructionRow(icon: "map.fill", color: .green, title: "Escape", description: "Once your family is ready, find the bridge to leave the island.", image: .bridge)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - HUD Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("HUD Indicators")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        VStack(spacing: 20) {
                            HUDRow(iconImage: .predatorBarBird, wordImage: .predatorBarWord, barColor: .red, text: "The Predator Bar shows how close a red bird is to spotting you.")
                            
                            HUDRow(iconImage: .babyBirdNest, wordImage: .babyBirdWord, barColor: .blue, text: "The Nest Bar tracks your baby's hunger and growth progress.")
                            
                            // Inventory Bar
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack {
                                    Color.black.opacity(0.3)
                                        .frame(height: 60)
                                        .cornerRadius(8)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                        }
                                    
                                    HStack(spacing: 12) {
                                        Image(.inventoryWord)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100)
                                        
                                        HStack(spacing: 8) {
                                            InventorySlotPlaceholder(image: .leaf)
                                            InventorySlotPlaceholder(image: .stick)
                                            InventorySlotPlaceholder(image: .dandelion)
                                            InventorySlotPlaceholder(image: .spiderweb)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                }
                                
                                Text("The Inventory Bar shows which building materials you are carrying.")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.vertical)
            }
        }
    }
}

// MARK: - Inventory Slot Pattern (Used in the Bar and Rows)
struct InventorySlotPlaceholder: View {
    let image: ImageResource
    var size: CGFloat = 42
    
    var body: some View {
        ZStack {
            Image(.inventoryBackground)
                .resizable()
                .frame(width: size, height: size)
            
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.75, height: size * 0.75)
        }
    }
}

// MARK: - Updated Multi-Image Row with Inventory Backgrounds
struct MultiImageInstructionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let images: [ImageResource]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(color).bold()
                Text(title).font(.headline)
            }
            Text(description).font(.subheadline).foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                ForEach(images, id: \.self) { img in
                    InventorySlotPlaceholder(image: img, size: 60)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Updated Standard Instruction Row
struct InstructionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let image: ImageResource
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon).foregroundColor(color).font(.subheadline).bold()
                    Text(title).font(.headline)
                }
                Text(description).font(.subheadline).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            // Consistent Inventory Style for single images too
            InventorySlotPlaceholder(image: image, size: 70)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - HUD Row Pattern
struct HUDRow: View {
    let iconImage: ImageResource?
    let wordImage: ImageResource
    let barColor: Color
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Color.black.opacity(0.3)
                    .frame(height: 60)
                    .cornerRadius(8)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    }
                
                HStack(spacing: 10) {
                    if let icon = iconImage {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                    }
                    
                    Image(wordImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(barColor)
                                .frame(width: 25, height: 12)
                                .opacity(index < 2 ? 1.0 : 0.2)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
            
            Text(text)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
