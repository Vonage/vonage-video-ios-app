//
//  Created by Vonage on 10/2/26.
//

import SwiftUI

public struct CaptionsViewContainer: View {
    
    @ObservedObject var viewModel: CaptionsViewModel
    
    public init(viewModel: CaptionsViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        CaptionsView(captions: viewModel.captions)
        .onAppear() {
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
        .previewDiana, .previewAlice2, .previewDiana2
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
