//
//  Library+Conversion.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import CoreData

extension Library {
    static func existingTracks(forBackends backends: Set<TrackToken>, context: NSManagedObjectContext) throws -> [TrackToken: DBTrack] {
        let fetchRequest = DBTrack.createFetchRequest()
        fetchRequest.predicate = .init(format: "backendID IN %@", backends.map { $0.id })
        let existing = try context.fetch(fetchRequest)
        let backendFor = { (track: DBTrack) in backends.first { $0.id == track.backendID }! }
        return Dictionary(uniqueKeysWithValues: existing.map { (backendFor($0), $0) })
    }
    
    static func existingPlaylists(forBackends backends: Set<PlaylistToken>, context: NSManagedObjectContext) throws -> [PlaylistToken: DBPlaylist] {
        let fetchRequest = DBPlaylist.createFetchRequest()
        fetchRequest.predicate = .init(format: "backendID IN %@", backends.map { $0.id })
        let existing = try context.fetch(fetchRequest)
        let backendFor = { (playlist: DBPlaylist) in backends.first { $0.id == playlist.backendID }! }
        return Dictionary(uniqueKeysWithValues: existing.map { (backendFor($0), $0) })
    }
    

    static func convert(_ library: DirectLibrary, context: NSManagedObjectContext) -> ([DBTrack], [DBPlaylist]) {
        guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
            fatalError("Failed to find model in MOC")
        }
        
        guard let trackModel = model.entitiesByName["DBTrack"],
              let playlistModel = model.entitiesByName["DBPlaylist"]
        else {
            fatalError("Failed to find track / playlist models in MOC")
        }
        
        // ================= Discover all static content =====================
        // (all deeper playlists' conversion can be deferred)
        
        var allTracks = Set(library.allTracks)
        var allPlaylists = Set<PlaylistToken>()
        
        // Unfold playlists
        for backend in flatSequence(first: library.allPlaylists, next: { backend in
            if let backend = backend as? TransientPlaylist {
                allTracks.formUnion(backend._tracks.map { $0.asToken })
                return backend._children.map { $0.asToken }
            }
            return []
        }) {
            allPlaylists.insert(backend)
        }

        // ================= Convert Tracks =====================

        let convertTrack = { (backend: TrackToken) -> DBTrack in
            if let backend = backend as? MockTrack {
                let dbTrack = DBTrack(entity: trackModel, insertInto: context)
                dbTrack.merge(attributes: backend._attributes)
                return dbTrack
            }
            
            let dbTrack = DBTrack(entity: trackModel, insertInto: context)
            dbTrack.backend = backend
            dbTrack.backendID = backend.id

            return dbTrack
        }

        let existingTracks = (try? Self.existingTracks(forBackends: allTracks, context: context)) ?? [:]
        
        let tracksByID = Dictionary(uniqueKeysWithValues: allTracks.map { ($0.id, existingTracks[$0] ?? convertTrack($0)) })
        
        // ================= Convert Playlists =====================
        // (tracks are guaranteed at this point)
        
        var playlistChildren: [DBPlaylist: [String]] = [:]
        
        let convertPlaylist = { (backend: PlaylistToken) -> DBPlaylist in
            if let backend = backend as? TransientPlaylist {
                let dbPlaylist = DBPlaylist(entity: playlistModel, insertInto: context)
                
                dbPlaylist.addToTracks(NSOrderedSet(array: backend._tracks.map { tracksByID[$0.id]! }))
                dbPlaylist.merge(attributes: backend._attributes)
                playlistChildren[dbPlaylist] = backend._children.map { $0.asToken.id }
                
                return dbPlaylist
            }
            
            let dbPlaylist = DBPlaylist(entity: playlistModel, insertInto: context)
            dbPlaylist.backend = backend
            dbPlaylist.backendID = backend.id
            
            return dbPlaylist
        }

        let existingPlaylists = (try? Self.existingPlaylists(forBackends: allPlaylists, context: context)) ?? [:]
        let playlistsByID = Dictionary(uniqueKeysWithValues: allPlaylists.map { ($0.id, existingPlaylists[$0] ?? convertPlaylist($0)) })
        
        // ================= Update Children =====================
        // (playlists are guaranteed at this point)

        for (playlist, children) in playlistChildren {
            playlist.addToChildren(NSOrderedSet(array: children.map { playlistsByID[$0]! }))
        }
                    
        // Finally, gather back what was originally asked
        return (
            library.allTracks.map { tracksByID[$0.id]! },
            library.allPlaylists.map { playlistsByID[$0.id]! }
        )
    }
}
