//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import VERADomain

public final class DefaultArchivingStatusDataSource: ArchivingStatusDataSource {
    private var _archivingState = CurrentValueSubject<ArchivingState, Never>(.idle)
    public lazy var archivingState: AnyPublisher<ArchivingState, Never> = _archivingState.eraseToAnyPublisher()

    public init() {
    }

    public func set(archivingState: ArchivingState) {
        _archivingState.value = archivingState
    }

    public func reset() {
        _archivingState.value = .idle
    }
}
