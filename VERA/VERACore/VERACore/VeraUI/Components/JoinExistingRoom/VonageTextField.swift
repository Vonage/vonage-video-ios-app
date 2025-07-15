//
//  Created by Vonage on 15/7/25.
//

import SwiftUI

enum VonageTextFieldState {
    case initial, valid, invalid
}

struct VonageTextField: View {

    private let iconName: String
    private let systemIconName: String
    private let placeholder: String
    private var text: Binding<String>
    private var state: VonageTextFieldState

    init(
        iconName: String = "",
        systemIconName: String = "",
        placeholder: String,
        text: Binding<String>,
        state: VonageTextFieldState
    ) {
        self.iconName = iconName
        self.systemIconName = systemIconName
        self.placeholder = placeholder
        self.text = text
        self.state = state
    }

    var body: some View {
        HStack(spacing: 12) {
            if !iconName.isEmpty {
                Image(iconName, bundle: .veraCore)
                    .foregroundColor(.vGray3)
                    .frame(width: 20)
            }
            if !systemIconName.isEmpty {
                Image(systemName: systemIconName)
                    .foregroundColor(.vGray3)
                    .frame(width: 20)
            }

            TextField(placeholder, text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .textInputAutocapitalization(.never)
                .textCase(.lowercase)
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
                .animation(.easeInOut(duration: 0.3), value: state)
        )
    }

    private var borderColor: Color {
        switch state {
        case .initial:
            return .uiSecondaryLabel
        case .valid:
            return .accentBlue
        case .invalid:
            return .red
        }
    }
}

#Preview {
    VonageTextField(iconName: "keyboard", placeholder: "", text: .constant("Hello"), state: .initial)
}
