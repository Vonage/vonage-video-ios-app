//
//  Created by Vonage on 10/2/26.
//

import Combine
import Foundation
import VERADomain

public final class CaptionsViewModel: ObservableObject {
    @Published public var captions: [CaptionItem] = []

    private var initiated = false

    public func setup() {
        guard !initiated else { return }
        initiated = true

    }

    public func updateCaptions(_ captions: [CaptionItem]) {
        self.captions = captions
    }
}
