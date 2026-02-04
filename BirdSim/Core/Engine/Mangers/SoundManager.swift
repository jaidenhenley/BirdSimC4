//
//  SoundManager.swift
//  BirdSim
//
//  Created by George Clinkscales on 2/3/26.
//

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
    
    private var musicPlayer: AVAudioPlayer?
    private var effectPlayers: [String: AVAudioPlayer] = [:]
    private(set) var currentTrack: String?

    private init() {
        // Change to .playback so the physical silent switch doesn't mute the game
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - Background Music
    func startBackgroundMusic(track: GameTrack) {
        let filename = track.fileName
        
        guard currentTrack != filename || musicPlayer?.isPlaying == false else { return }
        guard UserDefaults.standard.bool(forKey: "is_music_enabled") else { return }

        let extensions = ["wav", "mp3", "m4a"]
        var foundURL: URL?
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                foundURL = url
                break
            }
        }

        guard let url = foundURL else {
            print("❌ Audio Error: \(filename) not found")
            return
        }

        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = 0.0
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
            
            // Smoothly ramp up volume
            musicPlayer?.setVolume(0.5, fadeDuration: 1.5)
            
            currentTrack = filename
        } catch {
            print("❌ Could not play music: \(error)")
        }
    }
    
    func stopMusic() {
        musicPlayer?.stop()
        currentTrack = nil
    }
    
    // MARK: - Sound Effects
    func playSoundEffect(named filename: String) {
        guard UserDefaults.standard.bool(forKey: "is_sound_enabled") else { return }
        
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
