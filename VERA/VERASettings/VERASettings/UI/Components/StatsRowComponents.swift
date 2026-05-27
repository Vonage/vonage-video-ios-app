//
//  Created by Vonage on 22/2/26.
//

import SwiftUI

/// Section header for stats tables (e.g. "AUDIO", "VIDEO", "NETWORK").
struct StatsSectionHeader: View {

    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            #if os(iOS)
                .listRowBackground(Color(.systemGroupedBackground))
            #endif
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
            .listRowSeparator(.hidden)
    }
}

/// Sub-header for stats tables (e.g. simulcast quality labels).
struct StatsSubHeader: View {

    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            .listRowSeparator(.hidden)
    }
}

/// A single metric row displaying a label and its value.
struct StatsRow: View {

    let metric: String
    let value: String?
    var defaultValue: String = StatsConstants.defaultValue

    var body: some View {
        HStack {
            Text(metric)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? defaultValue)
                .monospacedDigit()
                .fontWeight(.medium)
        }
    }
}
