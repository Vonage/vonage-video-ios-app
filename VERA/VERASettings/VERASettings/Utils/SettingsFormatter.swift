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
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(clamping: bytes))
    }

    /// Formats a byte count into a human-readable string (e.g., "1.2 MB").
    public static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    /// Formats a packet count with thousands separator.
    public static func formatPackets(_ packets: UInt64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: packets)) ?? "\(packets)"
    }

    /// Formats a packet count with thousands separator.
    public static func formatPackets(_ packets: Int64) -> String {
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
    /// - Returns: A formatted string like "1.5 Mbps", "500 kbps", or `nil` if zero.
    private static func formatBandwidth(_ bps: Double) -> String? {
        return switch bps {
        case 0: nil
        case 1_000_000...:
            String(format: "%.1f Mbps", bps / 1_000_000)
        case 1_000...:
            String(format: "%.1f kbps", bps / 1_000)
        default:
            "\(bps) bps"
        }
    }
}
