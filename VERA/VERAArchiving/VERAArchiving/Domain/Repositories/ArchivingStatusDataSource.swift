//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import VERADomain

/// Tracks the state of the archives running in the current session.
///
/// Recording and post-call transcription are separate, concurrent archives, so the
/// state is keyed by ``ArchiveKind``. A single instance serves every kind, which makes
/// it impossible to wire the recording state where the transcription state is expected.
public protocol ArchivingStatusDataSource: Sendable {
    /// Emits the state of the archive of the given kind.
    func archivingState(for kind: ArchiveKind) -> AnyPublisher<ArchivingState, Never>
    /// Updates the state of the archive of the given kind.
    func set(archivingState: ArchivingState, for kind: ArchiveKind)
    /// Resets every archive kind to idle.
    func reset()
}
