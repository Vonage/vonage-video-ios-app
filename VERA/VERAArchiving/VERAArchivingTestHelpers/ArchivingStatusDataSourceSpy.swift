//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import VERAArchiving

public final class ArchivingStatusDataSourceSpy: ArchivingStatusDataSource {
    public var _archivingStatus = CurrentValueSubject<Bool, Never>(false)
    public lazy var archivingStatus: AnyPublisher<Bool, Never> = {
        archivingStatusCallCount += 1
        return _archivingStatus.eraseToAnyPublisher()
    }()

    public var archivingStatusCallCount = 0
    public var setCallCount = 0
    public var resetCallCount = 0
    public var lastArchivingStatus: Bool?

    public init() {
    }

    public func set(archivingStatus: Bool) {
        setCallCount += 1
        lastArchivingStatus = archivingStatus
        _archivingStatus.value = archivingStatus
    }

    public func reset() {
        resetCallCount += 1
        _archivingStatus.value = false
    }
}
