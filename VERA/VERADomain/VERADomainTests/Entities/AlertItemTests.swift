//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERADomain

@Suite("AlertItem tests")
struct AlertItemTests {

    @Test("AlertItem simple init sets title and message")
    func simpleInit() {
        let alert = AlertItem(title: "Error", message: "Something went wrong")

        #expect(alert.title == "Error")
        #expect(alert.message == "Something went wrong")
        #expect(alert.okAction == "OK")
        #expect(alert.cancelAction == nil)
    }

    @Test("AlertItem full init sets all properties")
    func fullInit() {
        let alert = AlertItem(
            title: "Confirm",
            message: "Are you sure?",
            okAction: "Yes",
            cancelAction: "No")

        #expect(alert.title == "Confirm")
        #expect(alert.message == "Are you sure?")
        #expect(alert.okAction == "Yes")
        #expect(alert.cancelAction == "No")
    }

    @Test("Camera permission alert has correct text")
    func cameraPermissionAlert() {
        let alert = AlertItem.cameraPermissionAlert(onConfirm: {})

        #expect(alert.title == "Check Settings")
        #expect(alert.message == "Please review camera permissions in settings.")
        #expect(alert.okAction == "Go to settings")
        #expect(alert.cancelAction == "Cancel")
    }

    @Test("Microphone permission alert has correct text")
    func microphonePermissionAlert() {
        let alert = AlertItem.microphonePermissionAlert(onConfirm: {})

        #expect(alert.title == "Check Settings")
        #expect(alert.message == "Please review microphone permissions in settings.")
        #expect(alert.okAction == "Go to settings")
        #expect(alert.cancelAction == "Cancel")
    }

    @Test("Generic error alert has correct structure")
    func genericErrorAlert() {
        let alert = AlertItem.genericError("Network failure")

        #expect(alert.title == "Error")
        #expect(alert.message == "Network failure")
        #expect(alert.okAction == "OK")
        #expect(alert.cancelAction == nil)
    }

    @Test("Room credentials error alert includes error message")
    func roomCredentialsErrorAlert() {
        let alert = AlertItem.roomCredentialsError("Timeout")

        #expect(alert.title == "Connection Error")
        #expect(alert.message == "Failed to get room credentials: Timeout")
    }

    @Test("Goodbye error alert includes error message")
    func goodbyeErrorAlert() {
        let alert = AlertItem.goodbyeError("Server error")

        #expect(alert.title == "Error")
        #expect(alert.message == "Failed to get room archives: Server error")
    }

    @Test("Download error alert includes error message")
    func downloadErrorAlert() {
        let alert = AlertItem.downloadError("File not found")

        #expect(alert.title == "Error")
        #expect(alert.message == "Failed to download recording: File not found")
    }

    @Test("AlertItem equality is based on id, title and message")
    func alertEquality() {
        let alert1 = AlertItem(title: "A", message: "B")
        let alert2 = AlertItem(title: "A", message: "B")

        // Different ids should make them not equal
        #expect(alert1 != alert2)
    }

    @Test("AlertItem equality with same instance")
    func alertEqualitySameInstance() {
        let alert = AlertItem(title: "A", message: "B")

        #expect(alert == alert)
    }
}
