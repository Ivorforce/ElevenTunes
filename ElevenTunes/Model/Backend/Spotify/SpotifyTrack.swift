//
//  SpotifyTrack+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import CoreData
import AVFoundation
import SpotifyWebAPI
import SwiftUI
import Combine

struct MinimalSpotifyTrack: Codable, Hashable {
    static let filters = "id"

    var id: String
}

public class SpotifyTrackToken: TrackToken, SpotifyURIConvertible {
    enum CodingKeys: String, CodingKey {
      case trackID
    }
    
    enum SpotifyError: Error {
        case noURI
    }

    var trackID: String

    public override var id: String { trackID }
    
    public var uri: String { "spotify:track:\(id)" }

    init(_ uri: String) {
        self.trackID = uri
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackID = try container.decode(String.self, forKey: .trackID)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trackID, forKey: .trackID)
        try super.encode(to: encoder)
    }
    
    static func trackID(fromURL url: URL) throws -> String {
        guard
            url.host == "open.spotify.com",
            url.pathComponents.dropFirst().first == "track",
            let id = url.pathComponents.last
        else {
            throw SpotifyError.noURI
        }
        return id
    }
    
    static func create(_ spotify: Spotify, fromURL url: URL) -> AnyPublisher<SpotifyTrackToken, Error> {
        return Future { try trackID(fromURL: url) }
            .flatMap { uri in
                spotify.api.track(uri).compactMap(ExistingSpotifyTrack.init)
            }
            .map { SpotifyTrackToken($0.id) }
            .eraseToAnyPublisher()
    }
    
    override func expand(_ context: Library) -> AnyTrack {
        SpotifyTrack(self, spotify: context.spotify)
    }
}

public class SpotifyTrack: RemoteTrack {
    let spotify: Spotify
    let token: SpotifyTrackToken
            
    init(_ token: SpotifyTrackToken, spotify: Spotify) {
        self.token = token
        self.spotify = spotify
        super.init()
    }

    init(track: ExistingSpotifyTrack, spotify: Spotify) {
        self.token = SpotifyTrackToken(track.id)
        self.spotify = spotify
        super.init()
        self.extractAttributes(from: track)
        // TODO Somehow the track might contain different attributes than our own request
//        contentSet.insert(.minimal)
    }

    public override var asToken: TrackToken { token }
    
    public override var accentColor: Color { Spotify.color }
    
    public override var origin: URL? {
        URL(string: "https://open.spotify.com/track/\(token.trackID)")
    }

    public override func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        let spotify = context.spotify
        
        let spotifyTrack = spotify.api.track(token)
            .compactMap(ExistingSpotifyTrack.init)
        let device = spotify.devices.$selected
            .compactMap { $0 }
            .eraseError()
        
        return spotifyTrack.combineLatest(device)
            .map({ (track, device) -> AnyAudioEmitter in
                RemoteAudioEmitter(SpotifyAudioEmitter(
                    spotify,
                    device: device,
                    context: .uris([track]),
                    track: track
                )) as AnyAudioEmitter
            })
            .eraseToAnyPublisher()
    }
    
    func extractAttributes(from track: ExistingSpotifyTrack, features: AudioFeatures? = nil) {
        self._attributes.value.merge(
            .init([
                .title: track.info.name
            ])
        )
        
        if let album = track.info.album, let albumID = album.id {
            self._album.value = SpotifyAlbum(albumID, album: album, spotify: spotify)
        }
        self._artists.value = (track.info.artists ?? [])
            .filter { $0.id != nil }
            .compactMap {
                SpotifyArtist($0.id!, attributes: .init([
                    .title: $0.name
                ]))
            }
        
        if let features = features {
            self._attributes.value.merge(
                .init([
                    .bpm: Tempo(features.tempo),
                    .key: MusicalKey(features.key)
                ])
            )
        }
    }
    
    public override func load(atLeast mask: TrackContentMask) {
        contentSet.promise(mask) { promise in
            let spotify = self.spotify
            
            spotify.api.track(token)
                .compactMap(ExistingSpotifyTrack.init)
                .zip(spotify.api.trackAudioFeatures(token))
                .onMain()
                .fulfillingAny(.minimal, of: promise)
                .sink(receiveCompletion: appLogErrors) { [unowned self] (track, features) in
                    self.extractAttributes(from: track, features: features)
                }
                .store(in: &cancellables)
        }
    }
}
