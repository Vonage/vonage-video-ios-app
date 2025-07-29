//
//  Created by Vonage on 16/7/25.
//

import SwiftUI

struct UIViewContainer: UIViewRepresentable {
    private let view: UIView

    init(view: UIView) {
        self.view = view
    }

    func makeUIView(context: Context) -> UIView { view }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
