//
//  Created by Vonage on 13/07/2026.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: OktaAuthManager

    var body: some View {
        VStack(spacing: 24) {
            // SPIKE: Using SF Symbol as safe fallback
            // Replace with actual VERA logo asset once confirmed
            Image(systemName: "video.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80)
                .foregroundColor(.blue)

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

            Button {
                Task {
                    let window = UIApplication.shared
                        .connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .flatMap({ $0.windows })
                        .first(where: { $0.isKeyWindow })
                    await authManager.signIn(from: window)
                }
            } label: {
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
}
