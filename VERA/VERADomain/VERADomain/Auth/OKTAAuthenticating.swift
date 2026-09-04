//
//  Created by Vonage on 12/8/26.
//

import Combine
import Foundation

#if canImport(UIKit)
    import UIKit
    public typealias ASPresentationAnchor = UIWindow
#elseif canImport(AppKit)
    public typealias ASPresentationAnchor = Any
#endif

public protocol OKTAAuthenticating: AuthStateDataSource {
    @MainActor func signIn(from anchor: ASPresentationAnchor) async throws
    func signOut() async throws
    func currentToken() async throws -> String
}
