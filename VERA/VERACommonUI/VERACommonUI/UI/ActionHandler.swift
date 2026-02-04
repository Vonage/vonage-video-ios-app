//
//  Created by Vonage on 02/02/2026.
//

import VERADomain

/// Actions that can be dispatched for centralized handling across the app.
///
/// Use these actions to trigger UI behaviors that need to be coordinated
/// across the app, such as showing alerts, navigating between screens,
/// or other modal presentations.
///
/// ## Overview
/// `Action` provides a type-safe way to communicate user intents or system events
/// from views to a central coordinator without tight coupling.
///
/// ## Usage
/// ```swift
/// // Trigger an alert
/// actionHandler(.presentAlert(alertItem))
///
/// // Navigate to another screen
/// actionHandler(.navigateToSettings)
/// ```
///
/// ## Topics
/// ### Alerts
/// - ``presentAlert(_:)``
///
/// ### Navigation
/// - ``navigateToGoodbye``
/// - ``navigateToSettings``
/// - ``navigateToWaitingRoom``
public enum Action {
    /// Displays an alert dialog to the user.
    ///
    /// Use this action when you need to show an error, confirmation,
    /// or informational alert from any view in the app.
    ///
    /// - Parameter item: The `AlertItem` containing the alert's title, message,
    ///   and optional confirmation handler.
    ///
    /// ## Example
    /// ```swift
    /// let alert = AlertItem(
    ///     title: "Error",
    ///     message: "Something went wrong",
    ///     onConfirm: { print("User acknowledged") }
    /// )
    /// actionHandler(.presentAlert(alert))
    /// ```
    case presentAlert(_ item: AlertItem)
    
    /// Navigates the user to the goodbye screen after leaving a meeting.
    ///
    /// Typically triggered when a call ends or the user manually disconnects.
    case navigateToGoodbye
    
    /// Navigates the user to the app settings screen.
    ///
    /// Use this action to allow users to configure app preferences,
    /// audio/video settings, or account options.
    case navigateToSettings
    
    /// Navigates the user to the waiting room before joining a meeting.
    ///
    /// The waiting room allows users to configure their audio/video
    /// settings before entering the meeting.
    case navigateToWaitingRoom(_ roomName: RoomName)
}

/// A closure type that handles dispatched actions.
///
/// Use `ActionHandler` to pass action handling capability to views
/// without exposing the coordinator directly, promoting loose coupling.
///
/// ## Overview
/// Views receive an `ActionHandler` closure and call it when user interactions
/// or system events require coordination at a higher level.
///
/// ## Example
/// ```swift
/// struct MyView: View {
///     let actionHandler: ActionHandler
///
///     var body: some View {
///         Button("Show Error") {
///             actionHandler(.presentAlert(AlertItem.genericError("Oops!")))
///         }
///     }
/// }
/// ```
///
/// ## Implementation
/// Typically provided by a coordinator or parent view:
/// ```swift
/// MyView(actionHandler: { action in
///     switch action {
///     case .presentAlert(let item):
///         alertItem = item
///     case .navigateToSettings:
///         path.append(.settings)
///     // ... handle other actions
///     }
/// })
/// ```
public typealias ActionHandler = (Action) -> Void
