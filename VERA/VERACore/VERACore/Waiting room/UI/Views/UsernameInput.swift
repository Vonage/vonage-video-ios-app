//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

struct UsernameInput: View {

    @Binding var userName: String
    @State private var usernameState = VonageTextFieldState.initial

    var body: some View {
        HStack {
            VonageTextField(
                systemIconName: "person",
                placeholder: "What is your name?",
                text: $userName,
                state: usernameState
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
            return .uiSecondaryLabel
        case .valid:
            return .accentBlue
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
