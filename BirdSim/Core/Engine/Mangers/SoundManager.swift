//
//  SoundManager.swift
//  BirdSim
//
//  Created by George Clinkscales on 2/3/26.
//

import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var musicPlayer: AVAudioPlayer?
    private var effectPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        // Set up Audio Session so it plays even if the silent switch is on (optional)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - Background Music
    func startBackgroundMusic(named filename: String) {
        guard UserDefaults.standard.bool(forKey: "is_music_enabled"),
              let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else { return }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1 // Loop forever
            musicPlayer?.volume = 0.5
            musicPlayer?.play()
        } catch {
            print("Could not play music: \(error)")
        }
    }
    
    func stopMusic() {
        musicPlayer?.stop()
    }
    
    // MARK: - Sound Effects
    func playSoundEffect(named filename: String) {
        guard UserDefaults.standard.bool(forKey: "is_sound_enabled") else { return }
        
        // Cache players for performance
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
