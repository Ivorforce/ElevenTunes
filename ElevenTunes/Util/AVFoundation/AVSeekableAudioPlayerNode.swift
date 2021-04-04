//
//  AVSeekableAudioPlayerNode.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 04.04.21.
//

import AVFoundation

class AVSeekableAudioPlayerNode {
	let file: AVAudioFile
	let format: AVAudioFormat
	
	private(set) var players: [AVAudioPlayerNode]
	
	private var startTime: TimeInterval = 0
	private var isSwapping = false
	
	var didFinishPlaying: (() -> Void)? = nil
	
	init(file: AVAudioFile) {
		self.file = file
		self.format = file.processingFormat
		players = [.init(), .init()]
	}
	
	var primary: AVAudioPlayerNode { players.first! }
	var secondary: AVAudioPlayerNode { players.last! }
	
	var currentTime: TimeInterval {
		guard
			let nodeTime = primary.lastRenderTime,
			let playerTime = primary.playerTime(forNodeTime: nodeTime)
		else {
			return startTime
		}
		
		return startTime + TimeInterval(playerTime.sampleTime) / TimeInterval(format.sampleRate)
	}
	
	var isPlaying: Bool { primary.isPlaying }
	
	var volume: Float {
		get { primary.volume }
		set {
			primary.volume = newValue
			secondary.volume = newValue
		}
	}
	
	func prepare() {
		seekPlayer(primary, to: startTime)
	}
		
	func play() {
		primary.play()
	}
	
	func stop() {
		startTime = currentTime
		
		isSwapping = true
		primary.stop()
		isSwapping = false
		
		// Prepare for next playback
		seekPlayer(primary, to: startTime)
	}
	
	private func seekPlayer(_ player: AVAudioPlayerNode, to time: TimeInterval) {
		let startSample = max(0, AVAudioFramePosition(round(time * format.sampleRate)))
		player.scheduleSegment(file, startingFrame: startSample, frameCount: AVAudioFrameCount(file.length - startSample), at: nil, completionCallbackType: .dataPlayedBack) { [weak self] type in
			guard type == .dataPlayedBack else { return } // No clue why it calls for other types too
			guard let self = self else { return }
			guard !self.isSwapping else { return }
			
			self.didFinishPlaying?()
		}
	}
	
	func move(to time: TimeInterval) {
		startTime = time

		guard primary.isPlaying else {
			// Prepare at new position
			seekPlayer(primary, to: time)
			return
		}
		
		// Prepare secondary
		seekPlayer(secondary, to: time)
		secondary.prepare(withFrameCount: 5000)
		
		// Hotswap when it's ready - no need to wait longer
		isSwapping = true
		primary.stop()
		isSwapping = false
		secondary.play()
		
		players.reverse()
	}
	
	func move(by time: TimeInterval, buffer: TimeInterval = 0.1) {
		// Where are we at?
		let beginning = Date()
		guard let renderTime = secondary.lastRenderTime else {
			appLogger.error("AVAudioPlayerNode not connected; can't move!")
			return
		}
		
		startTime = currentTime + time + buffer
		
		let volume = self.volume
		
		// Prepare secondary. Prepare to play exactly on cue
		seekPlayer(secondary, to: startTime)
		let startSampleTime = renderTime.sampleTime + AVAudioFramePosition(buffer * format.sampleRate)
		let startTime = AVAudioTime(sampleTime: startSampleTime, atRate: format.sampleRate)
		secondary.play(at: startTime)

		// Wait until we are at swap point.
		Thread.sleep(until: beginning.addingTimeInterval(buffer))
		
		// Hotswap, volume is the fastest way
		primary.volume = 0
		secondary.volume = volume
		
		// Stop secondary, and reset volume
		isSwapping = true
		primary.stop()
		primary.volume = volume
		isSwapping = false

		players.reverse()
	}
}
