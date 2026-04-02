//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERADomain

@Suite("Video enum types tests")
struct VideoEnumTests {

    // MARK: - VideoCodecType

    @Test(
        "VideoCodecType raw values are correct",
        arguments: [
            (VideoCodecType.vp8, 1),
            (VideoCodecType.h264, 2),
            (VideoCodecType.vp9, 3),
        ])
    func videoCodecTypeRawValues(codec: VideoCodecType, expected: Int) {
        #expect(codec.rawValue == expected)
    }

    @Test("VideoCodecType can be created from raw value")
    func videoCodecTypeFromRawValue() {
        #expect(VideoCodecType(rawValue: 1) == .vp8)
        #expect(VideoCodecType(rawValue: 2) == .h264)
        #expect(VideoCodecType(rawValue: 3) == .vp9)
        #expect(VideoCodecType(rawValue: 0) == nil)
        #expect(VideoCodecType(rawValue: 4) == nil)
    }

    // MARK: - VideoFrameRate

    @Test(
        "VideoFrameRate raw values are correct",
        arguments: [
            (VideoFrameRate.rate30FPS, 30),
            (VideoFrameRate.rate15FPS, 15),
            (VideoFrameRate.rate7FPS, 7),
            (VideoFrameRate.rate1FPS, 1),
        ])
    func videoFrameRateRawValues(rate: VideoFrameRate, expected: Int) {
        #expect(rate.rawValue == expected)
    }

    @Test("VideoFrameRate can be created from raw value")
    func videoFrameRateFromRawValue() {
        #expect(VideoFrameRate(rawValue: 30) == .rate30FPS)
        #expect(VideoFrameRate(rawValue: 15) == .rate15FPS)
        #expect(VideoFrameRate(rawValue: 7) == .rate7FPS)
        #expect(VideoFrameRate(rawValue: 1) == .rate1FPS)
        #expect(VideoFrameRate(rawValue: 0) == nil)
        #expect(VideoFrameRate(rawValue: 60) == nil)
    }

    // MARK: - VideoResolution

    @Test(
        "VideoResolution raw values are correct",
        arguments: [
            (VideoResolution.low, 0),
            (VideoResolution.mediun, 1),
            (VideoResolution.high, 2),
            (VideoResolution.high1080p, 3),
        ])
    func videoResolutionRawValues(resolution: VideoResolution, expected: Int) {
        #expect(resolution.rawValue == expected)
    }

    @Test("VideoResolution can be created from raw value")
    func videoResolutionFromRawValue() {
        #expect(VideoResolution(rawValue: 0) == .low)
        #expect(VideoResolution(rawValue: 1) == .mediun)
        #expect(VideoResolution(rawValue: 2) == .high)
        #expect(VideoResolution(rawValue: 3) == .high1080p)
        #expect(VideoResolution(rawValue: 4) == nil)
        #expect(VideoResolution(rawValue: -1) == nil)
    }

    // MARK: - VideoBitratePreset

    @Test(
        "VideoBitratePreset raw values are correct",
        arguments: [
            (VideoBitratePreset.default, 0),
            (VideoBitratePreset.bwSaver, 1),
            (VideoBitratePreset.extraBwSaver, 2),
            (VideoBitratePreset.customBitrate, 3),
        ])
    func videoBitratePresetRawValues(preset: VideoBitratePreset, expected: Int) {
        #expect(preset.rawValue == expected)
    }

    @Test("VideoBitratePreset can be created from raw value")
    func videoBitratePresetFromRawValue() {
        #expect(VideoBitratePreset(rawValue: 0) == .default)
        #expect(VideoBitratePreset(rawValue: 1) == .bwSaver)
        #expect(VideoBitratePreset(rawValue: 2) == .extraBwSaver)
        #expect(VideoBitratePreset(rawValue: 3) == .customBitrate)
        #expect(VideoBitratePreset(rawValue: 4) == nil)
    }

    // MARK: - VideoScaleBehavior

    @Test(
        "VideoScaleBehavior raw values are correct",
        arguments: [
            (VideoScaleBehavior.fill, "fill"),
            (VideoScaleBehavior.fit, "fit"),
        ])
    func videoScaleBehaviorRawValues(behavior: VideoScaleBehavior, expected: String) {
        #expect(behavior.rawValue == expected)
    }

    @Test("VideoScaleBehavior can be created from raw value")
    func videoScaleBehaviorFromRawValue() {
        #expect(VideoScaleBehavior(rawValue: "fill") == .fill)
        #expect(VideoScaleBehavior(rawValue: "fit") == .fit)
        #expect(VideoScaleBehavior(rawValue: "stretch") == nil)
    }
}
