//
//  Created by Vonage on 29/6/26.
//

#if DEBUG
    import SwiftUI

    struct QAMeetingRoomButtonsMenu: View {
        @ObservedObject var provider: QAMeetingRoomUIProvider

        var body: some View {
            NavigationStack {
                List {
                    Section("Meeting room") {
                        NavigationLink {
                            QAMeetingRoomBottomBarButtonsView(provider: provider)
                        } label: {
                            Label {
                                HStack {
                                    Text("Bottom bar")
                                    Spacer()
                                    Text("\(provider.items.count) buttons")
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "rectangle.bottomthird.inset.filled")
                            }
                        }
                    }
                }
                .navigationTitle("Customize UI")
            }
        }
    }

    private struct QAMeetingRoomBottomBarButtonsView: View {
        @ObservedObject var provider: QAMeetingRoomUIProvider

        var body: some View {
            List {
                Section {
                    HStack {
                        Text("Configured buttons")
                        Spacer()
                        Text("\(provider.items.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Add button") {
                        provider.addButton()
                    }

                    Button("Remove last") {
                        provider.removeLastButton()
                    }
                    .disabled(provider.items.isEmpty)

                    Button("Clear", role: .destructive) {
                        provider.clearButtons()
                    }
                    .disabled(provider.items.isEmpty)
                }

                Section("Buttons") {
                    if provider.items.isEmpty {
                        Text("No session buttons configured")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(provider.items) { item in
                            Label {
                                HStack {
                                    Text(item.label)
                                    Spacer()
                                    if item.isActive {
                                        Text("Active")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } icon: {
                                Image(systemName: item.systemImageName)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bottom bar")
        }
    }
#endif
