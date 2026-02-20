//
//  Created by Vonage on 10/2/26.
//

import SwiftUI

/// A stateful container that manages the ``CaptionsViewModel`` lifecycle
/// and renders a ``CaptionsView``.
///
/// `CaptionsViewContainer` bridges the reactive view-model layer with the
/// pure ``CaptionsView``:
/// - **`onAppear`** — calls ``CaptionsViewModel/initObservers()`` to start
///   receiving caption updates via Combine.
/// - **`onDisappear`** — calls ``CaptionsViewModel/cancelObservers()`` to
///   stop receiving updates and release subscriptions.
///
/// ## Usage
///
/// Create via ``CaptionsFactory/makeCaptionsView()`` or instantiate directly:
///
/// ```swift
/// CaptionsViewContainer(viewModel: captionsViewModel)
/// ```
///
/// - SeeAlso: ``CaptionsView``, ``CaptionsViewModel``, ``CaptionsFactory``
public struct CaptionsViewContainer: View {

    /// The view model that provides live caption data.
    @ObservedObject var viewModel: CaptionsViewModel

    /// Creates a container wrapping the given captions view model.
    ///
    /// - Parameter viewModel: The ``CaptionsViewModel`` that publishes caption updates.
    public init(viewModel: CaptionsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        CaptionsView(captions: viewModel.captions)
            .onAppear {
                viewModel.initObservers()
            }.onDisappear {
                viewModel.cancelObservers()
            }
    }
}

// MARK: - Previews

#Preview("With 1 Caption") {
    let viewModel = CaptionsViewModel()
    viewModel.captions = [.previewAlice]

    return ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            CaptionsViewContainer(viewModel: viewModel)
        }
    }
}

#Preview("With 2 Captions") {
    let viewModel = CaptionsViewModel()
    viewModel.captions = [.previewAlice, .previewBob]

    return ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            CaptionsViewContainer(viewModel: viewModel)
        }
    }
}

#Preview("With 3 Captions") {
    let viewModel = CaptionsViewModel()
    viewModel.captions = [.previewAlice, .previewBob, .previewCharlie]

    return ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            CaptionsViewContainer(viewModel: viewModel)
        }
    }
}

#Preview("Scrollable - 6 Captions") {
    let viewModel = CaptionsViewModel()
    viewModel.captions = [
        .previewAlice, .previewBob, .previewCharlie,
        .previewDiana, .previewAlice2, .previewDiana2,
    ]

    return ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            CaptionsViewContainer(viewModel: viewModel)
        }
    }
}

#Preview("Empty") {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            CaptionsViewContainer(viewModel: CaptionsViewModel())
        }
    }
}
