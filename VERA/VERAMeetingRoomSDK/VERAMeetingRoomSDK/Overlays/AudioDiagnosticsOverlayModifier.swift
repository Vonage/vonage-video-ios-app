//
//  Created by Vonage on 06/07/26.
//

import SwiftUI
import VERAAudioDiagnostics

struct AudioDiagnosticsOverlayModifier: ViewModifier {
    @Binding var showAudioDiagnostics: Bool
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showAudioDiagnostics) {
                container.audioDiagnosticsFactory.makeConfiguredView()
            }
    }
}
