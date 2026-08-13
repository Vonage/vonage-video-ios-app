//
//  Created by Vonage on 4/7/25.
//

import Combine
import Foundation
import SwiftUI
import VERACommonUI
import VERACore
import VERADomain
import VERAE2E
import VERAMeetingRoom
import VERAMeetingRoomSDK
import VERAVonage

#if ARCHIVING_ENABLED
    import VERAArchiving
#endif

#if BACKGROUND_EFFECTS_ENABLED
    import VERABackgroundEffects
#endif

#if SETTINGS_ENABLED
    import VERASettings
#endif

#if AUDIOEFFECTS_ENABLED
    import VERAAudioEffects
#endif

#if AUDIODIAGNOSTICS_ENABLED
    import VERAAudioDiagnostics
#endif

#if OKTA_ENABLED
    import VERAOKTA
#endif

@main
struct VERAApp: App {
    @StateObject var navigationCoordinator = NavigationCoordinator()

    #if DEBUG
        @StateObject private var meetingRoomCustomizationProvider = MeetingRoomCustomizationProvider()
        @State private var isMeetingRoomCustomizationMenuPresented = false
    #endif

    var dependencyContainer: DependencyContainer = {
        let baseHttpClient = AppHTTPClientProvider(
            isE2EEnabled: E2EConfiguration.isEnabled
        )()

        #if OKTA_ENABLED
            let authManager = OktaAuthManager()
            authManager.restoreSession()
            let tokenProvider = OktaTokenProvider(authManager: authManager)
            let httpClient = TokenInjectingHTTPClient(
                wrapped: baseHttpClient,
                tokenProvider: tokenProvider
            )
            let oktaFactory = OKTAFactory(authManager: authManager)
            return DependencyContainer(httpClient: httpClient, oktaFactory: oktaFactory)
        #else
            return DependencyContainer(httpClient: baseHttpClient)
        #endif
    }()

    var handleUniversalLink: HandleUniversalLink {
        HandleUniversalLink(
            baseURL: dependencyContainer.baseURL,
            navigator: navigationCoordinator)
    }

    @State private var previousPath = NavigationPath()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationCoordinator.path) {
                makeLandingPage()
                    .navigationDestination(for: AppRoute.self) { destination in
                        switch destination {
                        case .waitingRoom(let roomName):
                            if navigationCoordinator.isInMeeting {
                                LoaderModalView()
                            } else {
                                makeWaitingRoom(roomName: roomName)
                            }
                        case .goodbye(let roomName):
                            makeGoodbyePage(roomName: roomName)
                        case .meetingRoom:
                            fatalError("Should not be able to navigate to meeting room from landing")
                        case .landing:
                            fatalError("Should not be able to navigate to landing")
                        case .settings:
                            fatalError("Should not be able to navigate to settings")
                        }
                    }
            }
            .fullScreenCover(isPresented: $navigationCoordinator.isInMeeting) {
                if let newRoomRequest = navigationCoordinator.currentMeetingRoomRequest {
                    makeMeetingRoom(request: newRoomRequest)
                        .onDisappear {
                            dependencyContainer.publisherRepository.resetPublisher()
                            #if ARCHIVING_ENABLED
                                Task {
                                    await navigationCoordinator.archivesViewModel?.loadData()
                                }
                            #endif
                        }
                        .alert(item: $navigationCoordinator.alertItem) { $0.view }
                }
            }
            .environmentObject(navigationCoordinator)
            .alert(item: $navigationCoordinator.alertItem) { $0.view }
            .onOpenURL { url in
                handleUniversalLink(url)
            }
            .tint(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
            #if DEBUG
                .sheet(isPresented: $isMeetingRoomCustomizationMenuPresented) {
                    MeetingRoomCustomizationMenu(provider: meetingRoomCustomizationProvider)
                }
            #endif
        }
    }

    // MARK: - Factory Methods

    var landingPageFactory: LandingPageFactory { dependencyContainer.landingPageFactory }
    var waitingRoomFactory: WaitingRoomFactory { dependencyContainer.waitingRoomFactory }
    var goodByePageFactory: GoodByePageFactory { dependencyContainer.goodByePageFactory }

    #if ARCHIVING_ENABLED
        var archiveFactory: ArchivingFactory { dependencyContainer.archivingFactory }
    #endif

    #if BACKGROUND_EFFECTS_ENABLED
        var backgroundEffectFactory: BackgroundEffectFactory { dependencyContainer.backgroundEffectFactory }
    #endif

    #if SETTINGS_ENABLED
        var settingsFactory: SettingsFactory { dependencyContainer.settingsFactory }
    #endif

    #if AUDIOEFFECTS_ENABLED
        var audioEffectsFactory: AudioEffectsFactory { dependencyContainer.audioEffectsFactory }
    #endif

    private func makeLandingPage() -> some View {
        let landing = landingPageFactory.make { roomName in
            navigationCoordinator.go(to: .waitingRoom(roomName))
        }

        return Group {
            #if AUTHENTICATION_ENABLED
                landing
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            #if OKTA_ENABLED
                                NavBarAuthComponentButton(
                                    viewModel: makeOrGetNavBarAuthButtonViewModel()
                                )
                            #endif
                        }
                    }
                    .sheet(isPresented: $navigationCoordinator.showSignIn) {
                        #if OKTA_ENABLED
                            SignInView(
                                providers: [IDProvider(id: "okta", displayName: "Okta")],
                                onProviderSelected: { _ in
                                    guard
                                        let window = UIApplication.shared.connectedScenes
                                            .compactMap({ $0 as? UIWindowScene })
                                            .flatMap(\.windows)
                                            .first(where: \.isKeyWindow)
                                    else { return }
                                    try await dependencyContainer.oktaFactory.authenticationManager.signIn(from: window)
                                }
                            )
                            .presentationDetents([.height(200)])
                            .presentationDragIndicator(.visible)
                        #endif
                    }
            #else
                landing
            #endif
        }
    }

    #if OKTA_ENABLED
        @MainActor
        private func makeOrGetNavBarAuthButtonViewModel() -> NavBarAuthButtonViewModel {
            if let existing = navigationCoordinator.navBarAuthButtonViewModel {
                return existing
            }
            let viewModel = dependencyContainer.oktaFactory.makeNavBarAuthButtonViewModel(
                onLoginTapped: { [weak navigationCoordinator] in
                    navigationCoordinator?.showSignIn = true
                },
                onLogoutTapped: {
                    try? await self.dependencyContainer.oktaFactory.authenticationManager.signOut()
                }
            )
            navigationCoordinator.navBarAuthButtonViewModel = viewModel
            return viewModel
        }
    #endif

    private func makeWaitingRoom(roomName: String) -> some View {
        var waitingRoomViewModel: WaitingRoomViewModel

        if let existingViewModel = navigationCoordinator.waitingRoomViewModel,
            existingViewModel.roomName == roomName
        {
            // Reuse existing view model for the same room
            waitingRoomViewModel = existingViewModel
        } else {
            // Create a new waiting room view and view model for the specified room
            let result = waitingRoomFactory.make(roomName: roomName) {
                switch $0 {
                case .presentAlert(let alertItem):
                    navigationCoordinator.showAlert(alertItem)
                case .navigateToSettings:
                    navigationCoordinator.go(to: .settings)
                case .navigateToMeetingRoom(let roomName):
                    navigationCoordinator.go(to: .meetingRoom(roomName))
                default: break
                }
            }
            waitingRoomViewModel = result.viewModel
            waitingRoomViewModel.toolbarButtons = makeWaitingRoomToolbarButtons()
            waitingRoomViewModel.extraTrailingButtons = makeWaitingRoomTrailingButtons()

            #if AUDIODIAGNOSTICS_ENABLED
                // Create audio output test button (same visual style as the Camera selector)
                // to be displayed next to the Camera selector in the waiting room.
                let audioButton = dependencyContainer.audioDiagnosticsFactory.makeWaitingRoomButton()
                waitingRoomViewModel.audioOutputTestButton = ViewHolder(id: "audioOutputTest") {
                    audioButton
                }
            #endif

            #if BACKGROUND_EFFECTS_ENABLED
                waitingRoomViewModel.onPublisherReady = { [weak navigationCoordinator] in
                    navigationCoordinator?.videoEffectsViewModel?.reapplyCurrentEffect()
                }
            #endif

            navigationCoordinator.waitingRoomViewModel = waitingRoomViewModel
        }

        return waitingRoomFactory.make(viewModel: waitingRoomViewModel)
            #if DEBUG
                .toolbar(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        meetingRoomCustomizationMenuTrigger
                    }
                }
            #endif
            .onDisappear {
                // Required if the user goes back to the landing page
                dependencyContainer.cameraPreviewProviderRepository.resetPublisher()
                // Clear view model when leaving the waiting room
                navigationCoordinator.waitingRoomViewModel = nil
            }
    }

    /// Creates toolbar buttons for the top-right corner of the waiting room.
    /// Currently includes only the Settings button with icon-only design.
    /// These buttons use a plain icon design without circular backgrounds.
    private func makeWaitingRoomToolbarButtons() -> [ViewHolder] {
        var buttons: [ViewHolder] = []

        #if SETTINGS_ENABLED
            // Settings button with icon-only design (no circular background).
            // Presents the in-app SettingsView as a sheet.
            let settingsButton = settingsFactory.makeWaitingRoomButton()
            buttons.append(ViewHolder(id: "Settings", content: { settingsButton }))
        #endif

        return buttons
    }

    /// Creates trailing buttons for the waiting room (Background Effects, Audio Effects).
    /// These buttons use circular backgrounds and are positioned below the toolbar.
    private func makeWaitingRoomTrailingButtons() -> [ViewHolder] {
        var buttons: [ViewHolder] = []

        #if BACKGROUND_EFFECTS_ENABLED
            let (_, viewModel) = backgroundEffectFactory.makeEffectsButton(
                getCurrentPublisher: dependencyContainer.cameraPreviewProviderRepository.getPublisher
            )
            navigationCoordinator.videoEffectsViewModel = viewModel

            if let videoEffectsViewModel = navigationCoordinator.videoEffectsViewModel {
                let view = backgroundEffectFactory.makeEffectsButton(
                    viewModel: videoEffectsViewModel
                )

                buttons.append(ViewHolder(id: "Effects", content: { view }))
            }
        #endif

        #if AUDIOEFFECTS_ENABLED
            let (_, audioViewModel) = audioEffectsFactory.makeWaitingNoiseSuppressionButton(
                getCurrentPublisher: dependencyContainer.cameraPreviewProviderRepository.getPublisher
            )
            navigationCoordinator.waitingNoiseSuppressionViewModel = audioViewModel

            let audioButton = audioEffectsFactory.makeWaitingNoiseSuppressionButton(
                viewModel: audioViewModel
            )
            buttons.append(ViewHolder(id: "NoiseSuppresion", content: { audioButton }))
        #endif

        return buttons
    }

    #if DEBUG
        private var meetingRoomCustomizationMenuTrigger: some View {
            Button {
                isMeetingRoomCustomizationMenuPresented = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("meeting-room-customization-menu-trigger")
        }
    #endif

    /// Creates the meeting room using the SDK builder, replacing ~200 lines
    /// of manual dependency wiring, plugin registration, and overlay composition.
    private func makeMeetingRoom(request: NewRoomRequest) -> some View {
        // Reuse existing SDK-built view if available for the same room
        if let existing = navigationCoordinator.meetingRoomPrebuilt,
            existing.viewModel.roomName == request.roomName
        {
            return existing.view
                .onDisappear {
                    navigationCoordinator.meetingRoomViewModel = nil
                    navigationCoordinator.meetingRoomPrebuilt = nil
                }
        }

        let currentVideoEffect =
            navigationCoordinator.videoEffectsViewModel?.selectedEffect
            ?? dependencyContainer.videoEffectRepository.load()
        let currentNoiseSuppressionState = navigationCoordinator.waitingNoiseSuppressionViewModel?.state ?? .disabled

        let builder = MeetingRoomBuilder(
            baseURL: dependencyContainer.baseURL,
            roomName: request.roomName
        ).configuration(
            MeetingRoomConfiguration(
                allowMicrophoneControl: dependencyContainer.appConfig.audioSettings.allowMicrophoneControl,
                allowCameraControl: dependencyContainer.appConfig.videoSettings.allowCameraControl,
                showParticipantList: dependencyContainer.appConfig.meetingRoomSettings.showParticipantList,
                allowPictureInPicture: dependencyContainer.appConfig.meetingRoomSettings.allowPictureInPicture
            )
        )
        .enabledFeatures(dependencyContainer.meetingRoomEnabledFeatures)
        .publisherSettings(
            request.publisherSettings
                .initialVideoEffect(currentVideoEffect)
                .noiseSuppressionState(currentNoiseSuppressionState)
        )
        .appGroupIdentifier(EnvironmentConstants.veraAppGroupIdentifier)
        .broadcastExtensionBundleId(
            (Bundle.main.bundleIdentifier ?? "com.vonage.VERA") + ".BroadcastExtension"
        )
        .sessionKeyHolder(dependencyContainer.sessionKeyHolder)
        .onAction { [weak navigationCoordinator] action in
            switch action {
            case .callDidEnd:
                navigationCoordinator?.go(to: .goodbye(request.roomName))
            case .goBack(let room):
                navigationCoordinator?.go(to: .waitingRoom(room))
            }
        }

        builder.httpClientFactory(
            SharedMeetingRoomHTTPClientFactory(httpClient: dependencyContainer.httpClient)
        )
        if E2EConfiguration.isEnabled {
            builder
                .sessionRepositoryFactory(E2EMeetingRoomSessionRepositoryFactory())
                .archivingDataSourceFactory(E2EMeetingRoomArchivingDataSourceFactory())
        }
        #if DEBUG
            builder.uiProvider(meetingRoomCustomizationProvider)
        #endif

        let result = builder.build()
        navigationCoordinator.meetingRoomViewModel = result.viewModel
        navigationCoordinator.meetingRoomPrebuilt = result

        return result.view
            .onDisappear {
                // Clear cached meeting room when leaving
                navigationCoordinator.meetingRoomViewModel = nil
                navigationCoordinator.meetingRoomPrebuilt = nil
            }
    }

    private func makeGoodbyePage(roomName: String) -> some View {
        let viewModel: GoodByeViewModel

        if let existingViewModel = navigationCoordinator.goodByeViewModel, existingViewModel.roomName == roomName {
            viewModel = existingViewModel
        } else {
            let (_, newViewModel) = goodByePageFactory.make(roomName: roomName) {
                navigationCoordinator.go(to: .waitingRoom(roomName))
            } onReturnToLanding: {
                navigationCoordinator.go(to: .landing)
            } additionalContentView: {
                makeGoodbyeAdditionalContentView(roomName: roomName)
            }

            navigationCoordinator.goodByeViewModel = newViewModel
            viewModel = newViewModel
        }

        return goodByePageFactory.make(viewModel: viewModel) {
            makeGoodbyeAdditionalContentView(roomName: roomName)
        }
        .navigationBarHidden(true)
    }

    func makeGoodbyeAdditionalContentView(roomName: RoomName) -> some View {
        #if ARCHIVING_ENABLED
            if let viewModel = navigationCoordinator.archivesViewModel {
                return AnyView(archiveFactory.make(viewModel: viewModel))
            } else {
                let (view, viewModel) = archiveFactory.make { recording in
                    Task { @MainActor in
                        UIApplication.shared.open(recording.url)
                    }
                }
                navigationCoordinator.archivesViewModel = viewModel
                return AnyView(view)
            }
        #else
            return EmptyView()
        #endif
    }
}
