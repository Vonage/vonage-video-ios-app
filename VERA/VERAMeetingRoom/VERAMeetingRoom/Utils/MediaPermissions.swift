//
//  Created by Vonage on 14/05/2026.
//

import Foundation
import VERADomain

public class MediaPermissions {
    public static func requestPermissionsIfNeeded() async {
        let micStatus = DefaultCheckMicrophoneAuthorizationStatusUseCase()()
        if !micStatus.isAuthorized && !micStatus.isDenied {
            _ = await DefaultRequestMicrophonePermissionUseCase()()
        }

        let cameraStatus = DefaultCheckCameraAuthorizationStatusUseCase()()
        if !cameraStatus.isAuthorized && !cameraStatus.isDenied {
            _ = await DefaultRequestCameraPermissionUseCase()()
        }
    }
}
