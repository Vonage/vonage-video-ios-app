//
//  Created by Vonage on 21/5/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

/// A SwiftUI wrapper that presents `UIActivityViewController` for sharing content
/// via the iOS share sheet (Mail, AirDrop, Files, WhatsApp, Google Drive, etc.).
///
/// Uses a transparent host `UIViewController` that presents the activity controller
/// on appearance, avoiding the `_UIReparentingView` error that occurs when
/// `UIActivityViewController` is embedded directly via `UIViewControllerRepresentable`.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showShareSheet) {
///     ShareSheet(activityItems: logFileURLs)
/// }
/// ```
public struct ShareSheet: UIViewControllerRepresentable {

    /// The items to share (typically file URLs).
    let activityItems: [Any]

    /// Optional application activities to include.
    var applicationActivities: [UIActivity]?

    /// Optional excluded activity types.
    var excludedActivityTypes: [UIActivity.ActivityType]?

    /// Called when the share sheet is dismissed.
    var onDismiss: (() -> Void)?

    public init(
        activityItems: [Any],
        applicationActivities: [UIActivity]? = nil,
        excludedActivityTypes: [UIActivity.ActivityType]? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
        self.onDismiss = onDismiss
    }

    public func makeUIViewController(context: Context) -> ShareSheetHostController {
        ShareSheetHostController(
            activityItems: activityItems,
            applicationActivities: applicationActivities,
            excludedActivityTypes: excludedActivityTypes,
            onDismiss: onDismiss
        )
    }

    public func updateUIViewController(_ uiViewController: ShareSheetHostController, context: Context) {}
}

/// Transparent host controller that presents `UIActivityViewController`
/// once it is added to the window hierarchy, working around SwiftUI sheet conflicts.
public final class ShareSheetHostController: UIViewController {

    private let activityItems: [Any]
    private let applicationActivities: [UIActivity]?
    private let excludedActivityTypes: [UIActivity.ActivityType]?
    private let onDismiss: (() -> Void)?
    private var hasPresented = false

    init(
        activityItems: [Any],
        applicationActivities: [UIActivity]?,
        excludedActivityTypes: [UIActivity.ActivityType]?,
        onDismiss: (() -> Void)?
    ) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasPresented else { return }
        hasPresented = true

        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        activityVC.excludedActivityTypes = excludedActivityTypes
        activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.onDismiss?()
            self?.dismiss(animated: true)
        }

        // For iPad: configure popover presentation from the center of the view.
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        present(activityVC, animated: true)
    }
}
#endif
