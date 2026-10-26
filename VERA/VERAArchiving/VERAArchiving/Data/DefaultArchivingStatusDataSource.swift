//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import VERADomain

public final class DefaultArchivingStatusDataSource: ArchivingStatusDataSource {
    private let recordingState = CurrentValueSubject<ArchivingState, Never>(.idle)
    private let transcriptionState = CurrentValueSubject<ArchivingState, Never>(.idle)

    public init() {
    }

    public func archivingState(for kind: ArchiveKind) -> AnyPublisher<ArchivingState, Never> {
        subject(for: kind).eraseToAnyPublisher()
    }

    public func set(archivingState: ArchivingState, for kind: ArchiveKind) {
        subject(for: kind).value = archivingState
    }

    public func reset() {
        ArchiveKind.allCases.forEach { subject(for: $0).value = .idle }
    }

    private func subject(for kind: ArchiveKind) -> CurrentValueSubject<ArchivingState, Never> {
        switch kind {
        case .recording: recordingState
        case .transcription: transcriptionState
        }
    }
}
