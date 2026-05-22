//
//  Created by Vonage.
//

import Foundation
import Testing
import VERADomain

@testable import VERASettings

@Suite("SettingsFormatter Tests")
struct SettingsFormatterTests {

    // MARK: - formatBytes Tests

    @Test("formatBytes returns 0 KB for zero UInt64")
    func formatBytesReturnsZeroKBForZeroUInt64() {
        let result = SettingsFormatter.formatBytes(UInt64(0))
        #expect(result == "0 KB")
    }

    @Test("formatBytes returns 0 KB for zero Int64")
    func formatBytesReturnsZeroKBForZeroInt64() {
        let result = SettingsFormatter.formatBytes(Int64(0))
        #expect(result == "0 KB")
    }

    @Test("formatBytes formats kilobytes correctly")
    func formatBytesFormatsKilobytes() {
        let result = SettingsFormatter.formatBytes(Int64(1024))
        #expect(result == "1 KB")
    }

    @Test("formatBytes formats megabytes correctly")
    func formatBytesMegabytes() {
        let result = SettingsFormatter.formatBytes(Int64(1_048_576))
        #expect(result == "1 MB")
    }

    @Test("formatBytes UInt64 formats non-zero values")
    func formatBytesUInt64NonZero() {
        let result = SettingsFormatter.formatBytes(UInt64(2048))
        #expect(result == "2 KB")
    }

    // MARK: - formatPackets Tests

    @Test("formatPackets returns 0 for zero UInt64")
    func formatPacketsReturnsZeroForZeroUInt64() {
        let result = SettingsFormatter.formatPackets(UInt64(0))
        #expect(result == "0")
    }

    @Test("formatPackets returns 0 for zero Int64")
    func formatPacketsReturnsZeroForZeroInt64() {
        let result = SettingsFormatter.formatPackets(Int64(0))
        #expect(result == "0")
    }

    @Test("formatPackets uses thousands separator")
    func formatPacketsUsesThousandsSeparator() {
        let result = SettingsFormatter.formatPackets(Int64(5000))
        let expected = NumberFormatter.localizedDecimal(5000)
        #expect(result == expected)
    }

    @Test("formatPackets UInt64 uses thousands separator")
    func formatPacketsUInt64UsesThousandsSeparator() {
        let result = SettingsFormatter.formatPackets(UInt64(1_234_567))
        let expected = NumberFormatter.localizedDecimal(1_234_567)
        #expect(result == expected)
    }

    @Test("formatPackets small value without separator")
    func formatPacketsSmallValue() {
        let result = SettingsFormatter.formatPackets(Int64(42))
        #expect(result == "42")
    }

    // MARK: - formatBandwidth Tests

    @Test("formatBandwidth returns nil for zero Int64")
    func formatBandwidthReturnsNilForZeroInt64() {
        #expect(SettingsFormatter.formatBandwidth(Int64(0)) == nil)
    }

    @Test("formatBandwidth returns nil for nil Int64")
    func formatBandwidthReturnsNilForNilInt64() {
        let value: Int64? = nil
        #expect(SettingsFormatter.formatBandwidth(value) == nil)
    }

    @Test("formatBandwidth returns nil for zero Int32")
    func formatBandwidthReturnsNilForZeroInt32() {
        #expect(SettingsFormatter.formatBandwidth(Int32(0)) == nil)
    }

    @Test("formatBandwidth formats kbps correctly")
    func formatBandwidthKbps() {
        let result = SettingsFormatter.formatBandwidth(Int64(5000))
        #expect(result == "5.0 kbps")
    }

    @Test("formatBandwidth formats Mbps correctly")
    func formatBandwidthMbps() {
        let result = SettingsFormatter.formatBandwidth(Int64(2_500_000))
        #expect(result == "2.5 Mbps")
    }

    @Test("formatBandwidth formats bps for small values")
    func formatBandwidthBps() {
        let result = SettingsFormatter.formatBandwidth(Int64(500))
        #expect(result == "500.0 bps")
    }

    // MARK: - formatFrameRate Tests

    @Test("formatFrameRate formats correctly")
    func formatFrameRate() {
        #expect(SettingsFormatter.formatFrameRate(30.0) == "30 fps")
    }

    // MARK: - formatResolution Tests

    @Test("formatResolution formats width x height")
    func formatResolution() {
        #expect(SettingsFormatter.formatResolution(width: 1280, height: 720) == "1280×720")
    }

    // MARK: - sortedByResolution Tests

    @Test("sortedByResolution sorts layers ascending by pixel count")
    func sortedByResolutionAscending() {
        let layers = [
            VideoLayerStats(width: 1280, height: 720),
            VideoLayerStats(width: 320, height: 180),
            VideoLayerStats(width: 640, height: 360),
        ]
        let sorted = SettingsFormatter.sortedByResolution(layers)
        #expect(sorted[0].width == 320)
        #expect(sorted[1].width == 640)
        #expect(sorted[2].width == 1280)
    }

    @Test("sortedByResolution handles empty array")
    func sortedByResolutionEmpty() {
        let sorted = SettingsFormatter.sortedByResolution([])
        #expect(sorted.isEmpty)
    }

    @Test("sortedByResolution handles single layer")
    func sortedByResolutionSingle() {
        let layers = [VideoLayerStats(width: 1920, height: 1080)]
        let sorted = SettingsFormatter.sortedByResolution(layers)
        #expect(sorted.count == 1)
        #expect(sorted[0].width == 1920)
    }

    @Test("sortedByResolution preserves order when already sorted")
    func sortedByResolutionAlreadySorted() {
        let layers = [
            VideoLayerStats(width: 320, height: 180),
            VideoLayerStats(width: 640, height: 360),
            VideoLayerStats(width: 1280, height: 720),
        ]
        let sorted = SettingsFormatter.sortedByResolution(layers)
        #expect(sorted[0].width == 320)
        #expect(sorted[1].width == 640)
        #expect(sorted[2].width == 1280)
    }

    // MARK: - qualityLabel Tests

    @Test("qualityLabel with 2 layers returns Low and High")
    func qualityLabelTwoLayers() {
        #expect(SettingsFormatter.qualityLabel(index: 0, count: 2) == "Low Quality")
        #expect(SettingsFormatter.qualityLabel(index: 1, count: 2) == "High Quality")
    }

    @Test("qualityLabel with 3 layers returns Low, Medium, High")
    func qualityLabelThreeLayers() {
        #expect(SettingsFormatter.qualityLabel(index: 0, count: 3) == "Low Quality")
        #expect(SettingsFormatter.qualityLabel(index: 1, count: 3) == "Medium Quality")
        #expect(SettingsFormatter.qualityLabel(index: 2, count: 3) == "High Quality")
    }

    @Test("qualityLabel with 4 layers returns Low, Medium, Medium, High")
    func qualityLabelFourLayers() {
        #expect(SettingsFormatter.qualityLabel(index: 0, count: 4) == "Low Quality")
        #expect(SettingsFormatter.qualityLabel(index: 1, count: 4) == "Medium Quality")
        #expect(SettingsFormatter.qualityLabel(index: 2, count: 4) == "Medium Quality")
        #expect(SettingsFormatter.qualityLabel(index: 3, count: 4) == "High Quality")
    }

    // MARK: - formatNetworkCondition Tests

    @Test("formatNetworkCondition returns localized strings for all cases")
    func formatNetworkConditionAllCases() {
        #expect(SettingsFormatter.formatNetworkCondition(.unknown) == "Unknown")
        #expect(SettingsFormatter.formatNetworkCondition(.critical) == "Critical")
        #expect(SettingsFormatter.formatNetworkCondition(.warning) == "Warning")
        #expect(SettingsFormatter.formatNetworkCondition(.fair) == "Fair")
        #expect(SettingsFormatter.formatNetworkCondition(.good) == "Good")
        #expect(SettingsFormatter.formatNetworkCondition(.excellent) == "Excellent")
    }

    // MARK: - formatQualityLimitation Tests

    @Test("formatQualityLimitation returns localized strings for all cases")
    func formatQualityLimitationAllCases() {
        #expect(SettingsFormatter.formatQualityLimitation(.none) == "None")
        #expect(SettingsFormatter.formatQualityLimitation(.bandwidth) == "Bandwidth")
        #expect(SettingsFormatter.formatQualityLimitation(.cpu) == "CPU")
        #expect(SettingsFormatter.formatQualityLimitation(.codec) == "Codec")
        #expect(SettingsFormatter.formatQualityLimitation(.resolution) == "Resolution")
        #expect(SettingsFormatter.formatQualityLimitation(.layerChange) == "Layer Change")
    }

    // MARK: - formatDegradationSource Tests

    @Test("formatDegradationSource returns localized strings for all cases")
    func formatDegradationSourceAllCases() {
        #expect(SettingsFormatter.formatDegradationSource(.local) == "Local")
        #expect(SettingsFormatter.formatDegradationSource(.remote) == "Remote")
        #expect(SettingsFormatter.formatDegradationSource(.bothOrUnclear) == "Both or Unclear")
        #expect(SettingsFormatter.formatDegradationSource(.unknown) == "Unknown")
    }
}

extension NumberFormatter {
    fileprivate static func localizedDecimal(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
