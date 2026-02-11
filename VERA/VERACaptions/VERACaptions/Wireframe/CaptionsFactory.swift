//
//  Created by Vonage on 6/2/26.
//

import SwiftUI
import VERADomain

public final class CaptionsFactory {

    private let captionsActivationDataSource: CaptionsActivationDataSource
    private let captionsStatusDataSource: CaptionsStatusDataSource

    public init(
        captionsActivationDataSource: CaptionsActivationDataSource,
        captionsStatusDataSource: CaptionsStatusDataSource
    ) {
        self.captionsActivationDataSource = captionsActivationDataSource
        self.captionsStatusDataSource = captionsStatusDataSource
    }

    public func makeCaptionsButton(
        roomName: RoomName
    ) -> (view: some View, viewModel: CaptionsButtonViewModel) {
        let viewModel = CaptionsButtonViewModel(
            roomName: roomName,
            enableCaptionsUseCase: DefaultEnableCaptionsUseCase(
                captionsActivationDataSource: captionsActivationDataSource,
                captionsStatusDataSource: captionsStatusDataSource),
            disableCaptionsUseCase: DefaultDisableCaptionsUseCase(
                captionsActivationDataSource: captionsActivationDataSource),
            captionsStatusDataSource: captionsStatusDataSource)

        return (makeCaptionsButton(viewModel: viewModel), viewModel)
    }

    public func makeCaptionsButton(
        viewModel: CaptionsButtonViewModel
    ) -> some View {
        CaptionsScreenButton(viewModel: viewModel)
    }

    public func makeCaptionsView() -> (view: some View, viewModel: CaptionsViewModel) {
        let viewModel = CaptionsViewModel()
        return (makeCaptionsView(viewModel: viewModel), viewModel)
    }

    public func makeCaptionsView(
        viewModel: CaptionsViewModel
    ) -> some View {
        CaptionsScreenView(viewModel: viewModel)
    }
}
