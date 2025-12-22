//
//  Created by Vonage on 14/7/25.
//

import SwiftUI
import VERACommonUI

struct UsernameInput: View {

    @Binding var userName: Username
    @Binding var usernameState: VonageTextFieldState

    var body: some View {
        HStack {
            VonageTextField(
                placeholder: String(localized: "Enter your name", bundle: .veraCore),
                text: $userName,
                state: usernameState
            )
        }
        .onChange(of: userName) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                usernameState = userName.getUsernameState()
            }
        }
    }
}

extension Username {
    func getUsernameState(_ joinPressed: Bool = false) -> VonageTextFieldState {
        if joinPressed {
            if isEmpty {
                return .invalid(InvalidUsername.empty.rawValue)
            }
            if isValidUsername {
                return .initial
            } else {
                return .invalid(InvalidUsername.invalidFormat.rawValue)
            }
        } else {
            if isValidUsername {
                return .initial
            } else {
                return .invalid(InvalidUsername.invalidFormat.rawValue)
            }
        }
    }
}

enum InvalidUsername: String {
    case empty = "User name cannot be empty"
    case invalidFormat = "Invalid user name format"
}

#Preview {
    UsernameInput(userName: .constant("Zaphod"), usernameState: .constant(.initial))
}
