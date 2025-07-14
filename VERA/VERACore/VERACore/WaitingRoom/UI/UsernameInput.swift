//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

enum UsernameState {
    case initial, valid, invalid
}

struct UsernameInput: View {

    @Binding var userName: String
    @State private var usernameState = UsernameState.initial

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "person")
                    .foregroundColor(.vGray3)
                    .frame(width: 20)

                TextField("What is your name?", text: $userName)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.uiSystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
                    .animation(.easeInOut(duration: 0.3), value: usernameState)
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

    private func getUsernameState() -> UsernameState {
        if userName.isEmpty {
            return .initial
        } else {
            return userName.isValidRoomName ? .valid : .invalid
        }
    }
}

#Preview {
    UsernameInput(userName: .constant("Zaphod"))
}
