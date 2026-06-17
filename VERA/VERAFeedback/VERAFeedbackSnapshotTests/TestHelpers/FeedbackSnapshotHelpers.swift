//
//  Created by Vonage on 10/06/2026.
//

import UIKit

@testable import VERAFeedback

enum FeedbackSnapshotHelpers {

    static func makeTestImage(size: CGSize = CGSize(width: 200, height: 120)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    static func fillRequiredTextFields(in viewModel: FeedbackFormViewModel) {
        viewModel.feedbackFields[0].value = "Joining a video call with three participants"
        viewModel.feedbackFields[1].value = "Alex Johnson"
        viewModel.feedbackFields[2].value =
            "The video froze for several seconds whenever someone shared their screen."
    }

    static func attachSampleImage(to viewModel: FeedbackFormViewModel) {
        guard let imageField = viewModel.feedbackFields.first(where: { $0.type == .image }) else {
            return
        }
        imageField.attachedImage = makeTestImage()
    }
}
