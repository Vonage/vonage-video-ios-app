//
//  Created by Vonage on 31/05/2026.
//

import Combine
import Foundation
import OSLog
import Observation
import SwiftUI
import VERADomain

/// ViewModel for the video effects bottom sheet.
///
/// Manages background blur, stock backgrounds, user-uploaded backgrounds,
/// and immediately applies the selected effect to the publisher's stream.
@MainActor
@Observable
public final class VideoEffectsViewModel {

    public var selectedEffect: VideoEffect = .none
    public var backgrounds: [VideoBackgroundItem] = []
    public var remainingSlots: Int = 0
    public var isSheetPresented: Bool = false
    public var errorMessage: String?

    private static let logger = Logger(subsystem: "com.vonage.vera", category: "VideoEffects")
    @ObservationIgnored
    private let getCurrentPublisher: () throws -> VERAPublisher
    @ObservationIgnored
    private let getBackgroundsUseCase: GetBackgroundsUseCase
    @ObservationIgnored
    private let addBackgroundUseCase: AddBackgroundUseCase
    @ObservationIgnored
    private let deleteBackgroundUseCase: DeleteBackgroundUseCase
    @ObservationIgnored
    private let videoEffectRepository: VideoEffectRepository
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    public init(
        getCurrentPublisher: @escaping () throws -> VERAPublisher,
        getBackgroundsUseCase: GetBackgroundsUseCase,
        addBackgroundUseCase: AddBackgroundUseCase,
        deleteBackgroundUseCase: DeleteBackgroundUseCase,
        remainingSlotsPublisher: AnyPublisher<Int, Never>,
        videoEffectRepository: VideoEffectRepository
    ) {
        self.getCurrentPublisher = getCurrentPublisher
        self.getBackgroundsUseCase = getBackgroundsUseCase
        self.addBackgroundUseCase = addBackgroundUseCase
        self.deleteBackgroundUseCase = deleteBackgroundUseCase
        self.videoEffectRepository = videoEffectRepository

        selectedEffect = videoEffectRepository.load()
        remainingSlotsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remainingSlots in
                self?.remainingSlots = remainingSlots
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    public func loadBackgrounds() {
        guard let result = try? getBackgroundsUseCase() else { return }
        backgrounds = result.backgrounds
    }

    public func selectEffect(_ effect: VideoEffect) {
        selectedEffect = effect
        do {
            try videoEffectRepository.save(effect)
        } catch {
            Self.logger.error("Failed to save video effect: \(error.localizedDescription)")
        }
        applyToPublisher()
    }

    public func selectBackground(_ item: VideoBackgroundItem) {
        let effect = VideoEffect.backgroundImage(id: item.id, imagePath: item.imagePath)
        selectEffect(effect)
    }

    public func addBackgrounds(_ items: [PhotoItemDataLoader]) {
        Task {
            var lastAdded: VideoBackgroundItem?
            for item in items {
                guard let data = try? await item.loadImageData() else { continue }
                do {
                    let newItem = try addBackgroundUseCase(data)
                    backgrounds.append(newItem)
                    lastAdded = newItem
                } catch is UserBackgroundError {
                    showMaxImagesError()
                    break
                } catch {
                    break
                }
            }
            if let lastAdded {
                selectBackground(lastAdded)
            }
        }
    }

    public func deleteBackground(_ item: VideoBackgroundItem) {
        guard item.isUserUploaded else { return }
        do {
            let shouldResetEffect: Bool
            if case .backgroundImage(let activeId, _) = selectedEffect {
                shouldResetEffect = activeId == item.id
            } else {
                shouldResetEffect = false
            }

            try deleteBackgroundUseCase(item.id)
            backgrounds.removeAll { $0.id == item.id }
            if shouldResetEffect {
                selectEffect(.none)
            }
        } catch {
            Self.logger.error("Failed to delete background \(item.id): \(error.localizedDescription)")
        }
    }

    public func showMaxImagesError() {
        errorMessage = String(
            localized: "You've reached the limit of 10 images. Delete an image to add a new one.",
            bundle: .module
        )
    }

    // MARK: - Private

    public func reapplyCurrentEffect() {
        applyToPublisher()
    }

    private func applyToPublisher() {
        do {
            let publisher = try getCurrentPublisher()
            try publisher.applyVideoEffect(selectedEffect)
        } catch {
            Self.logger.error("Failed to apply video effect: \(error.localizedDescription)")
        }
    }
}
