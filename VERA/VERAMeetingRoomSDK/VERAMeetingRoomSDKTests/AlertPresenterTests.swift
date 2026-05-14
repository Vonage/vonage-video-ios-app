//
//  Created by Vonage on 12/5/26.
//

import Foundation
import Testing
import VERADomain

@testable import VERAMeetingRoomSDK

@Suite("AlertPresenter tests")
struct AlertPresenterTests {

    @Test("present delegates to AlertPresentable implementation")
    @MainActor
    func presentDelegatesToPresentable() {
        let spy = AlertPresentableSpy()
        let sut = AlertPresenter(presenter: spy)
        let alertItem = AlertItem(title: "Title", message: "Message")

        sut.present(alertItem)

        #expect(spy.presentedAlerts.count == 1)
        #expect(spy.presentedAlerts.first?.title == "Title")
        #expect(spy.presentedAlerts.first?.message == "Message")
    }

    @Test("present forwards multiple alerts")
    @MainActor
    func presentForwardsMultipleAlerts() {
        let spy = AlertPresentableSpy()
        let sut = AlertPresenter(presenter: spy)

        sut.present(AlertItem(title: "First", message: "A"))
        sut.present(AlertItem(title: "Second", message: "B"))

        #expect(spy.presentedAlerts.count == 2)
        #expect(spy.presentedAlerts[0].title == "First")
        #expect(spy.presentedAlerts[1].title == "Second")
    }

    @Test("reset prevents subsequent alerts from being presented")
    @MainActor
    func resetStopsPresentingAlerts() {
        let spy = AlertPresentableSpy()
        let sut = AlertPresenter(presenter: spy)

        sut.present(AlertItem(title: "Before", message: "Reset"))
        #expect(spy.presentedAlerts.count == 1)

        sut.reset()
        sut.present(AlertItem(title: "After", message: "Reset"))

        #expect(spy.presentedAlerts.count == 1)
    }
}

// MARK: - Test Doubles

@MainActor
private final class AlertPresentableSpy: AlertPresentable {
    var presentedAlerts: [AlertItem] = []

    func presentAlert(_ alertItem: AlertItem) {
        presentedAlerts.append(alertItem)
    }
}
