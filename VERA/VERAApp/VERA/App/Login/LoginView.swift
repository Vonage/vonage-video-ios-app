//
//  Created by Vonage on 13/07/2026.
//

import SwiftUI
import OktaOidc

struct LoginView: View {
    @EnvironmentObject var authManager: OktaAuthManager

    var body: some View {
        VStack(spacing: 24) {
            Image("vera_logo") // replace with actual asset name
                .resizable()
                .scaledToFit()
                .frame(width: 120)

            Text("Sign in to VERA")
                .font(.title2)
                .fontWeight(.semibold)

            if let error = authManager.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: triggerSignIn) {
                Label("Sign in with Okta", systemImage: "lock.shield")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    private func triggerSignIn() {
        // OktaOidc requires a UIViewController — get the top-most one
        guard let vc = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else { return }

        authManager.signIn(from: vc)
    }
}
