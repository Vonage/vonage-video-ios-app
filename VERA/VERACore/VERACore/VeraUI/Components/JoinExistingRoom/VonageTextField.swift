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

/// Layout constants for the floating-label text field.
private enum VonageTextFieldConstants {
    /// Horizontal padding for the floating label when floating.
    static let floatingLabelHorizontalPadding: CGFloat = 4
    /// Corner radius for the floating label background pill.
    static let floatingLabelCornerRadius: CGFloat = 4
    /// X offset of the floating label.
    static let floatingLabelOffsetX: CGFloat = 12
    /// X offset of the resting label.
    static let restingLabelOffsetX: CGFloat = 16
    /// Y offset of the floating label.
    static let floatingLabelOffsetY: CGFloat = -24
    /// Horizontal padding inside the text field.
    static let textFieldHorizontalPadding: CGFloat = 16
    /// Vertical padding inside the text field.
    static let textFieldVerticalPadding: CGFloat = 12
    /// Fixed height of the text field container.
    static let textFieldHeight: CGFloat = 48
    /// Width of the border stroke.
    static let borderWidth: CGFloat = 1
    /// Letter spacing (kerning) for input text and labels.
    static let kerning: CGFloat = 0.15
    /// Duration of the float/focus animations.
    static let animationDuration: Double = 0.2
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
            .kerning(VonageTextFieldConstants.kerning)
            .padding(.horizontal, isFloating ? VonageTextFieldConstants.floatingLabelHorizontalPadding : 0)
            .background(
                RoundedRectangle(cornerRadius: VonageTextFieldConstants.floatingLabelCornerRadius)
                    .fill(backgroundColor)
                    .opacity(isFloating ? 1 : 0)
            )
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: geo.size.width)
                }
            )
            .offset(
                x: isFloating
                    ? VonageTextFieldConstants.floatingLabelOffsetX
                    : VonageTextFieldConstants.restingLabelOffsetX,
                y: isFloating ? VonageTextFieldConstants.floatingLabelOffsetY : 0
            )
            .animation(.easeInOut(duration: VonageTextFieldConstants.animationDuration), value: isFloating)
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
                            .kerning(VonageTextFieldConstants.kerning)
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
                            .kerning(VonageTextFieldConstants.kerning)
                    }
                }
                .padding(.horizontal, VonageTextFieldConstants.textFieldHorizontalPadding)
                .padding(.vertical, VonageTextFieldConstants.textFieldVerticalPadding)
            }
            .frame(height: VonageTextFieldConstants.textFieldHeight)
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.medium.value)
                    .stroke(borderColor, lineWidth: VonageTextFieldConstants.borderWidth)
            )
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.medium.value)
                    .fill(backgroundColor)  // ← Background del textfield
            )
            .onPreferenceChange(LabelWidthPreferenceKey.self) { width in
                self.labelWidth = width
            }
            .animation(.easeInOut(duration: VonageTextFieldConstants.animationDuration), value: text.wrappedValue.isEmpty)
            .animation(.easeInOut(duration: VonageTextFieldConstants.animationDuration), value: isFocused)

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
