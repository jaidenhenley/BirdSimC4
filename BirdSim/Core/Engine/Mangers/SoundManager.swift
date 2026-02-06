//
//  SoundManager.swift
//  BirdSim
//
//  Created by George Clinkscales on 2/3/26.
//

import SwiftData
import AVFoundation

enum GameTrack: String {
    case mainMap = "awesomeness"
    case nestBuilding = "song18"
    case feedingUser = "DST-TowerDefenseTheme"
    case predator = "Invasion"
    case leaveMap = "one_0"
    case feedingBaby = "Cyberpunk Moonlight Sonata v2"
    
    var fileName: String { self.rawValue }
}

class SoundManager {
    static let shared = SoundManager()
    
    // Two players to allow for overlapping transitions
    private var musicPlayerA: AVAudioPlayer?
    private var musicPlayerB: AVAudioPlayer?
    private var isUsingPlayerA = true
    
    private var effectPlayers: [String: AVAudioPlayer] = [:]
    private(set) var currentTrack: String?

    private var isMusicEnabled: Bool = true
    private var musicVolume: Float = 0.5

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func startBackgroundMusic(track: GameTrack, fadeDuration: TimeInterval = 1.5) {
        let filename = track.fileName
        
        // Don't restart if already playing
        guard currentTrack != filename else { return }
        guard isMusicEnabled else { return }

        // Find file
        let extensions = ["wav", "mp3", "m4a"]
        var foundURL: URL?
        for ext in extensions {
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                foundURL = url
                break
            }
        }
        guard let url = foundURL else { return }

        do {
            // 1. Identify which player is new and which is old
            let oldPlayer = isUsingPlayerA ? musicPlayerA : musicPlayerB
            
            // 2. Setup the new player
            let freshlyLoadedPlayer = try AVAudioPlayer(contentsOf: url)
            freshlyLoadedPlayer.numberOfLoops = -1
            freshlyLoadedPlayer.volume = 0
            freshlyLoadedPlayer.prepareToPlay()
            freshlyLoadedPlayer.play()
            
            // 3. Crossfade
            freshlyLoadedPlayer.setVolume(musicVolume, fadeDuration: fadeDuration)
            oldPlayer?.setVolume(0, fadeDuration: fadeDuration)
            
            // 4. Clean up the old player after the fade
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
                oldPlayer?.stop()
            }
            
            // 5. Update state
            if isUsingPlayerA { musicPlayerB = freshlyLoadedPlayer } else { musicPlayerA = freshlyLoadedPlayer }
            isUsingPlayerA.toggle()
            currentTrack = filename
            
        } catch {
            print("❌ Crossfade Error: \(error)")
        }
    }

    func stopMusic() {
        musicPlayerA?.stop()
        musicPlayerB?.stop()
        currentTrack = nil
    }
    
    func setMusicEnabled(_ enabled: Bool) {
        isMusicEnabled = enabled
        if !enabled {
            stopMusic()
        }
    }

    func setMusicVolume(_ volume: Float) {
        musicVolume = volume
        musicPlayerA?.volume = volume
        musicPlayerB?.volume = volume
    }
    
    // MARK: - Sound Effects
    func playSoundEffect(named filename: String) {
        guard isMusicEnabled else { return }
        
        if let player = effectPlayers[filename] {
            player.currentTime = 0
            player.play()
        } else if let url = Bundle.main.url(forResource: filename, withExtension: "mp3") {
            do {
                let newPlayer = try AVAudioPlayer(contentsOf: url)
                effectPlayers[filename] = newPlayer
                newPlayer.play()
            } catch {
                print("Effect error: \(error)")
            }
        }
    }
} 

