//
//  Created by Vonage on 26/10/26.
//

import Foundation

/// Options chosen by the user when starting a post-call transcription.
///
/// They apply to a single transcription archive and cannot change while it runs.
public struct TranscriptionOptions: Equatable, Sendable {
    /// Whether the transcript includes an AI-generated summary.
    public var hasSummary: Bool

    public init(hasSummary: Bool) {
        self.hasSummary = hasSummary
    }

    /// Summary on.
    public static let `default` = TranscriptionOptions(hasSummary: true)
}
