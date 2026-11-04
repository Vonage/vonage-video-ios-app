//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import VERAArchiving
import VERADomain

public final class ArchivingStatusDataSourceSpy: ArchivingStatusDataSource {
    /// Recording state.
    public let _archivingState = CurrentValueSubject<ArchivingState, Never>(.idle)
    /// Post-call transcription state.
    public let _transcriptionState = CurrentValueSubject<ArchivingState, Never>(.idle)

    public var archivingStatusCallCount = 0
    public var setCallCount = 0
    public var resetCallCount = 0
    public var lastArchivingStatus: ArchivingState?
    public var lastArchiveKind: ArchiveKind?

    public init() {
    }

    public func archivingState(for kind: ArchiveKind) -> AnyPublisher<ArchivingState, Never> {
        archivingStatusCallCount += 1
        return subject(for: kind).eraseToAnyPublisher()
    }

    public func set(archivingState: ArchivingState, for kind: ArchiveKind) {
        setCallCount += 1
        lastArchivingStatus = archivingState
        lastArchiveKind = kind
        subject(for: kind).value = archivingState
    }

    public func reset() {
        resetCallCount += 1
        _archivingState.value = .idle
        _transcriptionState.value = .idle
    }

    public func subject(for kind: ArchiveKind) -> CurrentValueSubject<ArchivingState, Never> {
        switch kind {
        case .recording: _archivingState
        case .transcription: _transcriptionState
        }
    }
}
