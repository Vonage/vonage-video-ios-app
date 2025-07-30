//
//  Created by Vonage on 30/7/25.
//

import SwiftUI

struct GoToLandingPageButton: View {
    let onReturnToLanding: () -> Void

    var body: some View {
        Button {
            onReturnToLanding()
        } label: {
            Text("Return to landing page", bundle: .veraCore)
        }
        .buttonStyle(GoToLandingPageButtonStyle())
    }
}

struct GoToLandingPageButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.accentBlue.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(radius: 5)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    GoToLandingPageButton() {}
    GoToLandingPageButton() {}
    GoToLandingPageButton() {}
}
