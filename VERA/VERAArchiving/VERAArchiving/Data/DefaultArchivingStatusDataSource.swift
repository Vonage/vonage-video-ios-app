//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation

public final class DefaultArchivingStatusDataSource: ArchivingStatusDataSource {
    private var _archivingStatus = CurrentValueSubject<Bool, Never>(false)
    public lazy var archivingStatus: AnyPublisher<Bool, Never> = _archivingStatus.eraseToAnyPublisher()

    public init() {
    }

    public func set(archivingStatus: Bool) {
        _archivingStatus.value = archivingStatus
    }

    public func reset() {
        _archivingStatus.value = false
    }
}
