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

    @State private var contentHeight: CGFloat = 280

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.isShowingTranscriptionOptions) {
                TranscriptionStartOptionsScreen(viewModel: viewModel)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        contentHeight = height
                    }
                    .presentationDetents([.height(contentHeight)])
                    .presentationBackground(theme.background)
            }
    }
}
