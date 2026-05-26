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
    enum MenuField: Hashable, CaseIterable {
        case resume, start, instructions, settings, gameCenter, credits
    }

    @State private var selectedIndex: Int = 0
    @FocusState private var isKeyboardActive: Bool

    @State private var showingSettings = false
    @AppStorage("showingInstructions") var showingInstructions = true
    @State private var showingCredits = false

    let container: ModelContainer
    let presentingViewController: UIViewController?
    let onStartNewGame: () -> Void
    let onResumeGame: () -> Void
    @StateObject private var viewModel: MainGameView.ViewModel

    init(
        container: ModelContainer,
        presentingViewController: UIViewController?,
        onStartNewGame: @escaping () -> Void,
        onResumeGame: @escaping () -> Void
    ) {
        self.container = container
        self.presentingViewController = presentingViewController
        self.onStartNewGame = onStartNewGame
        self.onResumeGame = onResumeGame
        _viewModel = StateObject(wrappedValue: MainGameView.ViewModel(context: container.mainContext))
    }

    var availableFields: [MenuField] {
        let all = MenuField.allCases
        return hasSavedGame ? all : all.filter { $0 != .resume }
    }

    var hasSavedGame: Bool {
        (try? container.mainContext.fetch(FetchDescriptor<GameState>()).isEmpty == false) ?? false
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(.loadingScreen)
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()

                Color.white.opacity(0.001)
                    .frame(width: 1, height: 1)
                    .focusable()
                    .focusEffectDisabled()
                    .focused($isKeyboardActive)
                    .onKeyPress(.upArrow) { moveSelection(up: true); return .handled }
                    .onKeyPress(.downArrow) { moveSelection(up: false); return .handled }
                    .onKeyPress(.return) { triggerSelection(); return .handled }
                    .onKeyPress(.space) { triggerSelection(); return .handled }

                if UIDevice.current.userInterfaceIdiom == .pad {
                    VStack(spacing: 24) {
                        ForEach(availableFields, id: \.self) { field in
                            Button(action: { tap(field) }) {
                                menuLabel(
                                    text: labelTitle(for: field),
                                    color: field == .start ? .blue : .black,
                                    isSelected: availableFields[selectedIndex] == field
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                } else {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            if hasSavedGame {
                                iphoneButton("Resume Game", background: Color(hex: "F5C518"), foreground: .black, field: .resume)
                            }
                            iphoneButton("Start New Game", background: Color(hex: "2196F3"), foreground: .white, field: .start)
                        }

                        let bottomFields: [MenuField] = [.instructions, .settings, .gameCenter, .credits]
                        ForEach(Array(stride(from: 0, to: bottomFields.count, by: 2)), id: \.self) { i in
                            HStack(spacing: 12) {
                                iphoneButton(labelTitle(for: bottomFields[i]), background: .black, foreground: .white, field: bottomFields[i])
                                iphoneButton(labelTitle(for: bottomFields[i + 1]), background: .black, foreground: .white, field: bottomFields[i + 1])
                            }
                        }
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 80)
                    .shadow(radius: 10)
                }
            }
            .onAppear { isKeyboardActive = true; selectedIndex = 0 }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingInstructions) {
                HowToPlayView(viewModel: viewModel, onStartNewGame: onStartNewGame)
            }
            .sheet(isPresented: $showingCredits) { CreditsView() }
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func labelTitle(for field: MenuField) -> String {
        switch field {
        case .resume: return "Resume Game"
        case .start: return "Start New Game"
        case .instructions: return "Instructions"
        case .settings: return "Settings"
        case .gameCenter: return "Game Center"
        case .credits: return "Credits"
        }
    }

    private func tap(_ field: MenuField) {
        if let index = availableFields.firstIndex(of: field) {
            selectedIndex = index
        }
        triggerSelection()
    }

    private func moveSelection(up: Bool) {
        SoundManager.shared.playEffect(.tink)
        if up {
            selectedIndex = selectedIndex == 0 ? availableFields.count - 1 : selectedIndex - 1
        } else {
            selectedIndex = selectedIndex == availableFields.count - 1 ? 0 : selectedIndex + 1
        }
    }

    private func triggerSelection() {
        let field = availableFields[selectedIndex]
        SoundManager.shared.playEffect(.tap)

        switch field {
        case .resume: onResumeGame()
        case .start: onStartNewGame()
        case .instructions: showingInstructions.toggle()
        case .settings: showingSettings.toggle()
        case .gameCenter:
            Task { @MainActor in
                guard let presentingViewController else { return }
                GameKitManager.shared.showGameCenterUI(from: presentingViewController)
            }
        case .credits: showingCredits.toggle()
        }
    }

    @ViewBuilder
    private func iphoneButton(_ title: String, background: Color, foreground: Color, field: MenuField) -> some View {
        let isSelected = availableFields[safe: selectedIndex] == field
        Button(action: { tap(field) }) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? Color(hex: "F5C518") : background, in: Capsule())
                .overlay(Capsule().stroke(Color.white, lineWidth: isSelected ? 3 : 0))
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func menuLabel(text: String, color: Color, isSelected: Bool) -> some View {
        Text(text)
            .foregroundStyle(isSelected ? .black : .white)
            .bold()
            .font(.title2)
            .frame(width: 250, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(isSelected ? Color.yellow : color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: isSelected ? 4 : 0)
                    )
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Extensions

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
