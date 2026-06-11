//
//  Created by Vonage on 08/06/2026.
//

public final class FeedbackFactory {

    public init() {

    }
    /// Creates the feedback button for the meeting room bottom bar.
    ///
    /// - Parameter onShowFeedbackForm: Closure fired when the button is tapped.
    ///   The caller is responsible for presenting the feedback sheet.
    @MainActor
    public func makeMeetingRoomButton(onShowFeedbackForm: @escaping () -> Void) -> FeedbackComponentButton {
        .init(onShowFeedbackForm: onShowFeedbackForm)
    }
}
