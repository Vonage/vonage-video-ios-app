//
//  Created by Vonage on 13/07/2026.
//

import Foundation
import OktaOidc
import UIKit

@MainActor
final class OktaAuthManager: ObservableObject {

    // MARK: - Published State

    @Published var isAuthenticated: Bool = false
    @Published var accessToken: String?
    @Published var userEmail: String?
    @Published var error: String?

    // MARK: - Private

    private let oktaOidc: OktaOidc
    private var stateManager: OktaOidcStateManager?

    // MARK: - Init

    init() {
        // Reads from Okta.plist automatically
        guard let oidc = try? OktaOidc() else {
            fatalError("[OktaAuthManager] Failed to initialise OktaOidc — check Okta.plist")
        }
        self.oktaOidc = oidc
        restoreSession()
    }

    // MARK: - Session Restoration (cold launch)

    private func restoreSession() {
        guard let manager = OktaOidcStateManager
            .readFromSecureStorage(for: oktaOidc.configuration) else {
            isAuthenticated = false
            return
        }
        stateManager = manager
        accessToken = manager.accessToken
        isAuthenticated = manager.accessToken != nil
    }

    // MARK: - Sign In

    func signIn(from viewController: UIViewController) {
        error = nil
        oktaOidc.signInWithBrowser(from: viewController) { [weak self] manager, err in
            guard let self else { return }
            if let err {
                self.error = err.localizedDescription
                return
            }
            guard let manager else { return }

            // Persist to Keychain
            manager.writeToSecureStorage()

            self.stateManager = manager
            self.accessToken = manager.accessToken
            self.isAuthenticated = true

            // Optionally fetch user info
            manager.getUser { response, _ in
                if let email = response?["email"] as? String {
                    Task { @MainActor in self.userEmail = email }
                }
            }
        }
    }

    // MARK: - Sign Out

    func signOut(from viewController: UIViewController) {
        guard let manager = stateManager else { return }

        // Revoke tokens + clear session + remove from Keychain
        let options: OktaSignOutOptions = .allOptions
        oktaOidc.signOut(
            authStateManager: manager,
            from: viewController,
            progressHandler: { _ in },
            completionHandler: { [weak self] success, _ in
                guard let self else { return }
                if success {
                    self.stateManager = nil
                    self.accessToken = nil
                    self.userEmail = nil
                    self.isAuthenticated = false
                } else {
                    self.error = "Sign out failed — please try again"
                }
            }
        )
    }

    // MARK: - Token Refresh

    func renewTokensIfNeeded() {
        stateManager?.renew { [weak self] _, err in
            if let err {
                Task { @MainActor in
                    self?.error = err.localizedDescription
                    self?.isAuthenticated = false
                }
            }
        }
    }
}
