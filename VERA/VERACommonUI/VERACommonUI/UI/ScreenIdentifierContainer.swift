//
//  Created by Vonage on 18/5/26.
//

import SwiftUI

/// Adds an invisible accessibility anchor to a view without changing its visual appearance or hit testing.
///
/// This is useful for exposing stable identifiers to UI automation tools when assigning the identifier
/// directly to a complex SwiftUI container would alter how its child accessibility elements are exposed.
public struct AccessibilityAnchorModifier: ViewModifier {

    private let identifier: String
    private let label: String?
    private let alignment: Alignment
    private let size: CGSize

    public init(
        identifier: String,
        label: String? = nil,
        alignment: Alignment = .topLeading,
        size: CGSize = CGSize(width: 1, height: 1)
    ) {
        self.identifier = identifier
        self.label = label
        self.alignment = alignment
        self.size = size
    }

    public func body(content: Content) -> some View {
        content.overlay(alignment: alignment) {
            Color.clear
                .frame(width: size.width, height: size.height)
                .accessibilityElement()
                .if(label != nil) { view in
                    view.accessibilityLabel(label ?? "")
                }
                .accessibilityIdentifier(identifier)
                .allowsHitTesting(false)
        }
    }
}

extension View {
    /// Adds an invisible accessibility anchor identified by `identifier`.
    public func accessibilityAnchor(
        _ identifier: String,
        label: String? = nil,
        alignment: Alignment = .topLeading,
        size: CGSize = CGSize(width: 1, height: 1)
    ) -> some View {
        modifier(
            AccessibilityAnchorModifier(
                identifier: identifier,
                label: label,
                alignment: alignment,
                size: size
            )
        )
    }
}

/// A container that adds an invisible accessibility anchor for Maestro E2E tests.
/// Wraps content in a `ZStack` with a hidden element identified by the given screen ID.
public struct ScreenIdentifierContainer<Content: View>: View {

    private let screenID: String
    private let content: Content

    public init(_ screenID: String, @ViewBuilder content: () -> Content) {
        self.screenID = screenID
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityIdentifier(screenID)

            content
        }
    }
}
