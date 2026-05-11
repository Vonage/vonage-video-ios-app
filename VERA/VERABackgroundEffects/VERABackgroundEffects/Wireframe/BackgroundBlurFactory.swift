//
//  Created by Vonage on 26/1/26.
//

import Foundation
import SwiftUI
import VERACommonUI
import VERADomain

public final class BackgroundBlurFactory {

    public init() {
    }

    public func makeBlurButton(
        getCurrentPublisher: @escaping () throws -> VERAPublisher,
        getProvider: @escaping () -> BackgroundEffectProvider = { .vonage },
        getAppleVisionQuality: @escaping () -> AppleVisionSegmentationQuality = { .fast }
    ) -> (view: some View, viewModel: BackgroundBlurButtonViewModel) {
        let viewModel = BackgroundBlurButtonViewModel(
            getCurrentPublisher: getCurrentPublisher,
            getProvider: getProvider,
            getAppleVisionQuality: getAppleVisionQuality
        )
        let view = BackgroundBlurScreenButton(viewModel: viewModel)
        return (view, viewModel)
    }

    public func makeBlurButton(viewModel: BackgroundBlurButtonViewModel) -> some View {
        let view = BackgroundBlurScreenButton(viewModel: viewModel)
        return (view)
    }

    public func makeMeetingBlurButton(viewModel: BackgroundBlurButtonViewModel) -> some View {
        let view = MeetingBackgroundBlurScreenButton(viewModel: viewModel)
        return (view)
    }

    /// Returns a small HUD overlay showing the live performance counters for
    /// the active background-effect provider. Intended for DEBUG instrumentation.
    public func makeHUDView() -> some View {
        PerformanceHUDView()
    }
}
