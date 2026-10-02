import Foundation

extension AppConfig.AudioSettings {
    public var shouldShowMicrophoneControl: Bool {
        allowMicrophoneControl && allowAudioOnJoin
    }
}

extension AppConfig.VideoSettings {
    public var shouldShowCameraControl: Bool {
        allowCameraControl && allowVideoOnJoin
    }
}
