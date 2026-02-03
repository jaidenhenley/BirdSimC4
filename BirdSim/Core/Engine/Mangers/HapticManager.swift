//
//  HapticManager.swift
//  BirdSim
//
//  Created by George Clinkscales on 2/3/26.
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    enum HapticType {
        case light, medium, heavy, success, error, selection
    }
    
    func trigger(_ type: HapticType) {
        // Check UserDefaults to respect user settings
        guard UserDefaults.standard.bool(forKey: "haptics_enabled") else { return }
        
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}
