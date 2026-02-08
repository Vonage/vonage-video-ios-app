//
//  Created by Vonage on 6/2/26.
//

import SwiftUI
import VERADomain

public final class CaptionsFactory {

    private let captionsDataSource: CaptionsDataSource
    private let captionsStatusDataSource: CaptionsStatusDataSource

    public init(
        captionsDataSource: CaptionsDataSource,
        captionsStatusDataSource: CaptionsStatusDataSource
    ) {
        self.captionsDataSource = captionsDataSource
        self.captionsStatusDataSource = captionsStatusDataSource
    }

    public func makeCaptionsButton(
        roomName: RoomName
    ) -> (view: some View, viewModel: CaptionsButtonViewModel) {
        let viewModel = CaptionsButtonViewModel(
            roomName: roomName,
            enableCaptionsUseCase: DefaultEnableCaptionsUseCase(
                captionsDataSource: captionsDataSource,
                captionsStatusDataSource: captionsStatusDataSource),
            disableCaptionsUseCase: DefaultDisableCaptionsUseCase(
                captionsDataSource: captionsDataSource),
            captionsStatusDataSource: captionsStatusDataSource)

        return (makeCaptionsButton(viewModel: viewModel), viewModel)
    }

    public func makeCaptionsButton(
        viewModel: CaptionsButtonViewModel
    ) -> some View {
        CaptionsScreenButton(viewModel: viewModel)
    }
}
