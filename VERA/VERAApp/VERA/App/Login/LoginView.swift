//
//  Created by Vonage on 13/07/2026.
//

import SwiftUI
import VERACommonUI

struct LoginView: View {
    @EnvironmentObject var authManager: OktaAuthManager

    var body: some View {
        VStack(spacing: 24) {
            // SPIKE: Using SF Symbol as safe fallback
            Image(systemName: "video.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80)

            Text("Log in to VERA")
                .font(.title2)
                .fontWeight(.semibold)

            if let error = authManager.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            FilledButton(text: Text("Sign in with Okta"), image: Image(systemName: "lock.shield")) {
                Task {
                    let window = UIApplication.shared
                        .connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .flatMap({ $0.windows })
                        .first(where: { $0.isKeyWindow })
                    await authManager.signIn(from: window)
                }
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
}
