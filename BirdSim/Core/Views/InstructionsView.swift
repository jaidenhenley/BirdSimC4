//
//  InstructionPage.swift
//  BirdSim
//
//  Created by George Clinkscales on 2/6/26.
//

import SwiftUI

struct InstructionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("How to Play")
                    .font(.system(.largeTitle, design: .rounded))
                    .bold()
                    .padding(.bottom, 8)
                
                // Survival Section
                InstructionRow(
                    icon: "heart.fill",
                    color: .red,
                    title: "Stay Fed",
                    description: "Your hunger bar is constantly draining. Find worms to stay alive!",
                    image: .caterpiller
                )
                
                // Combat Section
                InstructionRow(
                    icon: "bird.fill",
                    color: .orange,
                    title: "Watch Out",
                    description: "Avoid red birds! They are predators. You must avoid or defeat them to survive.", image: .Predator.predator
                )
                
                // Crafting Section
                InstructionRow(
                    icon: "hammer.fill",
                    color: .brown,
                    title: "Build a Nest",
                    description: "Collect spiderwebs, sticks, leaves, and dandelions. Take them to a nesting tree to create your home.", image: .spiderweb
                )
                
                // Family Section
                InstructionRow(
                    icon: "egg.fill",
                    color: .blue,
                    title: "Raise Your Young",
                    description: "Find a mate to spawn a baby. Feed the baby bird twice so it becomes strong enough to leave.", image: .Predator.maleBird
                )
                
                // Goal Section
                InstructionRow(
                    icon: "map.fill",
                    color: .green,
                    title: "Escape",
                    description: "Once your family is ready, find the bridge to leave the island.", image: .bridge
                )
                
                Spacer()
            }
            .padding()
        }
    }
}

// A reusable row component to keep code clean
struct InstructionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let image: ImageResource
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
            }
            if image == .spiderweb {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .background(
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(.green)
                    )
            } else {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
        }
    }
}

#Preview {
    InstructionsView()
}
