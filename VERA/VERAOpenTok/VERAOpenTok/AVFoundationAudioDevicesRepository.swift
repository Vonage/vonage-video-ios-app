//
//  Created by Vonage on 15/7/25.
//

import AVFoundation
import Combine
import Foundation
import VERACore

public final class AVFoundationAudioDevicesRepository: AudioDevicesRepository {
    private let _observeAvailableDevices = CurrentValueSubject<[AudioDevice], Never>([])
    public lazy var observeAvailableDevices: AnyPublisher<[AudioDevice], Never> =
        _observeAvailableDevices.eraseToAnyPublisher()

    private let audioSession: AVAudioSession

    public init(audioSession: AVAudioSession) {
        self.audioSession = audioSession
    }

    public func routeTo(_ audioDeviceID: String) throws {
        guard
            let targetInput = audioSession.availableInputs?.first(
                where: { $0.uid == audioDeviceID })
        else {
            return
        }

        try audioSession.setPreferredInput(targetInput)
    }

    public func loadAudioDevices() {
        let audioDevices =
            audioSession.availableInputs?.compactMap { input -> AudioDevice? in
                let portDescription = getSystemIconForAudioDevice(input)
                return AudioDevice(id: input.uid, name: input.portName, portDescription: portDescription)
            } ?? []

        _observeAvailableDevices.send(audioDevices)
    }

    /// Returns the appropriate system icon name based on the audio device type
    private func getSystemIconForAudioDevice(_ input: AVAudioSessionPortDescription) -> String {
        switch input.portType {

        // Built-in devices
        case .builtInMic:
            return "iphone"
        case .builtInReceiver:
            return "iphone.badge.radiowaves.left.and.right"
        case .builtInSpeaker:
            return "speaker.wave.3"

        // Bluetooth devices
        case .bluetoothA2DP:
            return "speaker.bluetooth"
        case .bluetoothHFP:
            return "phone.bluetooth"
        case .bluetoothLE:
            return determineBluetoothIcon(from: input.portName)

        // Wired devices
        case .headphones:
            return "headphones"
        case .headsetMic:
            return "headphones.circle"
        case .lineIn:
            return "cable.connector"
        case .lineOut:
            return "speaker.2"

        // USB devices
        case .usbAudio:
            return "usb"

        // AirPlay devices
        case .airPlay:
            return "airplay.audio"

        // HDMI devices
        case .HDMI:
            return "tv"

        // DisplayPort
        case .displayPort:
            return "display"

        // CarAudio
        case .carAudio:
            return "car"

        // Unrecognized devices
        default:
            return "speaker.wave.2"
        }
    }

    /// Determines the specific icon for Bluetooth devices based on the device name
    private func determineBluetoothIcon(from portName: String) -> String {
        let lowercaseName = portName.lowercased()

        // AirPods and Apple products
        if lowercaseName.contains("airpods pro") {
            return "airpods.gen3"
        } else if lowercaseName.contains("airpods max") {
            return "airpodsmax"
        } else if lowercaseName.contains("airpods") {
            return "airpods.gen3"
        }

        // Beats
        if lowercaseName.contains("beats") {
            return "beats.headphones"
        }

        // Other Bluetooth headphones
        if lowercaseName.contains("headphone") || lowercaseName.contains("headset") {
            return "headphones.circle"
        }

        // Bluetooth speakers
        if lowercaseName.contains("speaker") {
            return "speaker.bluetooth"
        }

        // Car devices
        if lowercaseName.contains("car") || lowercaseName.contains("auto") {
            return "car"
        }

        // Generic Bluetooth
        return "speaker.bluetooth"
    }
}
