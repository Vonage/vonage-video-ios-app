//
//  Created by Vonage on 28/5/26.
//

import Combine
import Foundation

// MARK: - Call State

/// The current state of the meeting room call.
public enum MeetingRoomCallState: Equatable, Sendable {
    /// No active call.
    case idle
    /// Currently connecting to the room.
    case connecting
    /// Connected and in the call.
    case connected
    /// Disconnecting from the call.
    case disconnecting
    /// An error occurred.
    case failed
}

// MARK: - Toast

/// The mode/severity of a toast notification.
public enum MeetingRoomToastMode: Equatable, Sendable {
    case warning, info, failure, success
}

/// A toast notification item displayed in the meeting room.
public struct MeetingRoomToastItem: Equatable, Sendable {
    /// The toast message text.
    public let message: String
    /// The toast severity mode.
    public let mode: MeetingRoomToastMode

    public init(message: String, mode: MeetingRoomToastMode) {
        self.message = message
        self.mode = mode
    }

    public static func == (lhs: MeetingRoomToastItem, rhs: MeetingRoomToastItem) -> Bool {
        lhs.message == rhs.message && lhs.mode == rhs.mode
    }
}

// MARK: - Protocol

/// A protocol for observing the meeting room call state from the host app.
///
/// Conformance is provided by the SDK's internal view model. Use this protocol
/// to monitor call state, archiving, and toast notifications without
/// importing sub-modules.
///
/// Access via `MeetingRoomPrebuilt.callObserver`.
@MainActor
public protocol MeetingRoomCallObserving: AnyObject {
    /// Whether the meeting room UI is still loading.
    var isLoading: Bool { get }

    /// Whether the call is currently being archived/recorded.
    var isArchiving: Bool { get }

    /// The room name for the current meeting.
    var roomName: String { get }

    /// The current toast notification, if any.
    var currentToast: MeetingRoomToastItem? { get }

    /// Publisher for observing loading state updates.
    var isLoadingPublisher: AnyPublisher<Bool, Never> { get }

    /// Publisher for observing archiving state updates.
    var isArchivingPublisher: AnyPublisher<Bool, Never> { get }

    /// Publisher for observing toast updates.
    var currentToastPublisher: AnyPublisher<MeetingRoomToastItem?, Never> { get }
}

// MARK: - ViewModel Conformance

import VERADomain
import VERAMeetingRoom

extension MeetingRoomViewModel: MeetingRoomCallObserving {
    public var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    public var currentToast: MeetingRoomToastItem? {
        guard let toast else { return nil }
        return mapToastItem(toast)
    }

    public var isLoadingPublisher: AnyPublisher<Bool, Never> {
        $state
            .map { state in
                if case .loading = state { return true }
                return false
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public var isArchivingPublisher: AnyPublisher<Bool, Never> {
        $isArchiving.eraseToAnyPublisher()
    }

    public var currentToastPublisher: AnyPublisher<MeetingRoomToastItem?, Never> {
        $toast
            .map { toast in
                toast.map(mapToastItem)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func mapToastItem(_ toast: ToastItem) -> MeetingRoomToastItem {
        let mode: MeetingRoomToastMode
        switch toast.mode {
        case .warning: mode = .warning
        case .info: mode = .info
        case .failure: mode = .failure
        case .success: mode = .success
        }
        return MeetingRoomToastItem(message: toast.message, mode: mode)
    }
}
