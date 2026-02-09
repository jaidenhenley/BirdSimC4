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
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How to Play")
                            .font(.system(.largeTitle, design: .rounded))
                            .bold()
                        
                        Text("Survive, build, and protect your nest.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                    
                    Group {
                        InstructionRow(
                            icon: "heart.fill",
                            color: .red,
                            title: "Stay Fed",
                            description: "Your hunger bar is constantly draining. Find worms to stay alive!",
                            image: .caterpiller
                        )
                        
                        InstructionRow(
                            icon: "bird.fill",
                            color: .orange,
                            title: "Watch Out",
                            description: "Avoid red birds! They are predators. You must avoid or defeat them to survive.",
                            image: .Predator.predator
                        )
                        
                        InstructionRow(
                            icon: "hammer.fill",
                            color: .blue,
                            title: "Build a Nest",
                            description: "Collect spiderwebs, sticks, leaves, and dandelions. Take them to a nesting tree.",
                            image: .nest
                        )
                        
                        MultiImageInstructionRow(
                            icon: "hand.wave",
                            color: .cyan,
                            title: "Collect Items to Build a Nest",
                            description: "These are the items you will need .",
                            images: [.dandelion, .spiderweb, .stick, .leaf]
                        )
                        
                        InstructionRow(
                            icon: "heart.text.square.fill",
                            color: .blue,
                            title: "Raise Your Young",
                            description: "Find a mate and feed the baby bird twice until it's strong enough to fly.",
                            image: .Predator.maleBird
                        )
                        
                        InstructionRow(
                            icon: "map.fill",
                            color: .green,
                            title: "Escape",
                            description: "Once your family is ready, find the bridge to leave the island.",
                            image: .bridge
                        )
                        
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Reusable Asset Box
struct AssetBox: View {
    let image: ImageResource
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // 1. Base Layer (Light Gray)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.12))
            
            // 2. Contrast Layer (Subtle Darken)
            // This is the key: it darkens the "well" just enough to make white lines pop
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.12))
                .padding(2) // Creates a slight border effect with the base layer
            
            // 3. The Asset
            Image(image)
                .resizable()
                .scaledToFit()
                .padding(size * 0.18)
                // 4. Strong Edge Definition
                // This adds a dark outline to the asset itself
                .shadow(color: .black.opacity(0.4), radius: 0.5, x: 0, y: 0.5)
                .shadow(color: .black.opacity(0.4), radius: 0.5, x: 0, y: -0.5)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Row Components

struct InstructionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let image: ImageResource
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon).foregroundColor(color).font(.headline)
                    Text(title).font(.headline)
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            AssetBox(image: image, size: 80)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MultiImageInstructionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let images: [ImageResource]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: icon).foregroundColor(color)
                        Text(title).font(.headline)
                    }
                    Text(description).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<images.count, id: \.self) { index in
                        AssetBox(image: images[index], size: 80)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    InstructionsView()
}
