//
//  Created by Vonage on 15/7/25.
//

import SwiftUI
import VERACommonUI

typealias TextFieldError = String

enum VonageTextFieldState: Equatable {
    case initial, valid
    case invalid(TextFieldError)
}

struct FloatingLabel: View {
    let text: String
    let isFloating: Bool
    let color: Color
    let backgroundColor: Color

    var body: some View {
        Text(text.capitalizingFirstLetter)
            .adaptiveFont(isFloating ? .caption : .bodyBase)
            .foregroundColor(color)
            .kerning(0.15)
            .padding(.horizontal, isFloating ? 4 : 0)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
                    .opacity(isFloating ? 1 : 0)
            )
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: geo.size.width)
                }
            )
            .offset(x: isFloating ? 12 : 16, y: isFloating ? -24 : 0)
            .animation(.easeInOut(duration: 0.2), value: isFloating)
    }
}

struct VonageTextField: View {

    private let placeholder: String
    private var text: Binding<String>
    private var state: VonageTextFieldState
    private let forceLowercase: Bool

    @State private var labelWidth: CGFloat = 0
    @FocusState private var isFocused: Bool

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
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .leading) {
                FloatingLabel(
                    text: placeholder,
                    isFloating: !text.wrappedValue.isEmpty,
                    color: placeholderColor,
                    backgroundColor: backgroundColor
                )
                .allowsHitTesting(false)

                Group {
                    if forceLowercase {
                        TextField("", text: lowercasedBinding)
                            .textFieldStyle(PlainTextFieldStyle())
                            .adaptiveFont(.bodyBase)
                            .focused($isFocused)
                            .foregroundStyle(textColor)
                            .kerning(0.15)
                            #if os(iOS)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            #endif
                    } else {
                        TextField("", text: text)
                            .textFieldStyle(PlainTextFieldStyle())
                            .adaptiveFont(.bodyBase)
                            .focused($isFocused)
                            .foregroundStyle(textColor)
                            .kerning(0.15)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.medium.value)
                    .stroke(borderColor, lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.medium.value)
                    .fill(backgroundColor)  // ← Background del textfield
            )
            .onPreferenceChange(LabelWidthPreferenceKey.self) { width in
                self.labelWidth = width
            }
            .animation(.easeInOut(duration: 0.2), value: text.wrappedValue.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: isFocused)

            if case .invalid(let error) = state {
                Text(NSLocalizedString(error, bundle: .veraCore, comment: ""))
                    .foregroundColor(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
                    .adaptiveFont(.caption)
            }
        }
    }

    private var lowercasedBinding: Binding<String> {
        Binding(
            get: { text.wrappedValue },
            set: { text.wrappedValue = $0.lowercased() }
        )
    }

    private var backgroundColor: Color {
        VERACommonUIAsset.SemanticColors.surface.swiftUIColor
    }

    private var placeholderColor: Color {
        if case .invalid = state {
            VERACommonUIAsset.SemanticColors.error.swiftUIColor
        } else {
            isFocused
                ? VERACommonUIAsset.SemanticColors.primary.swiftUIColor
                : VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor
        }
    }

    private var textColor: Color {
        if text.wrappedValue.isEmpty {
            VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor
        } else if isFocused {
            VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor
        } else {
            VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor
        }
    }

    private var borderColor: Color {
        switch state {
        case .initial:
            if isFocused {
                VERACommonUIAsset.SemanticColors.primary.swiftUIColor
            } else {
                VERACommonUIAsset.SemanticColors.tertiary.swiftUIColor
            }
        case .valid:
            if isFocused {
                VERACommonUIAsset.SemanticColors.primary.swiftUIColor
            } else {
                VERACommonUIAsset.SemanticColors.tertiary.swiftUIColor
            }
        case .invalid: VERACommonUIAsset.SemanticColors.error.swiftUIColor
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
    VonageTextField(
        placeholder: "Hello",
        text: .constant("Hello"), state: .initial)
}
