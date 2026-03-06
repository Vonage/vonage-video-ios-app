//
//  Created by Vonage on 25/2/26.
//

import SwiftUI
import VERASettings
import VERADomain
import Combine

@main
struct VERASettingsDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoMeetingView()
        }
    }
}

// MARK: - Demo Meeting View

struct DemoMeetingView: View {
    @StateObject private var viewModel = DemoViewModel()
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Simulated video background
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple, .pink]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Bottom control bar
                DemoControlBar(
                    onOpenSettings: {
                        showSettings.toggle()
                    }
                )
                .padding()
            }
            
            // Stats overlay (controlled by settings)
            StatsOverlayView(viewModel: viewModel.statsOverlayViewModel)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(
                    viewModel: viewModel.settingsViewModel,
                    statisticsViewModel: viewModel.statisticsViewModel
                )
            }
        }
    }
}

// MARK: - Demo Toolbar

struct DemoToolbar: View {
    let onClose: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            Spacer()
            
            Text("Demo Meeting")
                .font(.headline)
                .foregroundColor(.white)
        
            Spacer()
            
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
    }
}

// MARK: - Demo Control Bar

struct DemoControlBar: View {
    let onOpenSettings: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            // Settings button (only control in bottom bar, like VERA App)
            SettingsMeetingRoomButton(onShowSettings: onOpenSettings)
            
            Spacer()
        }
    }
}

// MARK: - Demo View Model

@MainActor
class DemoViewModel: ObservableObject {
    let settingsRepository: DemoSettingsRepository
    let statsDataSource: DemoStatsDataSource
    let settingsViewModel: SettingsViewModel
    let statisticsViewModel: StatisticsViewModel
    let statsOverlayViewModel: StatsOverlayViewModel
    
    init() {
        // Initialize repositories with stats enabled by default
        var initialPrefs = PublisherSettingsPreferences.default
        initialPrefs.senderStatsEnabled = true
        
        self.settingsRepository = DemoSettingsRepository(initialPreferences: initialPrefs)
        self.statsDataSource = DemoStatsDataSource()
        
        // Initialize ViewModels
        self.settingsViewModel = SettingsViewModel(
            repository: settingsRepository,
            settingsPreference: .default
        )
        
        self.statisticsViewModel = StatisticsViewModel(
            statsDataSource: statsDataSource,
            settingsRepository: settingsRepository
        )
        
        self.statsOverlayViewModel = StatsOverlayViewModel(
            settingsRepository: settingsRepository,
            statsDataSource: statsDataSource
        )
        
        // Setup
        statsOverlayViewModel.setup()
        
        // Start simulating stats
        Task {
            await startSimulatingStats()
        }
    }
    
    private func startSimulatingStats() async {
        while true {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await statsDataSource.updateStats(generateRandomStats())
        }
    }
    
    private func generateRandomStats() -> NetworkMediaStats {
        NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: Int64.random(in: 1000...2000),
                packetsLost: Int64.random(in: 0...10),
                bytesSent: Int64.random(in: 400_000...600_000),
                timestamp: Date().timeIntervalSince1970,
                audioCodec: "opus"
            ),
            sentVideo: VideoSendStats(
                packetsSent: Int64.random(in: 5000...10000),
                packetsLost: Int64.random(in: 10...50),
                bytesSent: Int64.random(in: 2_000_000...3_000_000),
                timestamp: Date().timeIntervalSince1970,
                videoCodec: "VP8"
            ),
            receivedAudio: AudioReceiveStats(
                packetsReceived: Int64.random(in: 900...1900),
                packetsLost: Int64.random(in: 0...15),
                bytesReceived: Int64.random(in: 380_000...580_000),
                timestamp: Date().timeIntervalSince1970,
                estimatedBandwidth: Int64.random(in: 450_000...550_000)
            ),
            receivedVideo: VideoReceiveStats(
                packetsReceived: UInt64.random(in: 4500...9500),
                packetsLost: UInt64.random(in: 20...80),
                bytesReceived: UInt64.random(in: 1_900_000...2_900_000),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}

// MARK: - Demo Settings Repository

final class DemoSettingsRepository: PublisherSettingsRepository {
    private nonisolated let subject: CurrentValueSubject<PublisherSettingsPreferences, Never>
    
    nonisolated var preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never> {
        subject.eraseToAnyPublisher()
    }
    
    init(initialPreferences: PublisherSettingsPreferences = .default) {
        self.subject = CurrentValueSubject(initialPreferences)
    }
    
    func getPreferences() async -> PublisherSettingsPreferences {
        subject.value
    }
    
    func save(_ preferences: PublisherSettingsPreferences) async {
        subject.send(preferences)
    }
    
    func reset() async {
        subject.send(.default)
    }
}

// MARK: - Demo Stats Data Source

final class DemoStatsDataSource: StatsDataSource {
    private nonisolated let subject: CurrentValueSubject<NetworkMediaStats, Never>
    
    nonisolated var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
    }
    
    init(initialStats: NetworkMediaStats = .empty) {
        self.subject = CurrentValueSubject(initialStats)
    }
    
    func updateStats(_ stats: NetworkMediaStats) async {
        subject.send(stats)
    }
}
