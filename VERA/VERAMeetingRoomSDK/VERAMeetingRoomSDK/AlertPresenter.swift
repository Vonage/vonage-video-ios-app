//
//  Created by Vonage on 23/4/26.
//

import VERADomain

/// A bridge that allows the builder's closures to present alerts
/// inside ``MeetingRoomComposedView`` via a shared reference.
///
/// Follows the same pattern as `BottomBarButtonsAssembler` callbacks:
/// the composed view sets `present` in `.onAppear`, and closures created
/// during `build()` call `present?(_:)` when an alert is needed.
@MainActor
final class AlertPresenter {
    var present: ((AlertItem) -> Void)?
}
