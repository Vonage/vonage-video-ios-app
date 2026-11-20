//
//  Created by Vonage on 19/11/26.
//

import CoreGraphics
import Testing

@testable import VERAScreenShare

@Suite("Screen share availability")
struct ScreenShareAvailabilityTests {
    @Test("Screen share stays available for an iOS app")
    func availableForIOSApp() {
        #expect(
            ScreenShareAvailability.isFeatureAvailable(
                usesSystemContentPicker: false,
                isiOSAppOnMac: false))
    }

    @Test("An iOS app on Mac shares only through the system picker")
    func iosAppOnMacRequiresSystemPicker() {
        #expect(
            ScreenShareAvailability.isFeatureAvailable(
                usesSystemContentPicker: false,
                isiOSAppOnMac: true) == false)
        #expect(
            ScreenShareAvailability.isFeatureAvailable(
                usesSystemContentPicker: true,
                isiOSAppOnMac: true))
    }

    @Test("The capture factory follows system picker availability")
    func factoryFollowsSystemPickerAvailability() {
        let made = ScreenCaptureControllerFactory.make() != nil
        #expect(made == ScreenShareAvailability.usesSystemContentPicker)
    }
}

@Suite("Screen share frame size")
struct ScreenShareFrameSizeTests {
    @Test("The content pixel size is kept and both edges align to 16")
    func keepsContentSizeAndAligns() {
        // 1080 is 8 past a multiple of 16, so that edge rounds up to 1088.
        let landscape = ScreenShareFrameSize.outputSize(inputWidth: 1920, inputHeight: 1080)
        #expect(landscape.width == 1920)
        #expect(landscape.height == 1088)

        let portrait = ScreenShareFrameSize.outputSize(inputWidth: 1080, inputHeight: 1920)
        #expect(portrait.width == 1088)
        #expect(portrait.height == 1920)

        let small = ScreenShareFrameSize.outputSize(inputWidth: 100, inputHeight: 100)
        #expect(small.width == 112)
        #expect(small.height == 112)

        let aligned = ScreenShareFrameSize.outputSize(inputWidth: 1280, inputHeight: 720)
        #expect(aligned.width == 1280)
        #expect(aligned.height == 720)
    }

    @Test("A zero content rect falls back to 1280x720")
    func zeroContentUsesFallback() {
        let size = ScreenShareFrameSize.outputSize(contentRect: .zero, pointPixelScale: 2)
        #expect(size.width == 1280)
        #expect(size.height == 720)
    }

    @Test("Content rect points are scaled to pixels")
    func contentRectScalesToPixels() {
        let size = ScreenShareFrameSize.outputSize(
            contentRect: CGRect(x: 0, y: 0, width: 960, height: 540),
            pointPixelScale: 2)
        #expect(size.width == 1920)
        #expect(size.height == 1088)
    }
}
