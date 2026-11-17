//
//  Created by Vonage on 27/10/26.
//

import SwiftUI
import Testing
import UIKit
import VERAArchiving

@testable import VERAMeetingRoomSDK

@Suite("TranscriptionOptionsOverlayModifier tests")
@MainActor
struct TranscriptionOptionsOverlayModifierTests {

    @Test("Without a transcription button the sheet is never presented")
    func noViewModelDoesNotPresentSheet() async {
        let (root, window) = host(viewModel: nil)

        try? await Task.sleep(for: .milliseconds(100))
        window.layoutIfNeeded()

        #expect(root.presentedViewController == nil)
    }

    @Test("Sheet is not presented while the start options are hidden")
    func hiddenOptionsDoNotPresentSheet() async {
        let viewModel = makeTranscriptionViewModel()
        let (root, window) = host(viewModel: viewModel)

        try? await Task.sleep(for: .milliseconds(100))
        window.layoutIfNeeded()

        #expect(root.presentedViewController == nil)
    }

    @Test("Sheet is presented when the start options are shown")
    func shownOptionsPresentSheet() async {
        let viewModel = makeTranscriptionViewModel()
        viewModel.isShowingTranscriptionOptions = true
        let (root, window) = host(viewModel: viewModel)

        // Presentation is asynchronous; give it a short runloop slice.
        try? await Task.sleep(for: .milliseconds(250))
        window.layoutIfNeeded()

        #expect(root.presentedViewController != nil)
    }

    // MARK: - Helpers

    private func makeTranscriptionViewModel() -> ArchiveButtonViewModel {
        let container = MeetingRoomSDKContainer(
            baseURL: URL(string: "https://api.example.com")!,
            enabledFeatures: [.postCallTranscription]
        )
        return container.archivingFactory.makeArchivingButton(kind: .transcription) { _ in }.viewModel
    }

    private func host(viewModel: ArchiveButtonViewModel?) -> (UIViewController, UIWindow) {
        let rootView = Color.clear.modifier(TranscriptionOptionsOverlayModifier(viewModel: viewModel))
        let hosting = UIHostingController(rootView: rootView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.rootViewController = hosting
        window.makeKeyAndVisible()
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        return (hosting, window)
    }
}
