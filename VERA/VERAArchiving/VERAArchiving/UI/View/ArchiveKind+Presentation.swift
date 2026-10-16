//
//  Created by Vonage on 11/10/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

extension ArchiveKind {
    /// Stable identifier of the bottom bar item controlling this kind of archive.
    public var bottomBarItemID: String {
        switch self {
        case .recording: "archive-button"
        case .transcription: "transcription-button"
        }
    }

    public func bottomBarLabel(for state: ArchivingState) -> String {
        switch self {
        case .recording:
            return state.isArchiving
                ? String(localized: "Stop Recording", bundle: .veraArchiving)
                : String(localized: "Start Recording", bundle: .veraArchiving)
        case .transcription:
            return state.isArchiving
                ? String(localized: "Stop Transcription", bundle: .veraArchiving)
                : String(localized: "Start Transcription", bundle: .veraArchiving)
        }
    }

    public func bottomBarAccessibilityIdentifier(for state: ArchivingState) -> String {
        switch self {
        case .recording:
            state.isArchiving
                ? ArchivingAccessibilityID.stopRecordingButton
                : ArchivingAccessibilityID.startRecordingButton
        case .transcription:
            state.isArchiving
                ? ArchivingAccessibilityID.stopTranscriptionButton
                : ArchivingAccessibilityID.startTranscriptionButton
        }
    }

    public func bottomBarImage(for state: ArchivingState) -> Image {
        switch self {
        case .recording:
            state.isArchiving
                ? VERACommonUIAsset.Images.radioChecked2Line.swiftUIImage
                : VERACommonUIAsset.Images.radioChecked2Solid.swiftUIImage
        case .transcription:
            state.isArchiving
                ? VERACommonUIAsset.Images.voicemailTranscriptLine.swiftUIImage
                : VERACommonUIAsset.Images.voicemailTranscriptSolid.swiftUIImage
        }
    }

    var startConfirmationTitle: String {
        switch self {
        case .recording: String(localized: "Start Recording?", bundle: .veraArchiving)
        case .transcription: String(localized: "Start Transcription?", bundle: .veraArchiving)
        }
    }

    var startConfirmationMessage: String {
        switch self {
        case .recording: String(localized: "start.recording.message", bundle: .veraArchiving)
        case .transcription: String(localized: "start.transcription.message", bundle: .veraArchiving)
        }
    }

    var stopConfirmationTitle: String {
        switch self {
        case .recording: String(localized: "Stop Recording?", bundle: .veraArchiving)
        case .transcription: String(localized: "Stop Transcription?", bundle: .veraArchiving)
        }
    }

    var stopConfirmationMessage: String {
        switch self {
        case .recording: String(localized: "stop.recording.message", bundle: .veraArchiving)
        case .transcription: String(localized: "stop.transcription.message", bundle: .veraArchiving)
        }
    }
}
