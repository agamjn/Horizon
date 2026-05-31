//
//  BreakAudio.swift
//  Horizon
//
//  Optional soothing ambient audio for the break screen. Tracks are looked up
//  from the bundle by extension (like the videos) and are optional: if none are
//  bundled, the break is silent (or uses a video clip's own audio). When an ambient
//  track *is* present it plays on every break and the video is muted, so the
//  soothing audio is consistent regardless of which (often-silent) clip is showing.
//

import Foundation
import AVFoundation

/// Finds optional ambient audio tracks bundled in the app.
enum BreakAudioLibrary {

    /// Every bundled audio track. Empty if none are bundled.
    static var allTracks: [URL] {
        let extensions = ["mp3", "m4a", "aac", "wav", "caf", "aiff"]
        let subdirectories: [String?] = [nil, "BreakAudio"]
        var urls: [URL] = []
        for ext in extensions {
            for subdirectory in subdirectories {
                urls += Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: subdirectory) ?? []
            }
        }
        return Array(Set(urls))
    }

    /// A track chosen at random for this break, or nil if none are bundled.
    static func randomTrack() -> URL? {
        allTracks.randomElement()
    }
}

/// Plays a soothing ambient track on a loop for the duration of a break.
@MainActor
final class AmbientAudioPlayer {

    private var player: AVAudioPlayer?

    /// Whether a track is actually playing right now.
    var isPlaying: Bool { player != nil }

    /// Begin looping the given track with a gentle fade-in.
    func start(url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1          // loop indefinitely
            player.volume = 0
            player.prepareToPlay()
            player.play()
            player.setVolume(0.6, fadeDuration: 1.5)
            self.player = player
        } catch {
            NSLog("Horizon: ambient audio failed to load: \(error.localizedDescription)")
            self.player = nil
        }
    }

    /// Stop and release the player.
    func stop() {
        player?.stop()
        player = nil
    }
}
