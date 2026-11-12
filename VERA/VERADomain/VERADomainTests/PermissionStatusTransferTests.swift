//
//  Created by Vonage on 14/10/2026.
//

import AVFoundation
import Testing

@testable import VERADomain

@Suite("Permission status value transfer")
struct PermissionStatusTransferTests {

    @Test("All permission states preserve their authorization and denial flags across tasks")
    func statusesAcrossTasks() async {
        let statuses: [PermissionStatus] = [.notDetermined, .restricted, .denied, .authorized]
        let received = await Task.detached { statuses }.value
        #expect(received == statuses)
        #expect(received.map(\.isAuthorized) == [false, false, false, true])
        #expect(received.map(\.isDenied) == [false, false, true, false])
    }

    @Test("AVFoundation statuses retain their existing domain mapping after transfer")
    func systemStatusMapping() async {
        let mappings: [(AVAuthorizationStatus, PermissionStatus)] = [
            (.notDetermined, .notDetermined),
            (.restricted, .restricted),
            (.denied, .denied),
            (.authorized, .authorized),
        ]
        for (systemStatus, expected) in mappings {
            let status = systemStatus.permissionStatus
            let received = await Task.detached { status }.value
            #expect(received == expected)
        }
    }
}
