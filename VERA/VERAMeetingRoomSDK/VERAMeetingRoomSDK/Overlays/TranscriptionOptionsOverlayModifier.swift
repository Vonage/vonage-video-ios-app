//
//  Created by Vonage on 26/10/26.
//

import SwiftUI
import VERAArchiving

/// Presents the post-call transcription start options when the transcription button asks for them.
///
/// The transcription button lives in the bottom bar or its overflow menu, so the sheet is
/// attached to the meeting room instead of the button.
struct TranscriptionOptionsOverlayModifier: ViewModifier {
    let viewModel: ArchiveButtonViewModel?

    func body(content: Content) -> some View {
        if let viewModel {
            content.modifier(TranscriptionOptionsSheet(viewModel: viewModel))
        } else {
            content
        }
    }
}

private struct TranscriptionOptionsSheet: ViewModifier {
    @Environment(\.meetingRoomTheme) private var theme

    @Bindable var viewModel: ArchiveButtonViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.isShowingTranscriptionOptions) {
                TranscriptionStartOptionsScreen(viewModel: viewModel)
                    .presentationDetents([.medium])
                    .presentationBackground(theme.background)
            }
    }
}
