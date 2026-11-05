//
//  Created by Vonage on 18/10/26.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit

    /// Presents the system share sheet so the user can save or send a local file.
    struct ShareSheet: UIViewControllerRepresentable {
        let fileURL: URL

        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
#else
    /// Offers a local file through `ShareLink` where `UIActivityViewController` is unavailable.
    struct ShareSheet: View {
        let fileURL: URL

        var body: some View {
            ShareLink(item: fileURL)
                .padding()
        }
    }
#endif
