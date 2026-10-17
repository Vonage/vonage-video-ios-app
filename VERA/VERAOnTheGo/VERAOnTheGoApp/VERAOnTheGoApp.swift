//
//  Created by Vonage on 17/10/26.
//

import SwiftUI
import VERAOnTheGo

@main
struct VERAOnTheGoDemoApp: App {
    var body: some Scene {
        WindowGroup {
            OnTheGoDemoHost()
                .preferredColorScheme(.dark)
        }
    }
}

/// Hosts the On-the-Go feature against a fake call so the suggestion,
/// audio-first screen, and settings row can be exercised without a session.
@MainActor
private struct OnTheGoDemoHost: View {
    @State private var session = DemoSession()

    var body: some View {
        Group {
            if session.hasLeft {
                leftCall
            } else if session.viewModel.state == .active {
                OnTheGoView(viewModel: session.viewModel)
            } else {
                fakeCall
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("--active") {
                session.viewModel.enterManually()
            }
        }
        .sheet(isPresented: $session.showSettings) {
            NavigationStack {
                Form {
                    session.factory.makeSettingsRow()
                }
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { session.showSettings = false }
                    }
                }
            }
        }
    }

    private var fakeCall: some View {
        VStack(spacing: 20) {
            ZStack(alignment: .top) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    tile("You", color: .indigo)
                    tile("Alice", color: .teal)
                    tile("Ben", color: .brown)
                    tile("Chen", color: .purple)
                }
                if session.viewModel.state == .suggested {
                    OnTheGoSuggestionBanner(viewModel: session.viewModel)
                        .padding(.top, 8)
                }
            }

            Text("In a call")
                .font(.title2.weight(.semibold))
            Text("5 participants · Alice is speaking")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Simulated walking raises the On-the-Go suggestion.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Switch to On-the-Go") { session.viewModel.enterManually() }
                .buttonStyle(.borderedProminent)
            Button(session.isSharing ? "Stop sharing" : "Start screen share") {
                session.toggleShare()
            }
            .buttonStyle(.bordered)
            Button("Settings") { session.showSettings = true }
                .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private func tile(_ name: String, color: Color) -> some View {
        ZStack(alignment: .bottomLeading) {
            color.opacity(0.85)
            Text(name)
                .font(.caption.weight(.semibold))
                .padding(8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var leftCall: some View {
        VStack(spacing: 16) {
            Text("You left the call")
                .font(.title2.weight(.semibold))
            Button("Rejoin") { session.rejoin() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

@MainActor
@Observable
private final class DemoSession {
    let factory: OnTheGoFactory
    let viewModel: OnTheGoViewModel

    var showSettings = false
    private(set) var hasLeft = false
    private(set) var isSharing = true
    private var isMicEnabled = true
    private var isCameraEnabled = true
    private var isConnected = true

    private let shareView = AnyView(
        ZStack {
            LinearGradient(
                colors: [.blue, .black],
                startPoint: .top,
                endPoint: .bottom
            )
            Text("Shared slides")
                .font(.title.weight(.semibold))
                .foregroundStyle(.white)
        }
    )

    init() {
        let defaults = UserDefaults(suiteName: "VERAOnTheGoDemo") ?? .standard
        defaults.set(true, forKey: "onTheGo.suggestWhenMoving")
        let factory = OnTheGoFactory(
            configuration: .init(),
            preferences: UserDefaultsOnTheGoPreferencesRepository(userDefaults: defaults),
            motionProvider: SimulatedMotionActivityProvider(delay: 1.5)
        )
        let owner = DemoOwner()
        let viewModel = factory.makeViewModel(
            actions: OnTheGoCallActions(
                toggleMic: { owner.session?.toggleMic() },
                toggleCamera: { owner.session?.toggleCamera() },
                endCall: { owner.session?.leave() }
            )
        )
        self.factory = factory
        self.viewModel = viewModel
        owner.session = self
        push()
    }

    func toggleShare() {
        isSharing.toggle()
        push()
    }

    func rejoin() {
        hasLeft = false
        isConnected = true
        isMicEnabled = true
        isCameraEnabled = true
        push()
    }

    private func toggleMic() {
        isMicEnabled.toggle()
        push()
    }

    private func toggleCamera() {
        isCameraEnabled.toggle()
        push()
    }

    private func leave() {
        isConnected = false
        hasLeft = true
        push()
    }

    private func push() {
        let share: OnTheGoCallSnapshot.Participant? =
            isSharing
            ? .init(
                id: "share",
                name: "Alice",
                isScreenshare: true,
                view: shareView
            )
            : nil
        viewModel.update(
            snapshot: OnTheGoCallSnapshot(
                isConnected: isConnected,
                isMicEnabled: isMicEnabled,
                isCameraEnabled: isCameraEnabled,
                participantCount: 5,
                activeSpeakerName: isConnected ? "Alice" : nil,
                screenShareParticipant: share
            )
        )
    }
}

/// Breaks the init cycle between the session and the action closures.
@MainActor
private final class DemoOwner {
    weak var session: DemoSession?
}
