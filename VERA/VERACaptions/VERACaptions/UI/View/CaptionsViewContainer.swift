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
#if DEBUG
    #Preview("With 1 Caption") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsViewContainer(viewModel: .oneCaptionViewModel)
            }
        }
    }

    #Preview("With 2 Captions") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsViewContainer(viewModel: .twoCaptionViewModel)
            }
        }
    }

    #Preview("With 3 Captions") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsViewContainer(viewModel: .threeCaptionViewModel)
            }
        }
    }

    #Preview("Scrollable - 6 Captions") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsViewContainer(viewModel: .sixCaptionViewModel)
            }
        }
    }

    #Preview("Empty") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsViewContainer(viewModel: .emptyCaptionViewModel)
            }
        }
    }

    extension CaptionsViewModel {

        fileprivate static var emptyCaptionViewModel: CaptionsViewModel {
            return CaptionsViewModel()
        }

        fileprivate static var oneCaptionViewModel: CaptionsViewModel {
            let vm = CaptionsViewModel()
            vm.captions = [.previewAlice]
            return vm
        }

        fileprivate static var twoCaptionViewModel: CaptionsViewModel {
            let vm = CaptionsViewModel()
            vm.captions = [.previewAlice, .previewBob]
            return vm
        }

        fileprivate static var threeCaptionViewModel: CaptionsViewModel {
            let vm = CaptionsViewModel()
            vm.captions = [.previewAlice, .previewBob, .previewCharlie]
            return vm
        }

        fileprivate static var sixCaptionViewModel: CaptionsViewModel {
            let vm = CaptionsViewModel()
            vm.captions = [
                .previewAlice, .previewBob, .previewCharlie,
                .previewDiana, .previewAlice2, .previewDiana2,
            ]
            return vm
        }
    }
#endif
