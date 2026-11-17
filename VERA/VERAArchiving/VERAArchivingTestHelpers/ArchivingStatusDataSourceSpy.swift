//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import VERAArchiving
import VERADomain

public final class ArchivingStatusDataSourceSpy: ArchivingStatusDataSource {
    /// Recording state.
    public let _archivingState = CurrentValueRelay<ArchivingState, Never>(.idle)
    /// Post-call transcription state.
    public let _transcriptionState = CurrentValueRelay<ArchivingState, Never>(.idle)
    private let calls = Calls()

    public var archivingStatusCallCount: Int { calls.withLock { $0.archivingStatusCallCount } }
    public var setCallCount: Int { calls.withLock { $0.setCallCount } }
    public var resetCallCount: Int { calls.withLock { $0.resetCallCount } }
    public var lastArchivingStatus: ArchivingState? { calls.withLock { $0.lastArchivingStatus } }
    public var lastArchiveKind: ArchiveKind? { calls.withLock { $0.lastArchiveKind } }

    public init() {}

    public func archivingState(for kind: ArchiveKind) -> AnyPublisher<ArchivingState, Never> {
        calls.withLock { $0.archivingStatusCallCount += 1 }
        return relay(for: kind).publisher
    }

    public func set(archivingState: ArchivingState, for kind: ArchiveKind) {
        calls.withLock {
            $0.setCallCount += 1
            $0.lastArchivingStatus = archivingState
            $0.lastArchiveKind = kind
        }
        relay(for: kind).send(archivingState)
    }

    public func reset() {
        calls.withLock { $0.resetCallCount += 1 }
        _archivingState.send(.idle)
        _transcriptionState.send(.idle)
    }

    private func relay(for kind: ArchiveKind) -> CurrentValueRelay<ArchivingState, Never> {
        switch kind {
        case .recording: _archivingState
        case .transcription: _transcriptionState
        }
    }

    /// The lock protects test call recordings; no publisher callbacks run under it.
    private final class Calls: @unchecked Sendable {
        struct Values {
            var archivingStatusCallCount = 0
            var setCallCount = 0
            var resetCallCount = 0
            var lastArchivingStatus: ArchivingState?
            var lastArchiveKind: ArchiveKind?
        }
        private let lock = NSLock()
        private var values = Values()
        func withLock<Result>(_ operation: (inout Values) -> Result) -> Result {
            lock.withLock { operation(&values) }
        }
    }
}
