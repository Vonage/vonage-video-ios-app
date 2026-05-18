//
//  Created by Vonage on 18/5/26.
//

import SwiftUI

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
