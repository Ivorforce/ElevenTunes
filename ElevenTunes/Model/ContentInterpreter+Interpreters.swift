//
//  ContentInterpreter+Interpreters.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import Foundation
import Combine
import UniformTypeIdentifiers

extension ContentInterpreter {
    static func simple(matches: @escaping (URL) throws -> Bool, interpret: @escaping (URL) -> AnyPublisher<Content, Error>) -> ((URL) -> AnyPublisher<Content, Error>?) {
        return { url in
            if !((try? matches(url)) ?? false) { return nil }
            return interpret(url)
                .eraseToAnyPublisher()
        }
    }

    static func simple(matches: @escaping (URL) throws -> Bool, interpret: @escaping (URL) throws -> Content) -> ((URL) -> AnyPublisher<Content, Error>?) {
        return { url in
            if !((try? matches(url)) ?? false) { return nil }
            return Future { try interpret(url) }
                .eraseToAnyPublisher()
        }
    }

    // TODO Split up properly
    static func createDefault(spotify: Spotify) -> ContentInterpreter {
        let interpreter = ContentInterpreter()
        
        let register = { interpreter.interpreters.append($0) }
        
        register(simple {
            _ = try SpotifyTrackToken.trackID(fromURL: $0)
            return true
        } interpret: {
            SpotifyTrackToken.create(spotify, fromURL: $0)
                .map { Content.track($0) }
                .eraseToAnyPublisher()
        })
        
        register(simple {
            _ = try SpotifyPlaylistToken.playlistID(fromURL: $0)
            return true
        } interpret: { (url: URL) -> AnyPublisher<Content, Error> in
            SpotifyPlaylistToken.create(spotify, fromURL: url)
                .map { Content.playlist($0) }
                .eraseToAnyPublisher()
        })
        
        register(simple {
            _ = try SpotifyUserPlaylistToken.userID(fromURL: $0)
            return true
        } interpret: { (url: URL) -> AnyPublisher<Content, Error> in
            SpotifyUserPlaylistToken.create(spotify, fromURL: url)
                .map { Content.playlist($0) }
                .eraseToAnyPublisher()
        })
        
        register(simple { $0.pathExtension == "m3u" } interpret: {
            .playlist(try M3UPlaylistToken.create(fromURL: $0))
        })
        
        register(simple {
            try $0.isFileDirectory()
        } interpret: {
            .playlist(try DirectoryPlaylistToken.create(fromURL: $0))
        })
        
        register(simple(matches: FileVideoToken.understands) {
            .track(try FileVideoToken.create(fromURL: $0))
        })
        
        register(simple(matches: FileTrackToken.understands) {
            .track(try FileTrackToken.create(fromURL: $0))
        })

        return interpreter
    }
}
