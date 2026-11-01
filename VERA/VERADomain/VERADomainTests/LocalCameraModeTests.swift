//
//  Created by Vonage on 1/11/26.
//

import Testing
import VERADomain

@Suite("Local camera mode")
struct LocalCameraModeTests {
    @Test("Flip switches the front and rear cameras in one step")
    func flipSwitchesFrontAndRear() {
        #expect(LocalCameraMode.front.flipped() == .back)
        #expect(LocalCameraMode.back.flipped() == .front)
        #expect(LocalCameraMode.dual.flipped() == .front)
    }

    @Test("Hiding the front camera leaves the rear camera, and showing it returns to dual capture")
    func frontWindowToggle() {
        #expect(LocalCameraMode.dual.hidingFrontCamera(true) == .back)
        #expect(LocalCameraMode.back.hidingFrontCamera(false) == .dual)
        #expect(LocalCameraMode.front.hidingFrontCamera(true) == .front)
        #expect(LocalCameraMode.back.hidingFrontCamera(true) == .back)
    }

    @Test("Dual capture and the rear camera are the room you are showing")
    func showingTheRoom() {
        #expect(LocalCameraMode.front.isShowingTheRoom == false)
        #expect(LocalCameraMode.dual.isShowingTheRoom == true)
        #expect(LocalCameraMode.back.isShowingTheRoom == true)
    }
}
