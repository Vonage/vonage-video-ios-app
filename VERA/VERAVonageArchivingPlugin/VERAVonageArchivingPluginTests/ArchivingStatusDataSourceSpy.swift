//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import VERAArchiving

final class ArchivingStatusDataSourceSpy: ArchivingStatusDataSource {
    private var isArchiving = CurrentValueSubject<Bool, Never>(false)

    var setCallCount = 0
    var resetCallCount = 0
    var lastArchivingStatus: Bool?

    func archivingStatus() -> AnyPublisher<Bool, Never> {
        isArchiving.eraseToAnyPublisher()
    }

    func set(archivingStatus: Bool) {
        setCallCount += 1
        lastArchivingStatus = archivingStatus
        isArchiving.value = archivingStatus
    }

    func reset() {
        resetCallCount += 1
        isArchiving.value = false
    }
}
