//
//  BreakVideo.swift
//  Horizon
//
//  Plays a calming nature clip behind the break message. Clips are optional: if
//  none are bundled, the break screen falls back to a calm gradient (see
//  BreakView), so the app works with or without video.
//
//  Clips are looked up from the app bundle by extension, so any .mp4/.mov/.m4v
//  dropped into the project is picked up automatically. We use AVQueuePlayer +
//  AVPlayerLooper for gap-free looping of a local file, drawn by an AVPlayerLayer
//  scaled to fill the screen.
//

import SwiftUI
import AppKit
import AVFoundation

/// Finds the calming break clips bundled in the app (if any).
enum BreakVideoLibrary {

    /// Every bundled clip. Empty if none are bundled (→ gradient fallback).
    /// Checks both the Resources root and a "BreakVideos" subfolder, since Xcode
    /// may or may not flatten the folder into the bundle.
    static var allClips: [URL] {
        let extensions = ["mp4", "mov", "m4v"]
        let subdirectories: [String?] = [nil, "BreakVideos"]
        var urls: [URL] = []
        for ext in extensions {
            for subdirectory in subdirectories {
                urls += Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: subdirectory) ?? []
            }
        }
        return Array(Set(urls))   // de-dupe if both lookups find the same file
    }

    /// A clip chosen at random for this break, or nil if none are bundled.
    static func randomClip() -> URL? {
        allClips.randomElement()
    }
}

/// A SwiftUI background that plays a video, looping seamlessly, scaled to fill.
struct VideoBackgroundView: NSViewRepresentable {
    let url: URL
    let muted: Bool

    func makeNSView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        context.coordinator.start(in: view, url: url, muted: muted)
        return view
    }

    func updateNSView(_ nsView: PlayerContainerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator {
        // Strong references: an AVPlayerLooper stops looping if it is deallocated.
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?

        func start(in view: PlayerContainerView, url: URL, muted: Bool) {
            let item = AVPlayerItem(url: url)
            let queue = AVQueuePlayer()
            let looper = AVPlayerLooper(player: queue, templateItem: item)
            queue.isMuted = muted
            queue.automaticallyWaitsToMinimizeStalling = false   // start instantly (local file)
            view.playerLayer.videoGravity = .resizeAspectFill
            view.playerLayer.player = queue
            queue.play()
            self.player = queue
            self.looper = looper
        }
    }
}

/// A layer-backed NSView whose backing layer hosts an AVPlayerLayer.
final class PlayerContainerView: NSView {
    let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        playerLayer.frame = bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}
