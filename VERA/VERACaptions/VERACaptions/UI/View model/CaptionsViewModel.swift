//
//  Created by Vonage on 10/2/26.
//

import Combine
import Foundation
import VERADomain

public final class CaptionsViewModel: ObservableObject {
    
    @Published public var captions: [UICaptionItem] = []
    
    /// Maximum number of captions to display simultaneously
    private let maxVisibleCaptions = 3
    private var cancellables = Set<AnyCancellable>()
    
    private let captionsObserver: CaptionsObserver
    
    public init(captionsObserver: CaptionsObserver) {
        self.captionsObserver = captionsObserver
    }
    
    /// Convenience init for previews and tests.
    public convenience init() {
        self.init(captionsObserver: EmptyCaptionsObserver())
    }
    
     public func initObservers() {
        captionsObserver.captionsReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] captions in
                self?.handleCaptions(captions)
            }
            .store(in: &cancellables)         
    }
    
    public func cancelObservers() {
        cancellables.removeAll()
    }
    
    // MARK: - Private
    
    private func handleCaptions(_ captions: [CaptionItem]) {
        self.captions = Array(
            captions
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(maxVisibleCaptions)
                .map(UICaptionItem.init)
        )
    }
}
