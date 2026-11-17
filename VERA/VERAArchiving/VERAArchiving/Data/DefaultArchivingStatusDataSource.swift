//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import VERADomain

public final class DefaultArchivingStatusDataSource: ArchivingStatusDataSource {
    private let recordingState = CurrentValueRelay<ArchivingState, Never>(.idle)
    private let transcriptionState = CurrentValueRelay<ArchivingState, Never>(.idle)

    public init() {
    }

    public func archivingState(for kind: ArchiveKind) -> AnyPublisher<ArchivingState, Never> {
        relay(for: kind).publisher
    }

    public func set(archivingState: ArchivingState, for kind: ArchiveKind) {
        relay(for: kind).send(archivingState)
    }

    public func reset() {
        ArchiveKind.allCases.forEach { relay(for: $0).send(.idle) }
    }

    private func relay(for kind: ArchiveKind) -> CurrentValueRelay<ArchivingState, Never> {
        switch kind {
        case .recording: recordingState
        case .transcription: transcriptionState
        }
    }
}
