//
//  Created by Vonage on 2/6/26.
//

import SwiftUI
import VERADomain

/// A view modifier that tracks participant visibility and manages video stream subscriptions.
///
/// This modifier automatically calls `onAppear` when the view becomes visible and `onDisappear`
/// when it leaves the screen, enabling bandwidth optimization by only subscribing to visible
/// participant video streams.
struct ParticipantVisibilityModifier: ViewModifier {
    let participant: Participant

    func body(content: Content) -> some View {
        content
            .onAppear {
                participant.onAppear?()
            }
            .onDisappear {
                participant.onDisappear?()
            }
    }
}

extension View {
    /// Tracks visibility of a participant and manages their video stream subscription.
    ///
    /// When the view appears, the participant's `onAppear` callback is invoked to enable
    /// their video stream. When the view disappears, `onDisappear` is called to disable it.
    ///
    /// - Parameter participant: The participant whose visibility should be tracked.
    /// - Returns: A view that automatically manages the participant's video subscription.
    func trackingVisibility(of participant: Participant) -> some View {
        modifier(ParticipantVisibilityModifier(participant: participant))
    }
}
