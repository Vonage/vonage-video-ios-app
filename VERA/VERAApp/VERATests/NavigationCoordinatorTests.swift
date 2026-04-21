//
//  Created by Vonage on 21/04/2026.
//

import Foundation
import Testing
import VERADomain

@testable import VERA

@MainActor
@Suite("NavigationCoordinator tests")
struct NavigationCoordinatorTests {

    // MARK: - Initial State

    @Test("Initial path is empty")
    func initialPathIsEmpty() {
        let sut = makeSUT()
        #expect(sut.path.count == 0)
    }

    @Test("Initial isInMeeting is false")
    func initialIsInMeetingIsFalse() {
        let sut = makeSUT()
        #expect(!sut.isInMeeting)
    }

    @Test("Initial alertItem is nil")
    func initialAlertItemIsNil() {
        let sut = makeSUT()
        #expect(sut.alertItem == nil)
    }

    @Test("Initial currentMeetingRoom is nil")
    func initialCurrentMeetingRoomIsNil() {
        let sut = makeSUT()
        #expect(sut.currentMeetingRoom == nil)
    }

    // MARK: - go(to: .waitingRoom)

    @Test("go to waitingRoom sets path to one route")
    func goToWaitingRoomSetsPath() {
        let sut = makeSUT()
        sut.go(to: .waitingRoom("test-room"))
        #expect(sut.path.count == 1)
    }

    @Test("go to waitingRoom clears isInMeeting")
    func goToWaitingRoomClearsIsInMeeting() {
        let sut = makeSUT()
        sut.isInMeeting = true
        sut.go(to: .waitingRoom("test-room"))
        #expect(!sut.isInMeeting)
    }

    @Test("go to waitingRoom clears currentMeetingRoom")
    func goToWaitingRoomClearsCurrentMeetingRoom() {
        let sut = makeSUT()
        sut.currentMeetingRoom = "previous-room"
        sut.go(to: .waitingRoom("test-room"))
        #expect(sut.currentMeetingRoom == nil)
    }

    @Test("go to waitingRoom replaces existing path entries")
    func goToWaitingRoomReplacesExistingPath() {
        let sut = makeSUT()
        sut.go(to: .waitingRoom("first-room"))
        sut.go(to: .waitingRoom("second-room"))
        #expect(sut.path.count == 1)
    }

    // MARK: - go(to: .meetingRoom)

    @Test("go to meetingRoom sets isInMeeting to true")
    func goToMeetingRoomSetsIsInMeeting() {
        let sut = makeSUT()
        sut.go(to: .meetingRoom("test-room"))
        #expect(sut.isInMeeting)
    }

    @Test("go to meetingRoom sets currentMeetingRoom to the given room name")
    func goToMeetingRoomSetsCurrentMeetingRoom() {
        let sut = makeSUT()
        sut.go(to: .meetingRoom("my-room"))
        #expect(sut.currentMeetingRoom == "my-room")
    }

    @Test("go to meetingRoom sets path to one route")
    func goToMeetingRoomSetsPath() {
        let sut = makeSUT()
        sut.go(to: .meetingRoom("my-room"))
        #expect(sut.path.count == 1)
    }

    @Test("go to meetingRoom with a different room updates currentMeetingRoom")
    func goToMeetingRoomUpdatesMeetingRoom() {
        let sut = makeSUT()
        sut.go(to: .meetingRoom("first-room"))
        sut.go(to: .meetingRoom("second-room"))
        #expect(sut.currentMeetingRoom == "second-room")
    }

    // MARK: - go(to: .goodbye)

    @Test("go to goodbye clears isInMeeting")
    func goToGoodbyeClearsIsInMeeting() {
        let sut = makeSUT()
        sut.isInMeeting = true
        sut.go(to: .goodbye("test-room"))
        #expect(!sut.isInMeeting)
    }

    @Test("go to goodbye clears currentMeetingRoom")
    func goToGoodbyeClearsCurrentMeetingRoom() {
        let sut = makeSUT()
        sut.currentMeetingRoom = "test-room"
        sut.go(to: .goodbye("test-room"))
        #expect(sut.currentMeetingRoom == nil)
    }

    @Test("go to goodbye does not modify the navigation path")
    func goToGoodbyeDoesNotModifyPath() {
        let sut = makeSUT()
        sut.go(to: .meetingRoom("room"))
        let pathCountBeforeGoodbye = sut.path.count
        sut.go(to: .goodbye("room"))
        #expect(sut.path.count == pathCountBeforeGoodbye)
    }

    // MARK: - go(to: .landing)

    @Test("go to landing clears the navigation path")
    func goToLandingClearsPath() {
        let sut = makeSUT()
        sut.go(to: .waitingRoom("room"))
        sut.go(to: .landing)
        #expect(sut.path.count == 0)
    }

    @Test("go to landing clears isInMeeting")
    func goToLandingClearsIsInMeeting() {
        let sut = makeSUT()
        sut.isInMeeting = true
        sut.go(to: .landing)
        #expect(!sut.isInMeeting)
    }

    @Test("go to landing clears currentMeetingRoom")
    func goToLandingClearsCurrentMeetingRoom() {
        let sut = makeSUT()
        sut.currentMeetingRoom = "some-room"
        sut.go(to: .landing)
        #expect(sut.currentMeetingRoom == nil)
    }

    @Test("go to landing clears waitingRoomViewModel")
    func goToLandingClearsWaitingRoomViewModel() {
        let sut = makeSUT()
        sut.go(to: .landing)
        #expect(sut.waitingRoomViewModel == nil)
    }

    @Test("go to landing from deep navigation still clears path")
    func goToLandingFromDeepNavigationClearsPath() {
        let sut = makeSUT()
        sut.go(to: .waitingRoom("room"))
        sut.go(to: .landing)
        sut.go(to: .waitingRoom("room-2"))
        sut.go(to: .landing)
        #expect(sut.path.count == 0)
    }

    // MARK: - showAlert

    @Test("showAlert sets alertItem title")
    func showAlertSetsAlertItemTitle() {
        let sut = makeSUT()
        sut.showAlert(AlertItem(title: "Test Title", message: "Test Message"))
        #expect(sut.alertItem?.title == "Test Title")
    }

    @Test("showAlert sets alertItem message")
    func showAlertSetsAlertItemMessage() {
        let sut = makeSUT()
        sut.showAlert(AlertItem(title: "Test Title", message: "Test Message"))
        #expect(sut.alertItem?.message == "Test Message")
    }

    @Test("showAlert replaces a previously set alertItem")
    func showAlertReplacesPreviousAlertItem() {
        let sut = makeSUT()
        sut.showAlert(AlertItem(title: "First", message: "First message"))
        sut.showAlert(AlertItem(title: "Second", message: "Second message"))
        #expect(sut.alertItem?.title == "Second")
        #expect(sut.alertItem?.message == "Second message")
    }

    // MARK: - Combined State Transitions

    @Test("navigating to waitingRoom then landing results in empty path and no meeting")
    func waitingRoomThenLandingClearsState() {
        let sut = makeSUT()
        sut.go(to: .waitingRoom("room"))
        sut.go(to: .landing)
        #expect(sut.path.count == 0)
        #expect(!sut.isInMeeting)
        #expect(sut.currentMeetingRoom == nil)
    }

    @Test("navigating to meetingRoom then goodbye clears meeting state but preserves path")
    func meetingRoomThenGoodbyePreservesMeetingPath() {
        let sut = makeSUT()
        sut.go(to: .meetingRoom("room"))
        let pathCount = sut.path.count
        sut.go(to: .goodbye("room"))
        #expect(!sut.isInMeeting)
        #expect(sut.currentMeetingRoom == nil)
        #expect(sut.path.count == pathCount)
    }

    // MARK: - SUT Factory

    private func makeSUT() -> NavigationCoordinator {
        NavigationCoordinator()
    }
}
