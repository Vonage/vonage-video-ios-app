//
//  Created by Vonage on 21/7/25.
//

import AVFoundation
import Foundation

public protocol RequestCameraPermissionUseCase : RequestPermissionUseCase {}

public final class DefaultRequestCameraPermissionUseCase: RequestCameraPermissionUseCase {

    public init() {}

    public func callAsFunction() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
