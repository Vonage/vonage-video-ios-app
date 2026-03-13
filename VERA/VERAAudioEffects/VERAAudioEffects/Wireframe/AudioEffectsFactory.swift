//
//  Created by Vonage on 12/3/26.
//

import Foundation
import SwiftUI
import VERADomain

public typealias GetPublisher = () throws -> VERAPublisher

public final class AudioEffectsFactory {

    private final let publisherRepostiory: PublisherRepository
    private final let disableNoiseSuppresionUseCase: DisableNoiseSuppresionUseCase
    private final let enableNoiseSuppresionUseCase: EnableNoiseSuppresionUseCase

    public init(
        publisherRepostiory: PublisherRepository,
        disableNoiseSuppresionUseCase: DisableNoiseSuppresionUseCase,
        enableNoiseSuppresionUseCase: EnableNoiseSuppresionUseCase
    ) {
        self.publisherRepostiory = publisherRepostiory
        self.enableNoiseSuppresionUseCase = enableNoiseSuppresionUseCase
        self.disableNoiseSuppresionUseCase = disableNoiseSuppresionUseCase
    }

    public func makeWaitingNoiseSuppressionButton(
        getCurrentPublisher: @escaping GetPublisher
    ) -> (view: some View, viewModel: WaittingNoiseSuppressionViewModel) {
        let viewModel = WaittingNoiseSuppressionViewModel(
            getCurrentPublisher: getCurrentPublisher,
            disableNoiseSuppresionUseCase: disableNoiseSuppresionUseCase,
            enableNoiseSuppresionUseCase: enableNoiseSuppresionUseCase
        )
        let view = makeWaitingNoiseSuppressionButton(viewModel: viewModel)
        return (view, viewModel)
    }

    public func makeWaitingNoiseSuppressionButton(viewModel: WaittingNoiseSuppressionViewModel) -> some View {
        WaitingNoiseSuppressionButtonContainer(viewModel: viewModel)
    }

    public func makeMeetingNoiseSuppressionButton() -> (view: some View, viewModel: MeetingNoiseSuppressionViewModel) {
        let viewModel = MeetingNoiseSuppressionViewModel(
            getCurrentPublisher: publisherRepostiory.getPublisher,
            disableNoiseSuppresionUseCase: disableNoiseSuppresionUseCase,
            enableNoiseSuppresionUseCase: enableNoiseSuppresionUseCase
        )
        let view = makeMeetingNoiseSuppressionButton(viewModel: viewModel)
        return (view, viewModel)
    }

    public func makeMeetingNoiseSuppressionButton(viewModel: MeetingNoiseSuppressionViewModel) -> some View {
        MeetingNoiseSuppressionButtonContainer(viewModel: viewModel)
    }
}
