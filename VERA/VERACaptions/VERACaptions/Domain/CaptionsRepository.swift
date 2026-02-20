//
//  Created by Vonage on 19/02/2026.
//

import Combine
import VERADomain

/// Observes caption updates from the repository.
public protocol CaptionsObserver: Sendable {
    /// Publisher that emits the current list of captions whenever it changes.
    var captionsReceived: AnyPublisher<[CaptionItem], Never> { get }
}

/// Writes caption updates to the repository.
public protocol CaptionsWriter: Sendable {
    /// Updates the current list of captions.
    /// - Parameter captions: The new list of captions.
    func updateCaptions(_ captions: [CaptionItem]) async
}

/// Repository for managing captions during a call.
///
/// Combines write and observe capabilities for caption management.
public typealias CaptionsRepository = CaptionsWriter & CaptionsObserver
