//
//  Created by Vonage on 26/1/26.
//

import Combine
import Foundation
import SwiftUI
import VERACommonUI
import VERADomain

public final class BackgroundEffectFactory {

    private let getBackgroundsUseCase: GetBackgroundsUseCase
    private let addBackgroundUseCase: AddBackgroundUseCase
    private let deleteBackgroundUseCase: DeleteBackgroundUseCase
    private let remainingSlotsPublisher: AnyPublisher<Int, Never>
    private let videoEffectRepository: VideoEffectRepository

    public init(
        getBackgroundsUseCase: GetBackgroundsUseCase,
        addBackgroundUseCase: AddBackgroundUseCase,
        deleteBackgroundUseCase: DeleteBackgroundUseCase,
        remainingSlotsPublisher: AnyPublisher<Int, Never>,
        videoEffectRepository: VideoEffectRepository
    ) {
        self.getBackgroundsUseCase = getBackgroundsUseCase
        self.addBackgroundUseCase = addBackgroundUseCase
        self.deleteBackgroundUseCase = deleteBackgroundUseCase
        self.remainingSlotsPublisher = remainingSlotsPublisher
        self.videoEffectRepository = videoEffectRepository
    }

    @MainActor
    public func makeEffectsButton(
        getCurrentPublisher: @escaping () throws -> VERAPublisher
    ) -> (view: some View, viewModel: VideoEffectsViewModel) {
        let viewModel = makeViewModel(getCurrentPublisher: getCurrentPublisher)
        let view = BackgroundEffectScreenButton(viewModel: viewModel)
        return (view, viewModel)
    }

    @MainActor
    public func makeEffectsButton(viewModel: VideoEffectsViewModel) -> some View {
        BackgroundEffectScreenButton(viewModel: viewModel)
    }

    @MainActor
    public func makeMeetingEffectsButton(
        viewModel: VideoEffectsViewModel,
        onShowEffects: (() -> Void)? = nil
    ) -> some View {
        MeetingBackgroundEffectScreenButton(viewModel: viewModel, onShowEffects: onShowEffects)
    }

    @MainActor
    public func makeViewModel(
        getCurrentPublisher: @escaping () throws -> VERAPublisher
    ) -> VideoEffectsViewModel {
        VideoEffectsViewModel(
            getCurrentPublisher: getCurrentPublisher,
            getBackgroundsUseCase: getBackgroundsUseCase,
            addBackgroundUseCase: addBackgroundUseCase,
            deleteBackgroundUseCase: deleteBackgroundUseCase,
            remainingSlotsPublisher: remainingSlotsPublisher,
            videoEffectRepository: videoEffectRepository
        )
    }
}
