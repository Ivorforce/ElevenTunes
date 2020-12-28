//
//  FileVideo.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation
import CoreData
import UniformTypeIdentifiers
import Combine
import AVFoundation
import SwiftUI

public class FileVideo: RemoteTrack {
    public var url: URL
    
    init(_ url: URL) {
        self.url = url
        super.init()
        _attributes[TrackAttribute.title] = url.lastPathComponent
        _cacheMask = [.minimal]
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try super.encode(to: encoder)
    }

    static func understands(url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return false
        }
        return type.conforms(to: .audiovisualContent) && !type.conforms(to: .audio)
    }

    static func create(fromURL url: URL) throws -> FileVideo {
        _ = try AVAudioFile(forReading: url) // Just so we know it's readable
        return FileVideo(url)
    }
     
    public override var id: String { url.absoluteString }
    
    public override var icon: Image { Image(systemName: "video") }
        
    public override func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        // TODO Return video emitter when possible
        let url = self.url
        return Future {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return AVAudioPlayerEmitter(player)
        }
            .eraseToAnyPublisher()
    }
    
    public override func load(atLeast mask: TrackContentMask, library: Library) {
        _attributes[TrackAttribute.title] = url.lastPathComponent
        _cacheMask.formUnion(.minimal)
    }
}

extension FileVideo {
    enum CodingKeys: String, CodingKey {
      case url
    }
}
