//
//  DBTrack+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBTrack {
    static let attributeProperties = Set([
        "title"
    ])

    func merge(attributes: TypedDict<TrackAttribute>) {
        if let title = attributes[TrackAttribute.title] { self.title = title }
        
        attributesP = cachedAttributes
    }
    
    var cachedAttributes: TypedDict<TrackAttribute> {
        var dict = TypedDict<TrackAttribute>()
        dict[TrackAttribute.title] = title
        return dict
    }
}
