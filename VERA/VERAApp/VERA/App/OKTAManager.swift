//
//  Created by Vonage on 13/07/2026.
//
// VERA — Okta Auth Spike (okta-mobile-swift)

import Foundation
import AuthFoundation
import BrowserSignin
import UIKit

@MainActor
final class OktaAuthManager: ObservableObject {

    // MARK: - Published State

    @Published var isAuthenticated: Bool = false
    @Published var accessToken: String?
    @Published var userEmail: String?
    @Published var error: String?

    // MARK: - Init

    init() {
        //restoreSession()
    }

    // MARK: - Session Restoration (cold launch)

    private func restoreSession() {
        // Credential.default is non-nil if a token was previously stored
        if let credential = Credential.default {
            accessToken = credential.token.accessToken
            userEmail = credential.userInfo?.email
            isAuthenticated = true
        }
    }

    // MARK: - Sign In

    func signIn(from window: UIWindow?) async {
        error = nil
        do {
            // BrowserSignin.shared reads Okta.plist automatically
            // Opens ASWebAuthenticationSession — no UIViewController needed
            guard let token = try await BrowserSignin.shared?.signIn(from: window) else { return }
            let credential = try Credential.store(token)
            accessToken = credential.token.accessToken
            userEmail = credential.userInfo?.email
            print(accessToken, userEmail ?? "")
            isAuthenticated = true
        } catch {
            print(error.localizedDescription)
            self.error = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut(from window: UIWindow?) async {
        guard let credential = Credential.default else { return }
        do {
            // Revokes tokens + clears Keychain + ends Okta browser session
            try await BrowserSignin.shared?.signOut(from: window, credential: credential)
            try credential.remove()
            accessToken = nil
            userEmail = nil
            isAuthenticated = false
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Token Refresh

    func renewIfNeeded() async {
        guard let credential = Credential.default else { return }
        do {
            try await credential.refreshIfNeeded()
            accessToken = credential.token.accessToken
        } catch {
            self.error = error.localizedDescription
            isAuthenticated = false
        }
    }
}
