//
//  Created by Vonage on 19/02/2026.
//

import Combine
import Foundation
import VERADomain

/// Default implementation of CaptionsRepository.
///
/// Relays caption arrays to observers via a Combine CurrentValueSubject.
/// Uses Swift Actor for thread-safe concurrent access.
public actor DefaultCaptionsRepository: CaptionsRepository {

    // MARK: - Private Properties

    private nonisolated let captionsSubject = CurrentValueSubject<[CaptionItem], Never>([])

    // MARK: - CaptionsObserver

    public nonisolated var captionsReceived: AnyPublisher<[CaptionItem], Never> {
        captionsSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - CaptionsWriter

    public func updateCaptions(_ captions: [CaptionItem]) async {
        captionsSubject.send(captions)
    }
}

/// Null observer that never emits, used for previews and tests.
public final class EmptyCaptionsObserver: CaptionsObserver, @unchecked Sendable {
    public var captionsReceived: AnyPublisher<[CaptionItem], Never> {
        Empty().eraseToAnyPublisher()
    }
}
