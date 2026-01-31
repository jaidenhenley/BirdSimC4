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

    // Health
    var health: Double = 1.0

    // Inventory counts (simple fields to avoid complex Codable storage)
    var inventoryStick: Int = 0
    var inventoryLeaf: Int = 0
    var inventorySpiderweb: Int = 0

    init() {}
}
