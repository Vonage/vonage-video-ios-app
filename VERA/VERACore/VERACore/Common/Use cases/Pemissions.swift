//
//  Created by Vonage on 30/01/2026.
//

public protocol RequestPermissionUseCase {
    func callAsFunction() async -> Bool
}

public protocol CheckPermissionUseCase {
    func callAsFunction() -> Bool
}


