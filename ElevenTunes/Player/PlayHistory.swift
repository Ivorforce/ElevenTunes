//
//  PlayHistory.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine

class PlayHistory {
    @Published private(set) var queue: [Track]
    @Published private(set) var history: [Track] = []

    // previous = history.last, next = queue.first
    @Published private(set) var previous: Track?
    @Published private(set) var current: Track?
    @Published private(set) var next: Track?
    
    init(_ queue: [Track] = [], history: [Track] = []) {
        self.queue = queue
        self.history = history
        
        $queue.map(\.first).assign(to: &$next)
        $history.map(\.last).assign(to: &$previous)
    }
    
    convenience init(_ playlist: Playlist, at track: Track) {
        let tracks = playlist._tracks
        let trackIdx = tracks.firstIndex { $0.id == track.id }
        if trackIdx == nil {
            appLogger.error("Failed to find \(track) in \(playlist)")
        }
        let idx = trackIdx ?? 0
        
        self.init(Array(tracks[idx...].map(Track.init)), history: Array(tracks[..<idx].map(Track.init)))
    }
        
    @discardableResult
    func forwards() -> Track? {
        // Move forwards in replacements so that no value is missing at any point
        if let current = current { history.append(current) }
        current = queue.first
        _ = queue.popFirst()
        
        return current
    }
    
    @discardableResult
    func backwards() -> Track? {
        // Move backwards in replacements so that no value is missing at any point
        if let current = current { queue.prepend(current) }
        current = history.last
        _ = history.popLast()
        
        return current
    }
}
