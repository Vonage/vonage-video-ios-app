//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import OSLog
import SwiftUI
import VERADomain

/// ViewModel for the video effects bottom sheet.
///
/// Manages background blur, stock backgrounds, user-uploaded backgrounds,
/// and immediately applies the selected effect to the publisher's stream.
@MainActor
public final class VideoEffectsViewModel: ObservableObject {

    @Published public var selectedEffect: VideoEffect = .none
    @Published public var backgrounds: [VideoBackgroundItem] = []
    @Published public var remainingSlots: Int = 0
    @Published public var isSheetPresented: Bool = false
    @Published public var errorMessage: String?

    private static let logger = Logger(subsystem: "com.vonage.vera", category: "VideoEffects")
    private let getCurrentPublisher: () throws -> VERAPublisher
    private let getBackgroundsUseCase: GetBackgroundsUseCase
    private let addBackgroundUseCase: AddBackgroundUseCase
    private let deleteBackgroundUseCase: DeleteBackgroundUseCase
    private let videoEffectRepository: VideoEffectRepository

    public init(
        getCurrentPublisher: @escaping () throws -> VERAPublisher,
        getBackgroundsUseCase: GetBackgroundsUseCase,
        addBackgroundUseCase: AddBackgroundUseCase,
        deleteBackgroundUseCase: DeleteBackgroundUseCase,
        videoEffectRepository: VideoEffectRepository
    ) {
        self.getCurrentPublisher = getCurrentPublisher
        self.getBackgroundsUseCase = getBackgroundsUseCase
        self.addBackgroundUseCase = addBackgroundUseCase
        self.deleteBackgroundUseCase = deleteBackgroundUseCase
        self.videoEffectRepository = videoEffectRepository

        selectedEffect = videoEffectRepository.load()
    }

    // MARK: - Public Methods

    public func loadBackgrounds() {
        guard let result = try? getBackgroundsUseCase.execute() else { return }
        backgrounds = result.backgrounds
        remainingSlots = result.remainingSlots
    }

    public func selectEffect(_ effect: VideoEffect) {
        selectedEffect = effect
        videoEffectRepository.save(effect)
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
                    let newItem = try addBackgroundUseCase.execute(data)
                    backgrounds.append(newItem)
                    lastAdded = newItem
                } catch is UserBackgroundError {
                    showMaxImagesError()
                    break
                } catch {
                    break
                }
            }
            remainingSlots = (try? getBackgroundsUseCase.execute().remainingSlots) ?? 0
            if let lastAdded {
                selectBackground(lastAdded)
            }
        }
    }

    public func deleteBackground(_ item: VideoBackgroundItem) {
        guard item.isUserUploaded else { return }
        do {
            let didReset = try deleteBackgroundUseCase.execute(item.id)
            backgrounds.removeAll { $0.id == item.id }
            remainingSlots = (try? getBackgroundsUseCase.execute().remainingSlots) ?? 0
            if didReset {
                selectedEffect = .none
                applyToPublisher()
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
