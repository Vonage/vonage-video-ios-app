//
//  Created by Vonage on 26/1/26.
//

import Foundation
import SwiftUI
import VERACommonUI
import VERADomain

public final class BackgroundBlurFactory {

    private let publisherRepository: PublisherRepository

    public init(publisherRepository: PublisherRepository) {
        self.publisherRepository = publisherRepository
    }

    public func makeBlurButton() -> (view: some View, viewModel: BackgroundBlurButtonViewModel) {
        let viewModel = BackgroundBlurButtonViewModel(publisherRepository: publisherRepository)
        let view = BackgroundBlurScreenButton(viewModel: viewModel)
        return (view, viewModel)
    }
}
