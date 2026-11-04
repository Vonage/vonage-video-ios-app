//
//  Created by Vonage on 13/1/26.
//

import Combine
import Foundation
import Observation
import VERADomain

/// Drives the start/stop control of a session archive.
///
/// The same view model controls both the recording and the post-call transcription,
/// which run as separate concurrent archives. ``kind`` selects which one.
@Observable
public final class ArchiveButtonViewModel {
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    public var state: ArchivingState = .idle

    public var isShowingTranscriptionOptions = false

    public var transcriptionOptions: TranscriptionOptions = .default

    @ObservationIgnored
    public let kind: ArchiveKind

    @ObservationIgnored
    private let sessionKeyProvider: SessionKeyProvider
    @ObservationIgnored
    private let startArchivingUseCase: StartArchivingUseCase
    @ObservationIgnored
    private let stopArchivingUseCase: StopArchivingUseCase
    @ObservationIgnored
    private let archivingStatusDataSource: ArchivingStatusDataSource
    @ObservationIgnored
    private let showAlert: (AlertItem) -> Void
    @ObservationIgnored
    private let loadTranscriptionDefaults: () async -> TranscriptionOptions
    @ObservationIgnored
    private var initiated = false

    /// - Parameter loadTranscriptionDefaults: Loads the options pre-selected each time the
    ///   transcription start options are shown, e.g. the user's AI summary setting.
    public init(
        kind: ArchiveKind = .recording,
        sessionKeyProvider: SessionKeyProvider,
        startArchivingUseCase: StartArchivingUseCase,
        stopArchivingUseCase: StopArchivingUseCase,
        archivingStatusDataSource: ArchivingStatusDataSource,
        loadTranscriptionDefaults: @escaping () async -> TranscriptionOptions = { .default },
        showAlert: @escaping (AlertItem) -> Void
    ) {
        self.kind = kind
        self.sessionKeyProvider = sessionKeyProvider
        self.startArchivingUseCase = startArchivingUseCase
        self.stopArchivingUseCase = stopArchivingUseCase
        self.archivingStatusDataSource = archivingStatusDataSource
        self.loadTranscriptionDefaults = loadTranscriptionDefaults
        self.showAlert = showAlert
    }

    public func setup() {
        guard !initiated else { return }
        initiated = true

        archivingStatusDataSource.archivingState(for: kind)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.state = status
            }
            .store(in: &cancellables)
    }

    public func onTap() {
        switch (state, kind) {
        case (.archiving(let archiveID), _):
            confirm(title: kind.stopConfirmationTitle, message: kind.stopConfirmationMessage) { [weak self] in
                await self?.stopArchiving(withID: archiveID)
            }
        case (.idle, .recording):
            confirm(title: kind.startConfirmationTitle, message: kind.startConfirmationMessage) { [weak self] in
                await self?.startArchiving()
            }
        case (.idle, .transcription):
            Task { @MainActor [weak self] in
                guard let self else { return }
                transcriptionOptions = await loadTranscriptionDefaults()
                isShowingTranscriptionOptions = true
            }
        }
    }

    public func confirmTranscriptionStart() {
        isShowingTranscriptionOptions = false
        Task { @MainActor [weak self] in
            await self?.startArchiving()
        }
    }

    public func cancelTranscriptionStart() {
        isShowingTranscriptionOptions = false
    }

    private func confirm(
        title: String,
        message: String,
        action: @escaping @MainActor () async -> Void
    ) {
        showAlert(
            AlertItem(
                title: title,
                message: message,
                okAction: String(localized: "OK", bundle: .veraArchiving),
                cancelAction: String(localized: "Cancel", bundle: .veraArchiving)
            ) {
                Task { @MainActor in
                    await action()
                }
            }
        )
    }

    @MainActor
    private func startArchiving() async {
        do {
            _ = try await startArchivingUseCase(
                .init(
                    sessionKey: sessionKeyProvider.sessionKey,
                    kind: kind,
                    transcriptionOptions: kind == .transcription ? transcriptionOptions : nil))
        } catch {
        }
    }

    @MainActor
    private func stopArchiving(withID id: String) async {
        do {
            try await stopArchivingUseCase(
                .init(sessionKey: sessionKeyProvider.sessionKey, archiveID: id, kind: kind))
        } catch {
        }
    }
}
