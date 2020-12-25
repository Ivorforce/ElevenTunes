//
//  Track+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation

extension Track {
    class AttributeKey: RawRepresentable, Hashable {
        class Typed<K>: AttributeKey, TypedKey {
            typealias Value = K
        }

        let rawValue: String
        
        required init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension Track.AttributeKey {
    static let title = Typed<String>(rawValue: "title")
}
