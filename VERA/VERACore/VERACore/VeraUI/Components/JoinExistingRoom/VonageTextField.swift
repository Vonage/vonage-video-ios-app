//
//  Created by Vonage on 15/7/25.
//

import SwiftUI
import VERACommonUI

enum VonageTextFieldState {
    case initial, valid, invalid
}

struct VonageTextField: View {

    private let placeholder: String
    private var text: Binding<String>
    private var state: VonageTextFieldState
    private let forceLowercase: Bool

    @State private var labelWidth: CGFloat = 0

    init(
        placeholder: String,
        text: Binding<String>,
        state: VonageTextFieldState,
        forceLowercase: Bool = false
    ) {
        self.placeholder = placeholder
        self.text = text
        self.state = state
        self.forceLowercase = forceLowercase
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Group {
                if forceLowercase {
                    TextField(placeholder.capitalizingFirstLetter, text: text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .adaptiveFont(.bodyBase)
                        #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: text.wrappedValue) { newValue in
                                text.wrappedValue = newValue.lowercased()
                            }
                        #endif
                } else {
                    TextField(placeholder.capitalizingFirstLetter, text: text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .adaptiveFont(.bodyBase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 48)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: BorderRadius.medium.value)
                    .fill(Color.clear)

                RoundedRectangle(cornerRadius: BorderRadius.medium.value)
                    .stroke(borderColor, lineWidth: 1)
                    .mask(
                        RoundedRectangle(cornerRadius: BorderRadius.medium.value)
                            .overlay(alignment: .topLeading) {
                                if !text.wrappedValue.isEmpty {
                                    Rectangle()
                                        .frame(width: labelWidth + BorderRadius.medium.value, height: 2)
                                        .offset(x: 12, y: -1)
                                        .blendMode(.destinationOut)
                                }
                            }
                            .compositingGroup()
                    )
            }
        )
        .overlay(alignment: .topLeading) {
            if !text.wrappedValue.isEmpty {
                Text(placeholder.capitalizingFirstLetter)
                    .adaptiveFont(.caption)
                    .foregroundColor(borderColor)
                    .padding(.horizontal, 4)
                    .background(.clear)
                    .offset(x: 12, y: -10)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: LabelWidthPreferenceKey.self,
                                value: geo.size.width
                            )
                        }
                    )
            }
        }
        .onPreferenceChange(LabelWidthPreferenceKey.self) { width in
            self.labelWidth = width
        }
        .animation(.easeInOut(duration: 0.2), value: text.wrappedValue.isEmpty)
    }

    private var borderColor: Color {
        switch state {
        case .initial:
            return VERACommonUIAsset.SemanticColors.tertiary.swiftUIColor
        case .valid:
            return VERACommonUIAsset.SemanticColors.tertiary.swiftUIColor
        case .invalid:
            return VERACommonUIAsset.SemanticColors.error.swiftUIColor
        }
    }
}

private struct LabelWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension String {
    fileprivate var capitalizingFirstLetter: String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}

#Preview {
    VonageTextField(placeholder: "", text: .constant("Hello"), state: .initial)
}
