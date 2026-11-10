//
//  Created by Vonage on 18/6/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// Recording presentation of the archiving state.
///
/// - SeeAlso: ``ArchiveKind`` for the presentation of other archive kinds.
extension ArchivingState {
    public var bottomBarLabel: String {
        ArchiveKind.recording.bottomBarLabel(for: self)
    }

    public var bottomBarAccessibilityIdentifier: String {
        ArchiveKind.recording.bottomBarAccessibilityIdentifier(for: self)
    }

    public var bottomBarImage: Image {
        ArchiveKind.recording.bottomBarImage(for: self)
    }
}
