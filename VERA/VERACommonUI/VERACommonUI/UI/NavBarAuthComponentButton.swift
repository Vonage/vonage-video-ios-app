//
//  Created by Vonage on 12/8/26.
//

import SwiftUI

public struct NavBarAuthComponentButton: View {
    @ObservedObject private var viewModel: NavBarAuthButtonViewModel

    public init(viewModel: NavBarAuthButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavBarAuthButton(
            authState: viewModel.authState,
            onLoginTapped: viewModel.onLoginTapped,
            onLogoutTapped: viewModel.onLogoutTapped
        )
        .onAppear {
            viewModel.startObserving()
        }
    }
}
