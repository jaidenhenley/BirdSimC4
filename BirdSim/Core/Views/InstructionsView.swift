//
//  InstructionPage.swift
//  BirdSim
//
//  Created by George Clinkscales on 2/6/26.
//

import SwiftUI

// MARK: - Main View
struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Hero Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Survival Guide")
                                .font(.system(.largeTitle, design: .rounded).bold())
                            Text("Master the art of flight, gather vital resources, and lead your family to safety.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        // MARK: - 1. Platform Selection
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Controls & Input", icon: "gamecontroller.fill")
                            
                            VStack(spacing: 0) {
                                ControlTypeRow(
                                    title: "Keyboard",
                                    icons: ["keyboard", "command"],
                                    description: "Best for desktop play. Use WASD to move and Shift to fly."
                                )
                                
                                Divider()
                                    .padding(.horizontal)
                                
                                ControlTypeRow(
                                    title: "Touch Screen",
                                    icons: ["hand.tap", "iphone"],
                                    description: "Use the on-screen joystick to move and tap buttons to fly."
                                )
                            }
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
                        }
                        .padding(.horizontal)
                        
                        // MARK: - 2. Flight & Controls Details
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Action Reference", icon: "wind")
                            
                            VStack(alignment: .leading, spacing: 20) {
                                ControlRow(icon: "arrow.up.and.down.and.arrow.left.right", key: "WASD", title: "Navigation", desc: "Navigate through the island. Walking allows for precise resource gathering, while flying covers distance.")
                                
                                ControlRow(icon: "airplane", key: "SHFT", title: "Flight Toggle", desc: "Switch between walking and flying. Note: Hunger drains at a constant rate regardless of your speed.")
                                
                                ControlRow(icon: "hand.tap.fill", key: "SPC", title: "Interaction", desc: "Pick up building materials, grab caterpillars, or feed the young in your nest.")
                                
                                ControlRow(icon: "map.fill", key: "M", title: "Map View", desc: "Toggle the topographic map to locate nesting trees and identify the bridge.")
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
                        }
                        .padding(.horizontal)
                        
                        // MARK: - 3. Survival Basics (Updated for Minigames)
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Daily Survival", icon: "heart.fill")
                            
                            InstructionRow(
                                icon: "fork.knife",
                                color: .green,
                                title: "The Feeding Game",
                                description: "Locate caterpillars and complete the 'Feed' minigame to gain points and maintain energy.",
                                tip: "Keep your energy high to avoid health loss!",
                                image: .caterpiller
                            )
                            
                            InstructionRow(
                                icon: "exclamationmark.triangle.fill",
                                color: .orange,
                                title: "Predator Escape",
                                description: "If caught by a red bird, you must win the struggle minigame to escape. Successful escapes award bonus points.",
                                tip: "Avoid them entirely to save your energy.",
                                image: .Predator.predator
                            )
                        }
                        .padding(.horizontal)

                        // MARK: - 4. Building & Legacy
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Nesting & Growth", icon: "house.fill")
                            
                            // 1. Build
                            InstructionRow(
                                icon: "hammer.fill",
                                color: .blue,
                                title: "Build the Nest",
                                description: "Collect a dandelion, spiderweb, stick, and leaf to complete the Nesting Minigame.",
                                tip: "Once built, your nest is ready for a family!",
                                image: .babyBirdNest
                            )
                            
                            // 2. Locate Mate (Blue Bird)
                            InstructionRow(
                                icon: "heart.fill",
                                color: .cyan,
                                title: "Find Your Mate",
                                description: "Locate the blue bird on the island. Finding them is the only way to spawn the baby in your newly built nest.",
                                tip: "Keep an eye out for a flash of blue in the trees!",
                                image: .Predator.maleBird // This is the blue bird image
                            )
                            
                            // 3. Survival Challenge
                            InstructionRow(
                                icon: "timer",
                                color: .purple,
                                title: "The 2-Minute Challenge",
                                description: "Once the baby bird hatches, you must feed it TWICE within 2 minutes.",
                                tip: "CRITICAL: Fail to feed them in time and you lose the baby and points!",
                                image: .birdnest // Updated to the birdnest image
                            )
                        }
                        .padding(.horizontal)

                        // MARK: - 5. Interface (HUD)
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Heads-Up Display", icon: "eye.fill")
                            
                            VStack(spacing: 20) {
                                // --- 1. Point Tracker ---
                                HStack {
                                    Image(systemName: "star.circle.fill").foregroundColor(.yellow).font(.title2)
                                    VStack(alignment: .leading) {
                                        Text("Total Score").font(.subheadline.bold())
                                        Text("Gain points through minigames and feeding.").font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("PTS").font(.system(.caption, design: .monospaced).bold())
                                        .padding(4).background(RoundedRectangle(cornerRadius: 4).fill(Color.yellow.opacity(0.2)))
                                }
                                
                                Divider()
                                
                                // --- 2. Status Bars ---
                                HUDRow(iconImage: .hungerBarBird, wordImage: .hungerBarWord, barColor: .green, title: "Hunger Meter", text: "Drains over time. Play the Caterpillar minigame.")
                                
                                HUDRow(iconImage: .predatorBarBird, wordImage: .predatorBarWord, barColor: .red, title: "Threat Level", text: "Fills when predators are near. Win the escape game.")
                                
                                HUDRow(iconImage: .babyBirdNest, wordImage: .babyBirdWord, barColor: .blue, title: "Nesting Timer", text: "Feed the baby twice in 2 minutes or lose points.")
                                
                                Divider()
                                
                                // --- 3. Visual Inventory HUD (The original look) ---
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "briefcase.fill").foregroundColor(.secondary).font(.subheadline)
                                        Text("Material Inventory").font(.subheadline.bold())
                                        Spacer()
                                        Text("Required for Nesting").font(.caption).foregroundColor(.secondary)
                                    }
                                    
                                    // This is the visual grid you remember
                                    HStack(spacing: 12) {
                                        InventorySlotPlaceholder(image: .dandelion, size: 45)
                                        InventorySlotPlaceholder(image: .spiderweb, size: 45)
                                        InventorySlotPlaceholder(image: .stick, size: 45)
                                        InventorySlotPlaceholder(image: .leaf, size: 45)
                                        
                                        Spacer() // Pushes slots to the left
                                    }
                                    
                                    Text("Collect one of each to trigger the Nesting Minigame.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(20)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ready to Fly") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - Reusable Components

struct ControlTypeRow: View {
    let title: String
    let icons: [String]
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            // Fixed-width container for icons to ensure alignment
            ZStack {
                ForEach(0..<icons.count, id: \.self) { index in
                    Image(systemName: icons[index])
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                        // Offset the second icon slightly for the "stacked" look
                        .offset(x: index == 0 ? -10 : 10)
                }
            }
            .frame(width: 70) // This keeps the text aligned perfectly
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.blue).font(.callout.bold())
            Text(title.uppercased())
                .font(.caption.bold())
                .tracking(1.2)
                .foregroundColor(.secondary)
        }
    }
}

struct ControlRow: View {
    let icon: String
    let key: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 20) { // Increased spacing between icon and text
            ControlButtonPlaceholder(icon: icon, label: title, key: key)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3) // Prevents the description from getting too long
            }
        }
        .padding(.vertical, 4) // Add a little vertical padding between rows
    }
}

struct InstructionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let tip: String
    let image: ImageResource
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon).foregroundColor(color).font(.headline)
                    Text(title).font(.headline)
                }
                Text(description).font(.subheadline).foregroundColor(.primary.opacity(0.8))
                Text(tip).font(.caption).italic().foregroundColor(color)
            }
            Spacer()
            InventorySlotPlaceholder(image: image, size: 65)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
}

struct MultiImageInstructionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let tip: String
    let images: [ImageResource]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(color).font(.headline)
                Text(title).font(.headline)
            }
            Text(description).font(.subheadline).foregroundColor(.secondary)
            HStack(spacing: 8) {
                ForEach(images, id: \.self) { img in
                    InventorySlotPlaceholder(image: img, size: 50)
                }
            }
            Text(tip).font(.caption).italic().foregroundColor(.blue)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
}

struct HUDRow: View {
    let iconImage: ImageResource?
    let wordImage: ImageResource
    let barColor: Color
    let title: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = iconImage { Image(icon).resizable().scaledToFit().frame(width: 25, height: 25) }
                Text(title).font(.subheadline.bold())
                Spacer()
                Image(wordImage).resizable().scaledToFit().frame(height: 12)
            }
            HStack(spacing: 4) {
                ForEach(0..<8, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2).fill(barColor).frame(height: 10).opacity(index < 3 ? 1.0 : 0.2)
                }
            }
            Text(text).font(.caption).foregroundColor(.secondary)
        }
    }
}

struct ControlButtonPlaceholder: View {
    let icon: String
    let label: String
    let key: String
    
    var body: some View {
        VStack(spacing: 10) { // Increased spacing
            ZStack(alignment: .topTrailing) {
                // The Main Button Circle
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                
                // The Icon
                Image(systemName: icon)
                    .font(.system(size: 20)) // Fixed size to prevent smashing
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50) // Center it in the circle
                
                // The Key Label (Keyboard Indicator)
                Text(key)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white))
                    .offset(x: 8, y: -8) // Shifted out slightly to avoid the icon
                    .shadow(radius: 2)
            }
            
            // The Action Text (Navigation, Flight, etc.)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true) // Prevents text clipping
        }
        .frame(width: 65) // Ensure the whole column has enough space
    }
}

struct InventorySlotPlaceholder: View {
    let image: ImageResource
    var size: CGFloat = 42
    var body: some View {
        ZStack {
            Image(.inventoryBackground).resizable().frame(width: size, height: size)
            Image(image).resizable().scaledToFit().frame(width: size * 0.7, height: size * 0.7)
        }
    }
}
