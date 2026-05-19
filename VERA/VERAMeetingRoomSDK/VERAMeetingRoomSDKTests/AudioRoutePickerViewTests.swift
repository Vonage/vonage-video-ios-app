//
//  Created by Vonage on 21/04/2026.
//

import AVKit
import Foundation
import SwiftUI
import Testing
import UIKit

@testable import VERAMeetingRoomSDK

@Suite("AudioRoutePickerView tests")
struct AudioRoutePickerViewTests {

    @Test("AudioRoutePickerView can be initialized without arguments")
    func initializesWithoutArguments() {
        let sut = AudioRoutePickerView()
        _ = sut
    }

    @Test("makeUIView creates a container that includes an AVRoutePickerView subview")
    @MainActor
    func makeUIViewContainsAVRoutePickerView() {
        let hostingController = makeHostingController()
        let allViews = hostingController.view.flattenedSubviews()
        #expect(allViews.contains { $0 is AVRoutePickerView })
    }

    @Test("makeUIView creates a container that includes a UIButton overlay")
    @MainActor
    func makeUIViewContainsUIButton() {
        let hostingController = makeHostingController()
        let allViews = hostingController.view.flattenedSubviews()
        #expect(allViews.contains { $0 is UIButton })
    }

    @Test("AVRoutePickerView does not prioritize video devices")
    @MainActor
    func avRoutePickerViewDoesNotPrioritizeVideoDevices() {
        let hostingController = makeHostingController()
        let routePicker = hostingController.view.flattenedSubviews()
            .compactMap { $0 as? AVRoutePickerView }
            .first
        #expect(routePicker != nil)
        #expect(routePicker?.prioritizesVideoDevices == false)
    }

    @Test("AVRoutePickerView has clear tint color")
    @MainActor
    func avRoutePickerViewHasClearTintColor() {
        let hostingController = makeHostingController()
        let routePicker = hostingController.view.flattenedSubviews()
            .compactMap { $0 as? AVRoutePickerView }
            .first
        #expect(routePicker?.tintColor == .clear)
    }

    @Test("AVRoutePickerView has clear active tint color")
    @MainActor
    func avRoutePickerViewHasClearActiveTintColor() {
        let hostingController = makeHostingController()
        let routePicker = hostingController.view.flattenedSubviews()
            .compactMap { $0 as? AVRoutePickerView }
            .first
        #expect(routePicker?.activeTintColor == .clear)
    }

    @Test("updateUIView does not crash")
    @MainActor
    func updateUIViewDoesNotCrash() {
        // updateUIView is a no-op; verifying no crash occurs when the view updates
        let hostingController = makeHostingController()
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
    }

    // MARK: - Helpers

    @MainActor
    private func makeHostingController() -> UIHostingController<AudioRoutePickerView> {
        let hostingController = UIHostingController(rootView: AudioRoutePickerView())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.rootViewController = hostingController
        window.isHidden = false
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        return hostingController
    }
}

extension UIView {
    fileprivate func flattenedSubviews() -> [UIView] {
        var result: [UIView] = []
        for subview in subviews {
            result.append(subview)
            result.append(contentsOf: subview.flattenedSubviews())
        }
        return result
    }
}
