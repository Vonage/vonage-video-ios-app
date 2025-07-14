//
//  Created by Vonage on 9/7/25.
//

import Foundation

public protocol VideoRenderable {
    associatedtype PlatformView

    func makeRenderView() -> PlatformView
}
