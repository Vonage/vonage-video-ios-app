//
//  Created by Vonage on 29/6/26.
//

import SwiftUI

struct MeetingRoomCustomizationMenu: View {
    @ObservedObject var provider: MeetingRoomCustomizationProvider

    var body: some View {
        NavigationStack {
            List {
                Section("Meeting room") {
                    NavigationLink {
                        MeetingRoomCustomizationBottomBarMenu(provider: provider)
                    } label: {
                        Label {
                            HStack {
                                Text("Bottom bar")
                                Spacer()
                                Text(provider.isCustomBottomBarEnabled ? "Custom" : "SDK")
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

struct MeetingRoomCustomizationBottomBarMenu: View {
    @ObservedObject var provider: MeetingRoomCustomizationProvider

    var body: some View {
        List {
            Section("Bottom bar") {
                NavigationLink {
                    MeetingRoomCustomizationBottomBarButtonsView(provider: provider)
                } label: {
                    Label {
                        HStack {
                            Text("Buttons")
                            Spacer()
                            Text("\(provider.items.count)")
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.grid.2x2")
                    }
                }

                NavigationLink {
                    MeetingRoomCustomizationBottomBarCustomBarView(provider: provider)
                } label: {
                    Label {
                        HStack {
                            Text("Custom bar")
                            Spacer()
                            Text(provider.isCustomBottomBarEnabled ? "On" : "Off")
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
        }
        .navigationTitle("Bottom bar")
    }
}

struct MeetingRoomCustomizationBottomBarButtonsView: View {
    @ObservedObject var provider: MeetingRoomCustomizationProvider

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Configured buttons")
                    Spacer()
                    Text("\(provider.items.count)")
                        .foregroundStyle(.secondary)
                }

                Text("Buttons are appended to the SDK bottom bar.")
                    .foregroundStyle(.secondary)
            }

            Section {
                MeetingRoomCustomizationAddButtonRow(
                    title: "Add toggle button",
                    systemImage: MeetingRoomCustomizationButtonKind.toggle.systemImageName
                ) {
                    provider.addToggleButton()
                }

                MeetingRoomCustomizationAddButtonRow(
                    title: "Add dialog button",
                    systemImage: MeetingRoomCustomizationButtonKind.dialog.systemImageName
                ) {
                    provider.addDialogButton()
                }

                MeetingRoomCustomizationAddButtonRow(
                    title: "Add overlay button",
                    systemImage: MeetingRoomCustomizationButtonKind.overlay.systemImageName
                ) {
                    provider.addOverlayButton()
                }

                MeetingRoomCustomizationAddButtonRow(
                    title: "Add sheet button",
                    systemImage: MeetingRoomCustomizationButtonKind.sheet.systemImageName
                ) {
                    provider.addSheetButton()
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
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.label)
                                    Spacer()
                                    if item.isActive {
                                        Text("Active")
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Text(item.kind.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: item.systemImageName)
                        }
                    }
                }
            }
        }
        .navigationTitle("Buttons")
    }
}

struct MeetingRoomCustomizationAddButtonRow: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } icon: {
                Image(systemName: systemImage)
                    .frame(width: 22)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(MeetingRoomCustomizationAddButtonStyle())
    }
}

struct MeetingRoomCustomizationAddButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? Color.accentColor : Color.primary)
            .background {
                if configuration.isPressed {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.14))
                }
            }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct MeetingRoomCustomizationBottomBarCustomBarView: View {
    @ObservedObject var provider: MeetingRoomCustomizationProvider

    var body: some View {
        List {
            Section("Bar") {
                Toggle("Use custom bottom bar", isOn: customBottomBarBinding)

                HStack {
                    Text("Current bar")
                    Spacer()
                    Text(provider.isCustomBottomBarEnabled ? "Custom" : "SDK")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Custom implementation") {
                Label("Uses MeetingRoomBottomBarContext.controls", systemImage: "slider.horizontal.3")
                Text("Buttons extends the SDK bottom bar. Bar replaces the full bottom bar.")
                    .foregroundStyle(.secondary)
                Text(
                    "Participants control toggles the SDK participant list. "
                        + "A host can ignore it and use state.participants to present its own UI."
                )
                .foregroundStyle(.secondary)
            }

            Section("Included controls") {
                Label("Microphone · always available", systemImage: "mic.fill")
                Label("Camera · always available", systemImage: "video.fill")
                Label("Layout · always available", systemImage: "rectangle.grid.2x2.fill")
                Label("Participants · optional SDK list toggle", systemImage: "person.2.fill")
                Label("End call · always available", systemImage: "phone.down.fill")
                Label("Presentations · dialog, overlay, sheet", systemImage: "rectangle.on.rectangle")
            }
        }
        .navigationTitle("Custom bar")
    }

    var customBottomBarBinding: Binding<Bool> {
        Binding(
            get: { provider.isCustomBottomBarEnabled },
            set: { provider.setCustomBottomBarEnabled($0) }
        )
    }
}
