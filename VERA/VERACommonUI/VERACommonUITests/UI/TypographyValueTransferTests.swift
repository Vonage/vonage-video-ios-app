//
//  Created by Vonage on 15/10/26.
//

import SwiftUI
import Testing
import VERACommonUI

@Suite("Typography value transfers")
struct TypographyValueTransferTests {
    @Test("All generated styles preserve mobile and desktop metrics after transfer")
    func generatedStylesPreserveBothConfigurations() async {
        let styles: [TypographyStyle] = [
            .headline, .subtitle, .heading1, .heading2, .heading3, .heading4,
            .bodyExtended, .bodyExtendedSemibold, .bodyBase, .bodyBaseSemibold,
            .caption, .captionSemibold,
        ]
        let store = TypographySnapshotStore(styles)

        let transferred = await Task.detached { await store.snapshot() }.value

        #expect(transferred.count == styles.count)
        for (received, expected) in zip(transferred, styles) {
            #expect(received == expected)
            expectSameMetrics(received.mobileConfig, expected.mobileConfig)
            expectSameMetrics(received.desktopConfig, expected.desktopConfig)
        }
    }

    @Test("A custom typography configuration preserves fractional metrics and weight")
    func customConfigurationPreservesMetrics() async {
        let original = TypographyConfig(fontSize: 13.5, lineHeight: 21.25, weight: .heavy, lineSpacing: 7.75)
        let store = TypographySnapshotStore(original)

        let transferred = await Task.detached { await store.snapshot() }.value

        expectSameMetrics(transferred, original)
    }

    private func expectSameMetrics(_ received: TypographyConfig, _ expected: TypographyConfig) {
        #expect(received.fontSize == expected.fontSize)
        #expect(received.lineHeight == expected.lineHeight)
        #expect(received.weight == expected.weight)
        #expect(received.lineSpacing == expected.lineSpacing)
    }
}

private actor TypographySnapshotStore<Value: Sendable> {
    private let value: Value

    init(_ value: Value) { self.value = value }
    func snapshot() -> Value { value }
}
