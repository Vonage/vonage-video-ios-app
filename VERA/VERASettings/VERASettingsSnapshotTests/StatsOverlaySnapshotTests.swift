//
//  Created by Vonage on 5/3/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERADomain
import Combine

@testable import VERASettings

@Suite("StatsOverlay Snapshot Tests")
@MainActor
struct StatsOverlaySnapshotTests {
    
    // MARK: - Test Configuration
    
    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "StatsOverlayView"
    
    // MARK: - Core UI Tests
    
    @Test(
        "StatsOverlayView - Active States",
        arguments: [
            ("active-light", true, ColorScheme.light),
            ("active-dark", true, ColorScheme.dark),
        ])
    func activeStates(
        stateName: String,
        isActive: Bool,
        colorScheme: ColorScheme
    ) throws {
        let sut = makeSUT(isActive: isActive)
        
        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: stateName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(stateName)"
        )
    }
    
    @Test(
        "StatsOverlayView - Inactive States",
        arguments: [
            ("inactive-light", false, ColorScheme.light),
            ("inactive-dark", false, ColorScheme.dark),
        ])
    func inactiveStates(
        stateName: String,
        isActive: Bool,
        colorScheme: ColorScheme
    ) throws {
        let sut = makeSUT(isActive: isActive)
        
        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: stateName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(stateName)"
        )
    }
    
    @Test(
        "StatsOverlayView - Device Sizes",
        arguments: [
            ("iPhone-active", ViewImageConfig.iPhone13, true, CGSize(width: 390, height: 844)),
            ("iPad-active", ViewImageConfig.iPadPro12_9, true, CGSize(width: 1024, height: 1366)),
            ("iPhone-inactive", ViewImageConfig.iPhone13, false, CGSize(width: 390, height: 844)),
            ("iPad-inactive", ViewImageConfig.iPadPro12_9, false, CGSize(width: 1024, height: 1366)),
            ("iPhone-active-landscape", ViewImageConfig.iPhone13(.landscape), true, CGSize(width: 844, height: 390)),
            ("iPad-active-landscape", ViewImageConfig.iPadPro12_9(.landscape), true, CGSize(width: 1366, height: 1024)),
            ("iPhone-inactive-landscape", ViewImageConfig.iPhone13(.landscape), false, CGSize(width: 844, height: 390)),
            ("iPad-inactive-landscape", ViewImageConfig.iPadPro12_9(.landscape), false, CGSize(width: 1366, height: 1024)),
        ])
    func deviceSizes(
        deviceName: String,
        config: ViewImageConfig,
        isActive: Bool,
        frameSize: CGSize
    ) throws {
        let sut = makeSUT(isActive: isActive, frameSize: frameSize)
        
        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }
    
    @Test(
        "StatsOverlayView - Different Stats",
        arguments: [
            ("with-full-stats", await makeFullStats()),
            ("with-minimal-stats", await makeMinimalStats()),
            ("with-no-stats", NetworkMediaStats.empty),
        ])
    func differentStats(
        statsName: String,
        stats: NetworkMediaStats
    ) throws {
        let sut = makeSUT(isActive: true, stats: stats)
        
        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: statsName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(statsName)"
        )
    }
    
    // MARK: - Test Helpers
    
    private func makeSUT(
        isActive: Bool = true,
        stats: NetworkMediaStats = .mock,
        frameSize: CGSize = CGSize(width: 390, height: 844)
    ) -> AnyView {
        let repository = MockStatsSettingsRepository(
            initialPreferences: makePreferences(statsEnabled: isActive)
        )
        let statsDataSource = MockStatsOverlayDataSource()
        
        let viewModel = StatsOverlayViewModel(
            settingsRepository: repository,
            statsDataSource: statsDataSource
        )
        viewModel.isActive = isActive
        
        // Manually set statsText for snapshot consistency
        if isActive {
            viewModel.statsText = buildStatsText(stats)
        }
        
        return AnyView(
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple, .pink]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                StatsOverlayView(viewModel: viewModel)
                
            }.frame(width: frameSize.width, height: frameSize.height)
        )
}

    func makePreferences(statsEnabled: Bool) -> PublisherSettingsPreferences {
        var prefs = PublisherSettingsPreferences.default
        prefs.senderStatsEnabled = statsEnabled
        return prefs
    }

    private func buildStatsText(_ stats: NetworkMediaStats) -> String {
        var lines: [String] = []
        
        if let audioSend = stats.sentAudio {
            let codecLabel = audioSend.audioCodec.map { " (\($0))" } ?? ""
            lines.append("🔊 Audio Send\(codecLabel)")
            lines.append("Sent: \(audioSend.packetsSent), \(formatBytes(audioSend.bytesSent))")
            lines.append("Lost: \(audioSend.packetsLost)")
        }
        
        if let videoSend = stats.sentVideo {
            let codecLabel = videoSend.videoCodec.map { " (\($0))" } ?? ""
            lines.append("📹 Video Send\(codecLabel)")
            lines.append("Sent: \(videoSend.packetsSent), \(formatBytes(videoSend.bytesSent))")
            lines.append("Lost: \(videoSend.packetsLost)")
        }
        
        if let audioRecv = stats.receivedAudio {
            lines.append("🔈 Audio Recv")
            lines.append("Pkts: \(audioRecv.packetsReceived), Lost: \(audioRecv.packetsLost)")
            lines.append("Bytes: \(formatBytes(audioRecv.bytesReceived))")
        }
        
        if let videoRecv = stats.receivedVideo {
            lines.append("📺 Video Recv")
            lines.append("Recv: \(videoRecv.packetsReceived), \(formatBytes(Int64(videoRecv.bytesReceived)))")
            lines.append("Lost: \(videoRecv.packetsLost)")
        }
        
        return lines.isEmpty ? "Waiting for stats…" : lines.joined(separator: "\n")
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Sample Data
    
    private static func makeFullStats() async -> NetworkMediaStats {
        NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 1234,
                packetsLost: 5,
                bytesSent: 512_000,
                timestamp: Date().timeIntervalSince1970,
                audioCodec: "opus"
            ),
            sentVideo: VideoSendStats(
                packetsSent: 8765,
                packetsLost: 23,
                bytesSent: 5_242_880,
                timestamp: Date().timeIntervalSince1970,
                videoCodec: "VP8"
            ),
            receivedAudio: AudioReceiveStats(
                packetsReceived: 4321,
                packetsLost: 12,
                bytesReceived: 768_000,
                timestamp: Date().timeIntervalSince1970,
                estimatedBandwidth: 512_000
            ),
            receivedVideo: VideoReceiveStats(
                packetsReceived: 9876,
                packetsLost: 45,
                bytesReceived: 6_291_456,
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
    
    private static func makeMinimalStats() async -> NetworkMediaStats {
        NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 100,
                packetsLost: 0,
                bytesSent: 50_000,
                timestamp: Date().timeIntervalSince1970,
                audioCodec: "opus"
            ),
            sentVideo: nil,
            receivedAudio: nil,
            receivedVideo: nil
        )
    }
}

// MARK: - Mock Extensions

extension NetworkMediaStats {
    static var mock: NetworkMediaStats {
        NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 1000,
                packetsLost: 5,
                bytesSent: 500_000,
                timestamp: Date().timeIntervalSince1970,
                audioCodec: "opus"
            ),
            sentVideo: VideoSendStats(
                packetsSent: 5000,
                packetsLost: 25,
                bytesSent: 2_500_000,
                timestamp: Date().timeIntervalSince1970,
                videoCodec: "VP8"
            ),
            receivedAudio: AudioReceiveStats(
                packetsReceived: 950,
                packetsLost: 10,
                bytesReceived: 475_000,
                timestamp: Date().timeIntervalSince1970,
                estimatedBandwidth: 500_000
            ),
            receivedVideo: VideoReceiveStats(
                packetsReceived: 4800,
                packetsLost: 50,
                bytesReceived: 2_400_000,
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
