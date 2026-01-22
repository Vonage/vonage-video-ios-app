//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import VERAArchiving
import VERADomain

public final class ArchivingStatusDataSourceSpy: ArchivingStatusDataSource {
    public var _archivingState = CurrentValueSubject<ArchivingState, Never>(.idle)
    public lazy var archivingState: AnyPublisher<ArchivingState, Never> = {
        archivingStatusCallCount += 1
        return _archivingState.eraseToAnyPublisher()
    }()

    public var archivingStatusCallCount = 0
    public var setCallCount = 0
    public var resetCallCount = 0
    public var lastArchivingStatus: ArchivingState?

    public init() {
    }

    public func set(archivingState: ArchivingState) {
        setCallCount += 1
        lastArchivingStatus = archivingState
        _archivingState.value = archivingState
    }

    public func reset() {
        resetCallCount += 1
        _archivingState.value = .idle
    }
}
