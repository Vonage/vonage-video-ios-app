import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum FeedbackViewTestHelpers {

  /// Hosts a SwiftUI view in a window so layout and body code paths are exercised for coverage.
  @MainActor
  static func host<V: View>(_ view: V, size: CGSize = CGSize(width: 390, height: 900)) {
    #if canImport(AppKit)
    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = CGRect(origin: .zero, size: size)

    let window = NSWindow(
      contentRect: hostingView.frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.contentView = hostingView
    window.layoutIfNeeded()
    hostingView.layoutSubtreeIfNeeded()
    #elseif canImport(UIKit)
    let hostingController = UIHostingController(rootView: view)
    hostingController.view.frame = CGRect(origin: .zero, size: size)

    let window = UIWindow(frame: hostingController.view.frame)
    window.rootViewController = hostingController
    window.makeKeyAndVisible()
    hostingController.view.setNeedsLayout()
    hostingController.view.layoutIfNeeded()
    #endif
  }
}
