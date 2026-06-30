//
//  Created by Vonage on 29/6/26.
//

#if DEBUG
    import Combine
    import Testing
    import VERAMeetingRoom

    @testable import VERA

    @MainActor
    @Suite("QA meeting room UI provider tests")
    struct QAMeetingRoomUIProviderTests {

        @Test("Initial bottom bar buttons is empty")
        func initialBottomBarButtonsIsEmpty() {
            let sut = QAMeetingRoomUIProvider()

            #expect(sut.bottomBarButtons().isEmpty)
        }

        @Test("Add button appends button and emits update")
        func addButtonAppendsButtonAndEmitsUpdate() {
            let sut = QAMeetingRoomUIProvider()
            var updateCount = 0
            let cancellable = sut.updates.sink {
                updateCount += 1
            }

            sut.addButton()

            #expect(sut.bottomBarButtons().map(\.label) == ["QA 1"])
            #expect(updateCount == 1)
            cancellable.cancel()
        }

        @Test("Remove last button removes latest button and emits update")
        func removeLastButtonRemovesLatestButtonAndEmitsUpdate() {
            let sut = QAMeetingRoomUIProvider()
            sut.addButton()
            sut.addButton()
            var updateCount = 0
            let cancellable = sut.updates.sink {
                updateCount += 1
            }

            sut.removeLastButton()

            #expect(sut.bottomBarButtons().map(\.label) == ["QA 1"])
            #expect(updateCount == 1)
            cancellable.cancel()
        }

        @Test("Clear buttons removes all buttons and emits update")
        func clearButtonsRemovesAllButtonsAndEmitsUpdate() {
            let sut = QAMeetingRoomUIProvider()
            sut.addButton()
            sut.addButton()
            var updateCount = 0
            let cancellable = sut.updates.sink {
                updateCount += 1
            }

            sut.clearButtons()

            #expect(sut.bottomBarButtons().isEmpty)
            #expect(updateCount == 1)
            cancellable.cancel()
        }

        @Test("Generated button action toggles active state and emits update")
        func generatedButtonActionTogglesActiveStateAndEmitsUpdate() async {
            let sut = QAMeetingRoomUIProvider()
            sut.addButton()
            var updateCount = 0
            let cancellable = sut.updates.sink {
                updateCount += 1
            }

            let button = sut.bottomBarButtons()[0]
            #expect(!button.isActive)
            button.action()
            await Task.yield()

            let updatedButton = sut.bottomBarButtons()[0]
            #expect(updatedButton.isActive)
            #expect(updateCount == 1)
            cancellable.cancel()
        }
    }
#endif
