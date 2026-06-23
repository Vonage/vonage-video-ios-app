//
//  Created by Vonage on 21/6/26.
//

import AVKit
import UIKit

/// A UIView backed by `AVSampleBufferDisplayLayer` used as the PiP content surface.
final class PictureInPictureSampleBufferView: UIView {
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
