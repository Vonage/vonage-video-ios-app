//
//  Created by Vonage on 21/6/26.
//

import AVKit
import UIKit

/// A UIView backed by `AVSampleBufferDisplayLayer` used as the PiP content surface.
@MainActor
final class PictureInPictureSampleBufferView: UIView {
    private let recordingIndicator = UIImageView(image: UIImage(systemName: "record.circle"))

    var isRecording = false {
        didSet { recordingIndicator.isHidden = !isRecording }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        recordingIndicator.tintColor = .systemRed
        recordingIndicator.contentMode = .scaleAspectFit
        recordingIndicator.isHidden = true
        recordingIndicator.isUserInteractionEnabled = false
        recordingIndicator.accessibilityIdentifier = "archiving-recording-indicator"
        recordingIndicator.layer.shadowColor = UIColor.black.cgColor
        recordingIndicator.layer.shadowOpacity = 0.7
        recordingIndicator.layer.shadowRadius = 1
        recordingIndicator.layer.shadowOffset = .zero
        addSubview(recordingIndicator)
        recordingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recordingIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            recordingIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            recordingIndicator.widthAnchor.constraint(equalToConstant: 16),
            recordingIndicator.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }

    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        guard let layer = layer as? AVSampleBufferDisplayLayer else {
            fatalError("Expected AVSampleBufferDisplayLayer backing layer")
        }
        return layer
    }
}
