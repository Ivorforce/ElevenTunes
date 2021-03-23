//
//  OutputDeviceSelector.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.03.21.
//

import SwiftUI
import AVFoundation

@available(OSX 10.15, *)
protocol AudioDeviceProxy: ObservableObject {
	associatedtype Option: AudioDevice
	
	var options: [Option] { get }
	var current: Option? { get set }
}

struct ExtendedAudioDeviceView<Device: AudioDevice>: View {
	@ObservedObject var device: Device
		
	var body: some View {
		HStack {
			Slider(value: $device.volume, in: 0...1)
			
			PlayerAudioView.volumeImage(device.volume)
				.frame(width: 25, alignment: .leading)
		}
	}
}


struct AudioProviderView<Provider: AudioDeviceProxy>: View {
	@ObservedObject var provider: Provider
	
	@State private var pressOption: Provider.Option?
	@State private var hoverOption: Provider.Option?

	func optionView(_ option: Provider.Option) -> some View {
		HStack {
			Text(option.icon)
				.frame(width: 25, alignment: .leading)
			Text(option.name ?? "Unknown Device")
				.frame(width: 300, alignment: .leading)
			
			Text("􀆅").foregroundColor(Color.white.opacity(
				provider.current == option ? 1 :
				hoverOption == option ? 0.2 :
				0
			))
				.frame(width: 25, alignment: .leading)
		}
	}
	
	func backgroundOpacity(_ option: Provider.Option) -> Double? {
		pressOption == option ? 0.4 :
		hoverOption == option ? 0.2 :
			nil
	}

	var body: some View {
		VStack {
			HStack {
				Image(systemName: "speaker.wave.2.circle")
					.foregroundColor(.accentColor)

				if let device = provider.current {
					Text(device.name ?? "Unknown Device").bold()
						.padding(.trailing)
						.frame(maxWidth: .infinity, alignment: .leading)
					
					ExtendedAudioDeviceView(device: device)
						.frame(width: 150)
				}
				else {
					Text("None Selected").bold()
						.foregroundColor(.secondary)
						.padding(.trailing)
						.frame(maxWidth: .infinity, alignment: .leading)

					Slider(value: .constant(1), in: 0...1)
						.disabled(true)
						.frame(width: 150)

					PlayerAudioView.volumeImage(0)
						.frame(width: 25, alignment: .leading)
				}
			}
				.frame(height: 20)
				.padding()

			VStack(alignment: .leading, spacing: 0) {
				ForEach(provider.options, id: \.id) { option in
					optionView(option)
						.padding(.horizontal)
						.padding(.vertical, 10)
						.background(backgroundOpacity(option).map(Color.gray.opacity))
						.onHover { over in
							self.hoverOption = over ? option : nil
						}
						.onTapGesture {
							self.provider.current = option
						}
						.onLongPressGesture(pressing: { isDown in
							self.pressOption = isDown ? option : nil
						}) {}
				}
			}
		}
	}
}

//@available(OSX 10.15, *)
//struct OutputDeviceSelectorView_Previews: PreviewProvider {
//	static var previews: some View {
//		OutputDeviceSelectorView()
//	}
//}
