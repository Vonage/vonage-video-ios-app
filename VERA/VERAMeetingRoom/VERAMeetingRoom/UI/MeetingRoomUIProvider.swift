//
//  Created by Vonage on 29/6/26.
//

import Combine

/// Provides host-driven UI additions for the meeting room.
///
/// The first supported customization point is the list of extra bottom bar
/// buttons. The protocol can be expanded later with additional meeting room UI
/// surfaces without changing the builder shape.
public protocol MeetingRoomUIProvider {
    var updates: AnyPublisher<Void, Never> { get }

    @MainActor
    func bottomBarButtons() -> [BottomBarButton]
}

/// Default meeting room UI provider used when the host does not customize UI.
public struct DefaultMeetingRoomUIProvider: MeetingRoomUIProvider {
    private let makeBottomBarButtons: @MainActor () -> [BottomBarButton]
    public let updates: AnyPublisher<Void, Never>

    public init() {
        self.init(bottomBarButtons: { [] })
    }

    public init(
        bottomBarButtons: @escaping @MainActor () -> [BottomBarButton],
        updates: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()
    ) {
        self.makeBottomBarButtons = bottomBarButtons
        self.updates = updates
    }

    @MainActor
    public func bottomBarButtons() -> [BottomBarButton] {
        makeBottomBarButtons()
    }
}
