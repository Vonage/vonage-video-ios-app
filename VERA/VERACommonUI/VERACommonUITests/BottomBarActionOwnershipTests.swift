//
//  Created by Vonage on 19/10/26.
//

import SwiftUI
import Testing

@testable import VERACommonUI

@MainActor
@Suite("Bottom bar action ownership")
struct BottomBarActionOwnershipTests {
    @Test("A bottom bar action item invokes its UI-owned action after task transfer")
    func transferredItemPerformsActionOnMainActor() async {
        let recorder = ActionRecorder()
        let item = BottomBarActionItem(
            label: "Support",
            image: Image(systemName: "questionmark.circle")
        ) {
            MainActor.assertIsolated()
            recorder.actionCount += 1
        }

        await Task.detached {
            await item.performAction()
        }.value

        #expect(recorder.actionCount == 1)
    }

    @Test("Overflow header construction stays lazy and executes on MainActor")
    func overflowHeaderBuildsOnlyWhenRequested() async {
        let recorder = ActionRecorder()
        let item = BottomBarActionItem(
            label: "Support",
            image: Image(systemName: "questionmark.circle"),
            overflowPresentation: .headerContent {
                MainActor.assertIsolated()
                recorder.headerBuildCount += 1
                return AnyView(Text("Support"))
            }
        ) {}
        #expect(recorder.headerBuildCount == 0)

        await Task.detached {
            await MainActor.run {
                if case .headerContent(let content) = item.overflowPresentation {
                    _ = content()
                } else {
                    Issue.record("Expected an overflow header")
                }
            }
        }.value

        #expect(recorder.headerBuildCount == 1)
    }

    @MainActor
    private final class ActionRecorder {
        var actionCount = 0
        var headerBuildCount = 0
    }
}
