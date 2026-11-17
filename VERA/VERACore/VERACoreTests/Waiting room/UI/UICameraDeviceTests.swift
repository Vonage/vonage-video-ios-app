//
//  Created by Vonage on 19/10/26.
//

import Foundation
import Testing

@testable import VERACore

@MainActor
@Suite("Camera selection ownership")
struct UICameraDeviceTests {
    @Test("A camera selection can cross a task boundary and invoke its UI-owned action")
    func transferredSelectionInvokesActionOnMainActor() async {
        let selection = SelectionRecorder()
        var device = UICameraDevice(id: "back", name: "Back camera", iconName: "iphone.rear.camera")
        device.onTap = { [id = device.id] in
            MainActor.assertIsolated()
            selection.ids.append(id)
        }
        let transferredDevice = device

        let metadata = await Task.detached {
            await transferredDevice.onTap?()
            return [transferredDevice.id, transferredDevice.name, transferredDevice.iconName]
        }.value

        #expect(metadata == ["back", "Back camera", "iphone.rear.camera"])
        #expect(selection.ids == ["back"])
    }

    @MainActor
    private final class SelectionRecorder {
        var ids: [String] = []
    }
}
