//
//  TrackBackend.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

protocol TrackBackend {
    var icon: Image? { get }
    
    func audio() -> AnyPublisher<AnyAudioEmitter, Error>
}
