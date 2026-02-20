//
//  Created by Vonage on 10/2/26.
//

import Combine
import Foundation
import VERADomain

/// Default values shared between ``CaptionsViewModel`` and its consumers.
public enum CaptionsConstants {
    /// The default maximum number of captions shown simultaneously in the overlay.
    public static let maxVisibleCaptions = 3
}

/// View model that transforms raw ``CaptionItem`` data into display-ready
/// ``UICaptionItem`` values for ``CaptionsView``.
///
/// `CaptionsViewModel` subscribes to a ``CaptionsObserver`` and, for every
/// update, sorts the incoming captions by timestamp (newest first), trims
/// them to ``maxVisibleCaptions``, and maps each one to a ``UICaptionItem``
/// with pre-formatted attributed text.
///
/// ## Lifecycle
///
/// The subscription is **not** started automatically. The owning container
/// (``CaptionsViewContainer``) is responsible for calling:
/// - ``initObservers()`` in `onAppear` to begin receiving updates.
/// - ``cancelObservers()`` in `onDisappear` to tear down subscriptions.
///
/// ```swift
/// let vm = CaptionsViewModel(captionsObserver: repo)
/// vm.initObservers()      // start
/// // … later …
/// vm.cancelObservers()     // stop
/// ```
///
/// - SeeAlso: ``CaptionsViewContainer``, ``CaptionsView``, ``CaptionsFactory``
public final class CaptionsViewModel: ObservableObject {

    /// The display-ready caption items currently visible in the overlay.
    ///
    /// Updated on the main queue every time the ``CaptionsObserver`` emits
    /// new data. At most ``maxVisibleCaptions`` items are kept.
    @Published public var captions: [UICaptionItem] = []

    /// Maximum number of captions to display simultaneously.
    private let maxVisibleCaptions: Int
    private var cancellables = Set<AnyCancellable>()

    /// The observer that emits raw ``CaptionItem`` arrays from the repository.
    private let captionsObserver: CaptionsObserver

    /// Creates a view model backed by the given captions observer.
    ///
    /// - Parameters:
    ///   - captionsObserver: The source of raw caption data.
    ///   - maxVisibleCaptions: The maximum number of captions shown at once.
    ///     Defaults to ``CaptionsConstants/maxVisibleCaptions`` (3).
    public init(
        captionsObserver: CaptionsObserver,
        maxVisibleCaptions: Int = CaptionsConstants.maxVisibleCaptions
    ) {
        self.captionsObserver = captionsObserver
        self.maxVisibleCaptions = maxVisibleCaptions
    }

    /// Convenience initialiser for SwiftUI previews and unit tests.
    ///
    /// Uses an ``EmptyCaptionsObserver`` that never emits, so the view
    /// renders with whatever is assigned to ``captions`` directly.
    public convenience init() {
        self.init(
            captionsObserver: EmptyCaptionsObserver(),
            maxVisibleCaptions: CaptionsConstants.maxVisibleCaptions
        )
    }

    /// Subscribes to the captions observer and begins updating ``captions``.
    ///
    /// Each emission is received on the main queue, sorted by timestamp
    /// (newest first), trimmed to ``maxVisibleCaptions``, and mapped to
    /// ``UICaptionItem`` values.
    public func initObservers() {
        captionsObserver.captionsReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] captions in
                self?.handleCaptions(captions)
            }
            .store(in: &cancellables)
    }

    /// Cancels all active Combine subscriptions, stopping caption updates.
    public func cancelObservers() {
        cancellables.removeAll()
    }

    // MARK: - Private

    /// Sorts, trims, and maps raw captions into display-ready items.
    ///
    /// - Parameter captions: The raw caption items received from the observer.
    private func handleCaptions(_ captions: [CaptionItem]) {
        self.captions = Array(
            captions
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(maxVisibleCaptions)
                .map(UICaptionItem.init)
        )
    }
}
