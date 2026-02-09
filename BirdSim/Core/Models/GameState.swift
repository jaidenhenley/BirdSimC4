import Foundation
import SwiftData

@Model
final class GameState {
    var id: UUID = UUID()

    // Player / camera positions
    var playerX: Double = 200
    var playerY: Double = 400
    var cameraX: Double = 200
    var cameraY: Double = 400

    // Gameplay flags
    var isFlying: Bool = false
    var controlsAreVisable: Bool = true
    var gameStarted: Bool = false
    var showGameOver: Bool = false
    var showGameWin: Bool = false

    // Hunger
    var hunger: Double = 5.0

    // Inventory counts (simple fields to avoid complex Codable storage)
    var inventoryStick: Int = 0
    var inventoryLeaf: Int = 0
    var inventorySpiderweb: Int = 0
    var inventoryDandelion: Int = 0

    
    var userScore: Int = 0
    
    // babybirdnestgame saved variables
    var hasFoundMale: Bool = false
    var hasPlayedBabyGame: Bool = false
    var isBabyReadyToGrow: Bool = false
    var userFedBabyCount: Int = 0
    
    // MARK: - Nest Persistence
    
    var hasNest: Bool = false
    var nestX: Double = 0
    var nestY: Double = 0

    var hasBaby: Bool = false
    var babyX: Double = 0
    var babyY: Double = 0

    // Stores Date().timeIntervalSince1970
    var babySpawnTimestamp: Double = 0


    init() {}
}

