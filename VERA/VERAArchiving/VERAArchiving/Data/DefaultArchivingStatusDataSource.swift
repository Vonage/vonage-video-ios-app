//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation

public final class DefaultArchivingStatusDataSource: ArchivingStatusDataSource {

    private var isArchiving = CurrentValueSubject<Bool, Never>(false)

    public init() {
    }

    public func archivingStatus() -> AnyPublisher<Bool, Never> {
        isArchiving.eraseToAnyPublisher()
    }

    public func set(archivingStatus: Bool) {
        isArchiving.value = archivingStatus
    }

    public func reset() {
        isArchiving.value = false
    }
}
