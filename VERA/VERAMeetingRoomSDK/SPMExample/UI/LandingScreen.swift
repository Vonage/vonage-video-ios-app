//
//  Created by Vonage on 22/4/26.
//

import SwiftUI

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
            Color(.systemBackground)
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
                .font(.title.bold())

            Text(String(localized: "SPM Example"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Base URL"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField(baseURLString, text: $baseURLString)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Room Name"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField(String(localized: "Enter room name…"), text: $roomName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var joinButton: some View {
        Button {
            handleJoin()
        } label: {
            Text(String(localized: "Join Room"))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
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
