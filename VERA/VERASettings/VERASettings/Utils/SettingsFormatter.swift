//
//  Created by Vonage on 03/03/2026.
//

import Foundation
import VERADomain

// MARK: - VideoSendStats Extensions

extension VideoSendStats {
    /// Formatted string of packets sent with thousands separator.
    var packetsSentFormmatted: String {
        SettingsFormatter.formatPackets(self.packetsSent)
    }

    /// Formatted string of packets lost with thousands separator.
    var packetsLostFormmatted: String {
        SettingsFormatter.formatPackets(self.packetsLost)
    }

    /// Human-readable byte count for bytes sent (e.g., "1.2 MB").
    var bytesSentFormmatted: String {
        SettingsFormatter.formatBytes(self.bytesSent)
    }
}

// MARK: - VideoReceiveStats Extensions

extension VideoReceiveStats {
    /// Formatted string of packets received with thousands separator.
    var packetsReceivedFormmatted: String {
        SettingsFormatter.formatPackets(self.packetsReceived)
    }

    /// Formatted string of packets lost with thousands separator.
    var packetsLostFormmatted: String {
        SettingsFormatter.formatPackets(self.packetsLost)
    }

    /// Human-readable byte count for bytes received (e.g., "1.2 MB").
    var bytesReceivedFormmatted: String {
        SettingsFormatter.formatBytes(self.bytesReceived)
    }
}

// MARK: - AudioSendStats Extensions

extension AudioSendStats {
    /// Formatted string of packets sent with thousands separator.
    var packetsSentFormmatted: String {
        SettingsFormatter.formatPackets(self.packetsSent)
    }

    /// Formatted string of packets lost with thousands separator.
    var packetsLostFormmatted: String {
        SettingsFormatter.formatPackets(self.packetsLost)
    }

    /// Human-readable byte count for bytes sent (e.g., "1.2 MB").
    var bytesSentFormmatted: String {
        SettingsFormatter.formatBytes(self.bytesSent)
    }
}

// MARK: - AudioReceiveStats Extensions

extension AudioReceiveStats {
    /// Formatted string of packets received with thousands separator.
    var packetsReceivedFormmatted: String {
        SettingsFormatter.formatPackets(self.packetsReceived)
    }

    /// Formatted string of packets lost with thousands separator.
    var packetsLostFormmatted: String {
        SettingsFormatter.formatPackets(self.packetsLost)
    }

    /// Human-readable byte count for bytes received (e.g., "1.2 MB").
    var bytesReceivedFormmatted: String {
        SettingsFormatter.formatBytes(self.bytesReceived)
    }

    /// Formatted bandwidth string (e.g., "1.5 Mbps"), or `nil` if not available.
    var estimatedBandwidthFormatted: String? {
        SettingsFormatter.formatBandwidth(self.estimatedBandwidth)
    }
}

// MARK: - SettingsFormatter

/// Utility for formatting network statistics and bitrates for display in the settings UI.
enum SettingsFormatter {

    /// Formats a byte count into a human-readable string (e.g., "1.2 MB").
    public static func formatBytes(_ bytes: UInt64) -> String {
        guard bytes > 0 else { return "0 KB" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(clamping: bytes))
    }

    /// Formats a byte count into a human-readable string (e.g., "1.2 MB").
    public static func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 KB" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    /// Formats a packet count with thousands separators (e.g., "5,000").
    public static func formatPackets(_ packets: UInt64) -> String {
        formatPackets(Int64(clamping: packets))
    }

    /// Formats a packet count with thousands separators (e.g., "5,000").
    public static func formatPackets(_ packets: Int64) -> String {
        guard packets > 0 else { return "0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: packets)) ?? "\(packets)"
    }

    /// Formats bitrate from Int64 to a human-readable string (e.g., "1.5 Mbps").
    ///
    /// - Parameter bitsPerSecond: The bitrate in bits per second, or `nil`.
    /// - Returns: A formatted string, or `nil` if the input is `nil` or zero.
    public static func formatBandwidth(_ bitsPerSecond: Int64?) -> String? {
        return formatBandwidth(Double(bitsPerSecond ?? 0))
    }

    /// Formats bitrate from Int32 to a human-readable string (e.g., "1.5 Mbps").
    ///
    /// - Parameter bitsPerSecond: The bitrate in bits per second, or `nil`.
    /// - Returns: A formatted string, or `nil` if the input is `nil` or zero.
    public static func formatBandwidth(_ bitsPerSecond: Int32?) -> String? {
        return formatBandwidth(Double(bitsPerSecond ?? 0))
    }

    /// Formats bitrate in bits per second to a human-readable string.
    ///
    /// - Parameter bps: The bitrate in bits per second.
    /// - Returns: A formatted string like "1.5 Mbps", "500 kbps", "bps", or `nil` if zero or negative.
    private static func formatBandwidth(_ bps: Double) -> String? {
        return switch bps {
        case ...0: nil
        case 1_000_000...:
            String(format: "%.1f Mbps", bps / 1_000_000)
        case 1_000...:
            String(format: "%.1f kbps", bps / 1_000)
        default:
            "\(bps) bps"
        }
    }

    /// Formats a frame rate as a string (e.g., "30 fps").
    static func formatFrameRate(_ fps: Double) -> String {
        String(format: "%.0f fps", fps)
    }

    /// Formats width × height as a resolution string (e.g., "1280×720").
    static func formatResolution(width: Int32, height: Int32) -> String {
        "\(width)×\(height)"
    }

    /// Formats a duration in milliseconds into a human-readable string.
    static func formatDuration(milliseconds: Int64) -> String {
        let seconds = Double(milliseconds) / 1_000
        if seconds < 1 {
            return "\(milliseconds) ms"
        } else if seconds < 60 {
            return String(format: "%.1f s", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }

    /// Sorts video layers by resolution (pixel count) ascending.
    ///
    /// Ensures that index 0 is the lowest resolution ("Low Quality")
    /// and the last index is the highest resolution ("High Quality").
    ///
    /// - Parameter layers: The unsorted array of ``VideoLayerStats``.
    /// - Returns: Layers ordered from lowest to highest resolution.
    static func sortedByResolution(_ layers: [VideoLayerStats]) -> [VideoLayerStats] {
        layers.sorted { Int($0.width) * Int($0.height) < Int($1.width) * Int($1.height) }
    }

    /// Returns the quality label for a simulcast layer at the given sorted index.
    ///
    /// - Parameters:
    ///   - index: The zero-based index of the layer after sorting by resolution.
    ///   - count: The total number of layers.
    /// - Returns: A localized label: "Low Quality", "Medium Quality", or "High Quality".
    static func qualityLabel(index: Int, count: Int) -> String {
        if count == 2 {
            return index == 0 ? "Low Quality".localized : "High Quality".localized
        }
        switch index {
        case 0: return "Low Quality".localized
        case count - 1: return "High Quality".localized
        default: return "Medium Quality".localized
        }
    }

    /// Formats a ``NetworkCondition`` value for display.
    static func formatNetworkCondition(_ condition: NetworkCondition) -> String {
        switch condition {
        case .unknown: "Unknown".localized
        case .critical: "Critical".localized
        case .warning: "Warning".localized
        case .fair: "Fair".localized
        case .good: "Good".localized
        case .excellent: "Excellent".localized
        }
    }

    /// Formats a ``QualityLimitationReason`` value for display.
    static func formatQualityLimitation(_ reason: QualityLimitationReason) -> String {
        switch reason {
        case .none: "None".localized
        case .bandwidth: "Bandwidth".localized
        case .cpu: "CPU"
        case .codec: "Codec".localized
        case .resolution: "Resolution".localized
        case .layerChange: "Layer Change".localized
        }
    }

    /// Formats a ``NetworkDegradationSource`` value for display.
    static func formatDegradationSource(_ source: NetworkDegradationSource) -> String {
        switch source {
        case .local: "Local".localized
        case .remote: "Remote".localized
        case .bothOrUnclear: "Both or Unclear".localized
        case .unknown: "Unknown".localized
        }
    }
}

// MARK: - VideoReceiveStats Display Extensions

extension VideoReceiveStats {
    /// Formatted resolution string (e.g., "1280×720").
    var resolutionFormatted: String {
        SettingsFormatter.formatResolution(width: width, height: height)
    }

    /// Formatted decoded frame rate (e.g., "30 fps").
    var decodedFrameRateFormatted: String {
        SettingsFormatter.formatFrameRate(decodedFrameRate)
    }

    /// Formatted freeze count and duration.
    var freezeFormatted: String {
        "\(freezeCount) (\(SettingsFormatter.formatDuration(milliseconds: totalFreezesDuration)))"
    }

    /// Formatted pause count and duration.
    var pauseFormatted: String {
        "\(pauseCount) (\(SettingsFormatter.formatDuration(milliseconds: totalPausesDuration)))"
    }

    /// Formatted bitrate.
    var bitrateFormatted: String? {
        SettingsFormatter.formatBandwidth(bitrate)
    }
}

// MARK: - VideoSendStats Display Extensions

extension VideoSendStats {
    /// Formatted video frame rate (e.g., "30 fps").
    var videoFrameRateFormatted: String {
        SettingsFormatter.formatFrameRate(videoFrameRate)
    }
}

// MARK: - TransportStats Display Extensions

extension TransportStats {
    /// Formatted estimated bandwidth.
    var bandwidthFormatted: String? {
        SettingsFormatter.formatBandwidth(connectionEstimatedBandwidth)
    }

    /// Formatted estimated bandwidth, showing "Datos no disponibles" when not yet available.
    /// Used specifically for display in stats UI where unavailable state should be explicit.
    var bandwidthFormattedWithUnavailable: String? {
        if connectionEstimatedBandwidth <= 0 {
            return "Data unavailable".localized
        }
        return SettingsFormatter.formatBandwidth(connectionEstimatedBandwidth)
    }

    /// Formatted network condition.
    var conditionFormatted: String {
        SettingsFormatter.formatNetworkCondition(networkCondition)
    }
}
