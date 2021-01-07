//
//  LibraryPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Cocoa
import SwiftUI
import Combine
import CombineExt

class LibraryPlaylist: AnyPlaylist {
    let managedObjectContext: NSManagedObjectContext
    var playContext: PlayContext

    @Published var staticPlaylists: [AnyPlaylist] = []

    var cancellables = Set<AnyCancellable>()
    var library: Library?  // Weak because reference cycle
        
    init(library: Library, playContext: PlayContext) {
        self.managedObjectContext = library.managedObjectContext
        self.playContext = playContext
        self.library = library
        
        _tracks = CDPublisher(request: DBTrack.createFetchRequest(), context: managedObjectContext)
            // TODO Apparently, sometimes the same object is emitted twice
            .map { $0.removeDuplicates() }
            .removeDuplicates()
            .flatMap {
                $0.map { [weak self] in self!.library!.track(cachedBy: $0) }
                    .combineLatest()
            }
            .replaceError(with: [])
            .eraseToAnyPublisher()

        _children = CDPublisher(request: LibraryPlaylist.playlistFetchRequest, context: managedObjectContext)
            // TODO Apparently, sometimes the same object is emitted twice
            .map { $0.removeDuplicates { $0.uuid } }
            .removeDuplicates()
            .flatMap {
                $0
                    .map { [weak self] in self!.library!.playlist(cachedBy: $0) }
                    .combineLatest()
            }
            .combineLatest($staticPlaylists.eraseError()).map { $1 + $0 }
            .replaceError(with: [])
            .eraseToAnyPublisher()
                
        staticPlaylists = [
            SpotifyUser(spotify: library.spotify)
        ]
    }
    
    var id: String {
        "Library" // TODO
    }
    
    var contentType: PlaylistContentType { .hybrid }
    
    var origin: URL? { nil }
    
    var accentColor: Color { .accentColor }
    
    var hasCaches: Bool { false }
    
    var asToken: PlaylistToken { fatalError()}
    
    func cacheMask() -> AnyPublisher<PlaylistContentMask, Never> {
        Just([.minimal, .children, .tracks, .attributes]).eraseToAnyPublisher()
    }
    
    var _tracks: AnyPublisher<[AnyTrack], Never>!
    func tracks() -> AnyPublisher<[AnyTrack], Never> {
        _tracks
    }
    
    var _children: AnyPublisher<[AnyPlaylist], Never>!
    func children() -> AnyPublisher<[AnyPlaylist], Never> {
        _children
    }
    
    // TODO
    @Published var _attributes: TypedDict<PlaylistAttribute> = .init()
    func attributes() -> AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }
    
    func previewImage() -> AnyPublisher<NSImage?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    static var playlistFetchRequest: NSFetchRequest<DBPlaylist> {
        let request = DBPlaylist.createFetchRequest()
        request.predicate = NSPredicate(format: "parent == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return request
    }
    
    func load(atLeast mask: PlaylistContentMask, library: Library) {
        // TODO Deep
    }
    
    func invalidateCaches(_ mask: PlaylistContentMask) {
        // We have no caches per se, everything is stream
    }
    
    var icon: Image { Image(systemName: "house.fill" ) }
            
    func `import`(library: AnyLibrary) -> Bool {
        guard let defaultPlaylist = self.library?.defaultPlaylist else {
            return false
        }

        return Library.import(library, to: defaultPlaylist)
    }
}
