//
//  Created by Vonage on 16/7/25.
//

import OpenTok
import SwiftUI

struct OpenTokRendererView: UIViewRepresentable {
    private let publisher: OTPublisher

    init(publisher: OTPublisher) {
        self.publisher = publisher
    }

    func makeUIView(context: Context) -> UIView { publisher.view! }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
