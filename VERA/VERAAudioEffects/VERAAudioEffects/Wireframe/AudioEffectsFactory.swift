//
//  Created by Vonage on 12/3/26.
//

import Foundation
import SwiftUI
import VERADomain

public typealias GetPublisher = () throws -> VERAPublisher

public final class AudioEffectsFactory {

    private let statusDataSource: NoiseSuppressionStatusDataSource?
    private final let publisherRepository: PublisherRepository
    private final let disableNoiseSuppressionUseCase: DisableNoiseSuppressionUseCase
    private final let enableNoiseSuppressionUseCase: EnableNoiseSuppressionUseCase

    public init(
        publisherRepository: PublisherRepository,
        disableNoiseSuppressionUseCase: DisableNoiseSuppressionUseCase,
        enableNoiseSuppressionUseCase: EnableNoiseSuppressionUseCase,
        statusDataSource: NoiseSuppressionStatusDataSource? = nil
    ) {
        self.publisherRepository = publisherRepository
        self.statusDataSource = statusDataSource
        self.enableNoiseSuppressionUseCase = enableNoiseSuppressionUseCase
        self.disableNoiseSuppressionUseCase = disableNoiseSuppressionUseCase
    }

    public func makeWaitingNoiseSuppressionButton(
        getCurrentPublisher: @escaping GetPublisher
    ) -> (view: some View, viewModel: WaitingNoiseSuppressionViewModel) {
        let viewModel = WaitingNoiseSuppressionViewModel(
            getCurrentPublisher: getCurrentPublisher,
            disableNoiseSuppressionUseCase: disableNoiseSuppressionUseCase,
            enableNoiseSuppressionUseCase: enableNoiseSuppressionUseCase,
            statusDataSource: statusDataSource
        )
        let view = makeWaitingNoiseSuppressionButton(viewModel: viewModel)
        return (view, viewModel)
    }

    public func makeWaitingNoiseSuppressionButton(viewModel: WaitingNoiseSuppressionViewModel) -> some View {
        WaitingNoiseSuppressionButtonContainer(viewModel: viewModel)
    }

    public func makeMeetingNoiseSuppressionButton() -> (view: some View, viewModel: MeetingNoiseSuppressionViewModel) {
        let viewModel = MeetingNoiseSuppressionViewModel(
            getCurrentPublisher: publisherRepository.getPublisher,
            disableNoiseSuppressionUseCase: disableNoiseSuppressionUseCase,
            enableNoiseSuppressionUseCase: enableNoiseSuppressionUseCase,
            statusDataSource: statusDataSource
        )
        let view = makeMeetingNoiseSuppressionButton(viewModel: viewModel)
        return (view, viewModel)
    }

    public func makeMeetingNoiseSuppressionButton(viewModel: MeetingNoiseSuppressionViewModel) -> some View {
        MeetingNoiseSuppressionButtonContainer(viewModel: viewModel)
    }
}
