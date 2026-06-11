//
//  Created by Vonage on 11/06/2026.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

typealias PlatformImage = UIImage
typealias PlatformView = UIView

enum PlatformImageFactory {
    static func image(from data: Data) -> PlatformImage? {
        UIImage(data: data)
    }
}

extension Image {
    init(platformImage: PlatformImage) {
        self.init(uiImage: platformImage)
    }
}

extension Color {
    static var feedbackFormBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }
}

#elseif canImport(AppKit)
import AppKit

typealias PlatformImage = NSImage
typealias PlatformView = NSView

enum PlatformImageFactory {
    static func image(from data: Data) -> PlatformImage? {
        NSImage(data: data)
    }
}

extension Image {
    init(platformImage: PlatformImage) {
        self.init(nsImage: platformImage)
    }
}

extension Color {
    static var feedbackFormBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }
}
#endif
