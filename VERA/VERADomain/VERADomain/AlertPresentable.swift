//
//  Created by Vonage on 12/5/26.
//

import Foundation

/// Protocol for presenting alerts to the user.
///
/// Implementations handle the actual UI presentation mechanism
/// (e.g. UIKit `UIAlertController`, SwiftUI `.alert`, etc.).
/// This keeps alert presentation decoupled from view models and
/// business logic, following the dependency rule.
@MainActor
public protocol AlertPresentable: AnyObject {
    func presentAlert(_ alertItem: AlertItem)
}
