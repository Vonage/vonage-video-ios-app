//
//  Created by Vonage on 20/4/26.
//

import SwiftUI
import VERACommonUI

struct LandingScreen: View {

    let onJoin: (_ roomName: String, _ baseURL: URL) -> Void

    @State private var roomName: String = "test"
    // Replace with your VERA backend URL
    @State private var baseURLString: String = "https://api.example.com/"
    @State private var showInvalidURLAlert = false

    private var isJoinEnabled: Bool {
        !roomName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            VERACommonUIAsset.SemanticColors.surface.swiftUIColor
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                titleSection

                formSection

                joinButton

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .alert(
            String(localized: "Invalid URL"),
            isPresented: $showInvalidURLAlert
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "Please enter a valid base URL."))
        }
    }

    // MARK: - Subviews

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(String(localized: "VERAMeetingRoomSDK"))
                .adaptiveFont(.headline)
                .foregroundColor(VERACommonUIAsset.SemanticColors.textPrimary.swiftUIColor)

            Text(String(localized: "Demo App"))
                .adaptiveFont(.bodyBase)
                .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Base URL"))
                    .adaptiveFont(.caption)
                    .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)

                TextField(baseURLString, text: $baseURLString)
                    .adaptiveFont(.bodyBase)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .padding(12)
                    .cornerRadius(BorderRadius.small)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Room Name"))
                    .adaptiveFont(.caption)
                    .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)

                TextField(String(localized: "Enter room name…"), text: $roomName)
                    .adaptiveFont(.bodyBase)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .cornerRadius(BorderRadius.small)
            }
        }
    }

    private var joinButton: some View {
        FilledButton(text: Text(String(localized: "Join Room"))) {
            handleJoin()
        }
        .disabled(!isJoinEnabled)
    }

    // MARK: - Actions

    private func handleJoin() {
        let trimmedRoom = roomName.trimmingCharacters(in: .whitespaces)
        let trimmedURL = baseURLString.trimmingCharacters(in: .whitespaces)

        guard let url = URL(string: trimmedURL), url.scheme != nil else {
            showInvalidURLAlert = true
            return
        }

        onJoin(trimmedRoom, url)
    }
}

#Preview {
    LandingScreen { _, _ in }
}
