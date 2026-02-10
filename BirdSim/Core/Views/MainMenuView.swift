//
//  MainMenuView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/27/26.
//  Updated to main menu entry point on 2/2/26.
//

import SwiftUI
import SwiftData

struct MainMenuView: View {
    @State private var showingSettings = false
    @AppStorage("showingInstructions") var showingInstructions = true

    
    let container: ModelContainer
    let onStartNewGame: () -> Void
    let onResumeGame: () -> Void
    
    var hasSavedGame: Bool {
        (try? container.mainContext.fetch(FetchDescriptor<GameState>()).isEmpty == false) ?? false
    }
    
    var body: some View {
        
        Text("Take Flight - A Bird Life")

        
        VStack(spacing: 24) {
                        Button("Resume Game", action: onResumeGame)
                .buttonStyle(.bordered)
                .font(.title2)
                .padding(.horizontal, 40)
                .disabled(!hasSavedGame)
            Button("Start New Game", action: onStartNewGame)
                .buttonStyle(.borderedProminent)
                .font(.title2.bold())
                .padding(.horizontal, 40)
            Button("Instructions") {
                showingInstructions.toggle()
            }
                .buttonStyle(.borderedProminent)
                .font(.title2.bold())
                .padding(.horizontal, 40)
            Button("Settings") {
                showingSettings.toggle()
            }
                .buttonStyle(.borderedProminent)
                .font(.title2.bold())
                .padding(.horizontal, 40)
        }
        .padding(40)
        .background(.thinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .frame(maxWidth: 400)
        .frame(maxHeight: .infinity)
        .ignoresSafeArea(edges: .all)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingInstructions) {
            HowToPlayView()
        }
    }
}
