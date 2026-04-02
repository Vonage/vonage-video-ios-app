//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERADomain

@Suite("ToastItem tests")
struct ToastItemTests {

    @Test("ToastItem stores properties correctly")
    func toastItemProperties() {
        let toast = ToastItem(message: "Connected", mode: .success)

        #expect(toast.message == "Connected")
        #expect(toast.mode == .success)
    }

    @Test(
        "ToastItem can be created with all modes",
        arguments: [
            ToastMode.warning,
            ToastMode.info,
            ToastMode.failure,
            ToastMode.success,
        ])
    func toastItemAllModes(mode: ToastMode) {
        let toast = ToastItem(message: "Test", mode: mode)

        #expect(toast.mode == mode)
    }

    @Test("ToastItem equality with same properties")
    func toastItemEquality() {
        let toast1 = ToastItem(message: "Hello", mode: .info)
        let toast2 = ToastItem(message: "Hello", mode: .info)

        #expect(toast1 == toast2)
    }

    @Test("ToastItem inequality with different message")
    func toastItemInequalityByMessage() {
        let toast1 = ToastItem(message: "Hello", mode: .info)
        let toast2 = ToastItem(message: "World", mode: .info)

        #expect(toast1 != toast2)
    }

    @Test("ToastItem inequality with different mode")
    func toastItemInequalityByMode() {
        let toast1 = ToastItem(message: "Hello", mode: .info)
        let toast2 = ToastItem(message: "Hello", mode: .warning)

        #expect(toast1 != toast2)
    }
}
