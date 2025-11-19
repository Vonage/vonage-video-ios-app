//
//  Created by Vonage on 14/7/25.
//

import SwiftUI
import VERACommonUI

struct UsernameInput: View {

    @Binding var userName: String
    @State private var usernameState = VonageTextFieldState.initial
    let forceLowercase: Bool = false

    var body: some View {
        HStack {
            VonageTextField(
                systemIconName: "person",
                placeholder: String(localized: "What is your name?", bundle: .veraCore),
                text: $userName,
                state: usernameState,
                forceLowercase: forceLowercase
            )
        }
        .onChange(of: userName) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                usernameState = getUsernameState()
            }
        }
    }

    private var borderColor: Color {
        switch getUsernameState() {
        case .initial:
            return VERACommonUIAsset.Colors.uiSecondaryLabel.swiftUIColor
        case .valid:
            return VERACommonUIAsset.Colors.accentBlue.swiftUIColor
        case .invalid:
            return .red
        }
    }

    private func getUsernameState() -> VonageTextFieldState {
        if userName.isEmpty {
            return .initial
        } else {
            return .valid
        }
    }
}

#Preview {
    UsernameInput(userName: .constant("Zaphod"))
}
