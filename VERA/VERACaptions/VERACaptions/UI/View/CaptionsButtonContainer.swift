//
//  Created by Vonage on 6/2/26.
//

import SwiftUI

/// A stateful container that connects a ``CaptionsButtonViewModel`` to a
/// ``CaptionsButton``.
///
/// `CaptionsButtonContainer` observes the view model's
/// ``CaptionsButtonViewModel/state`` and forwards
/// ``CaptionsButtonViewModel/onTap()`` as the button action.
///
/// > Note: The caller is responsible for calling
/// > ``CaptionsButtonViewModel/setup()`` (typically in `.onAppear` or at
/// > creation time) to start the status subscription.
///
/// ## Usage
///
/// Create via ``CaptionsFactory/makeCaptionsButton(roomName:)`` or
/// instantiate directly:
///
/// ```swift
/// CaptionsButtonContainer(viewModel: buttonViewModel)
/// ```
///
/// - SeeAlso: ``CaptionsButton``, ``CaptionsButtonViewModel``, ``CaptionsFactory``
public struct CaptionsButtonContainer: View {

    /// The view model driving the button's state and tap action.
    @ObservedObject var viewModel: CaptionsButtonViewModel

    /// Creates a container wrapping the given button view model.
    ///
    /// - Parameter viewModel: The ``CaptionsButtonViewModel`` that manages
    ///   enable/disable state and tap handling.
    public init(viewModel: CaptionsButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        CaptionsButton(
            state: viewModel.state,
            action: viewModel.onTap
        )
    }
}

// MARK: - Previews

#if DEBUG
    #Preview("Disabled") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsButton(state: .disabled)
            }
            .padding(.bottom, 16)
        }
    }

    #Preview("Enabled") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsButton(state: .enabled(""))
            }
            .padding(.bottom, 16)
        }
    }

    #Preview("Enabled - With Captions") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsView(captions: [.previewAlice, .previewBob, .previewCharlie])
                CaptionsButton(state: .enabled(""))
            }
            .padding(.bottom, 16)
        }
    }

    #Preview("Enabled - Scrollable Captions") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsView(captions: [
                    .previewAlice, .previewBob, .previewCharlie,
                    .previewDiana, .previewAlice2, .previewDiana2,
                ])
                CaptionsButton(state: .enabled(""))
            }
            .padding(.bottom, 16)
        }
    }
#endif
