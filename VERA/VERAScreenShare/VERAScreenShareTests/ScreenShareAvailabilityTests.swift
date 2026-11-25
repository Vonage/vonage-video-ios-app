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
    @Test("Content within the limit keeps its size and both edges align to 16")
    func keepsSmallContentAndAligns() {
        // 1080 is 8 past a multiple of 16, so that edge rounds up to 1088.
        let square = ScreenShareFrameSize.outputSize(inputWidth: 1080, inputHeight: 1080)
        #expect(square.width == 1088)
        #expect(square.height == 1088)

        let small = ScreenShareFrameSize.outputSize(inputWidth: 100, inputHeight: 100)
        #expect(small.width == 112)
        #expect(small.height == 112)

        let aligned = ScreenShareFrameSize.outputSize(inputWidth: 1280, inputHeight: 720)
        #expect(aligned.width == 1280)
        #expect(aligned.height == 720)
    }

    @Test("Larger content is capped at 1280 on the longest edge and keeps its aspect ratio")
    func capsLargeContent() {
        let landscape = ScreenShareFrameSize.outputSize(inputWidth: 1920, inputHeight: 1080)
        #expect(landscape.width == 1280)
        #expect(landscape.height == 720)

        // iPhone 17 Pro Max portrait: 589 rounds up to 592.
        let phone = ScreenShareFrameSize.outputSize(inputWidth: 1320, inputHeight: 2868)
        #expect(phone.width == 592)
        #expect(phone.height == 1280)

        // 13-inch iPad Pro portrait.
        let tablet = ScreenShareFrameSize.outputSize(inputWidth: 2064, inputHeight: 2752)
        #expect(tablet.width == 960)
        #expect(tablet.height == 1280)
    }

    @Test("A zero content rect falls back to 1280x720")
    func zeroContentUsesFallback() {
        let size = ScreenShareFrameSize.outputSize(contentRect: .zero, pointPixelScale: 2)
        #expect(size.width == 1280)
        #expect(size.height == 720)
    }

    @Test("Content rect points are scaled to pixels before the cap")
    func contentRectScalesToPixels() {
        let size = ScreenShareFrameSize.outputSize(
            contentRect: CGRect(x: 0, y: 0, width: 480, height: 270),
            pointPixelScale: 2)
        #expect(size.width == 960)
        #expect(size.height == 544)

        let capped = ScreenShareFrameSize.outputSize(
            contentRect: CGRect(x: 0, y: 0, width: 960, height: 540),
            pointPixelScale: 2)
        #expect(capped.width == 1280)
        #expect(capped.height == 720)
    }
}
