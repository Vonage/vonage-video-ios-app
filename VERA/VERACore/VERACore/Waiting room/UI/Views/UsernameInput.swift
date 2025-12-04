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
                placeholder: String(localized: "Enter your name", bundle: .veraCore),
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
