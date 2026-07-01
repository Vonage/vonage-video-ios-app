//
//  Created by Vonage on 29/6/26.
//

import Combine
import SwiftUI
import VERACommonUI
import VERAMeetingRoom

enum MeetingRoomCustomizationButtonKind: String, CaseIterable {
    case toggle
    case dialog
    case overlay
    case sheet

    var label: String {
        switch self {
        case .toggle: "Toggle"
        case .dialog: "Dialog"
        case .overlay: "Overlay"
        case .sheet: "Sheet"
        }
    }

    var systemImageName: String {
        switch self {
        case .toggle: "switch.2"
        case .dialog: "exclamationmark.bubble.fill"
        case .overlay: "rectangle.on.rectangle"
        case .sheet: "rectangle.bottomhalf.inset.filled"
        }
    }
}

struct MeetingRoomCustomizationButtonItem: Identifiable, Equatable {
    let id: String
    let label: String
    let kind: MeetingRoomCustomizationButtonKind
    var isActive: Bool

    var accessibilityIdentifier: String {
        "meeting-room-custom-button-\(id)"
    }

    var systemImageName: String {
        kind.systemImageName
    }
}

@MainActor
struct MeetingRoomCustomizationButtonPresenter: BottomItemPresentable {
    let item: MeetingRoomCustomizationButtonItem

    var id: String { item.id }
    var label: String { item.label }
    var accessibilityIdentifier: String? { item.accessibilityIdentifier }
    var image: Image { Image(systemName: item.systemImageName) }
    var isActive: Bool { item.isActive }
    var accessory: BottomBarButtonAccessory? { nil }
    var overflowSelectionBehavior: BottomBarOverflowSelectionBehavior { .dismissBeforeAction }

    func performAction() {}
}

@MainActor
final class MeetingRoomCustomizationProvider: ObservableObject, MeetingRoomUIProvider {
    @Published private(set) var items: [MeetingRoomCustomizationButtonItem] = []
    @Published private(set) var isCustomBottomBarEnabled = false

    private let updatesSubject = PassthroughSubject<Void, Never>()
    private let updatesPublisher: AnyPublisher<Void, Never>
    private var nextButtonNumber = 1

    nonisolated var updates: AnyPublisher<Void, Never> {
        updatesPublisher
    }

    init() {
        updatesPublisher = updatesSubject.eraseToAnyPublisher()
    }

    func bottomBarButtons() -> [BottomBarButton] {
        items.map { item in
            let presenter = MeetingRoomCustomizationButtonPresenter(item: item)
            return BottomBarButton(
                presenter,
                isActive: item.isActive,
                overflowSelectionBehavior: .dismissBeforeAction,
                presentationRequest: { [weak self] in
                    self?.presentationRequest(for: item.id)
                }
            ) { [weak self] in
                Task { @MainActor in
                    self?.handleButtonAction(id: item.id)
                }
            }
        }
    }

    func bottomBarContent(context: MeetingRoomBottomBarContext) -> AnyView? {
        guard isCustomBottomBarEnabled else { return nil }

        return AnyView(MeetingRoomCustomizationBottomBar(context: context))
    }

    func addButton() {
        addToggleButton()
    }

    func addToggleButton() {
        addButton(kind: .toggle)
    }

    func addDialogButton() {
        addButton(kind: .dialog)
    }

    func addOverlayButton() {
        addButton(kind: .overlay)
    }

    func addSheetButton() {
        addButton(kind: .sheet)
    }

    private func addButton(kind: MeetingRoomCustomizationButtonKind) {
        useSDKBottomBar()

        let item = MeetingRoomCustomizationButtonItem(
            id: "custom-\(nextButtonNumber)",
            label: "\(kind.label) \(nextButtonNumber)",
            kind: kind,
            isActive: false)

        nextButtonNumber += 1
        items.append(item)
        updatesSubject.send()
    }

    func removeLastButton() {
        guard !items.isEmpty else { return }

        useSDKBottomBar()
        items.removeLast()
        updatesSubject.send()
    }

    func clearButtons() {
        guard !items.isEmpty else { return }

        useSDKBottomBar()
        items.removeAll()
        updatesSubject.send()
    }

    func handleButtonAction(id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }

        switch items[index].kind {
        case .toggle:
            items[index].isActive.toggle()
        case .dialog, .overlay, .sheet:
            items[index].isActive = true
        }
        updatesSubject.send()
    }

    func dismissPresentation(sourceButtonId: String) {
        guard let index = items.firstIndex(where: { $0.id == sourceButtonId }),
            items[index].isActive
        else { return }

        items[index].isActive = false
        updatesSubject.send()
    }

    func setCustomBottomBarEnabled(_ isEnabled: Bool) {
        guard isCustomBottomBarEnabled != isEnabled else { return }

        isCustomBottomBarEnabled = isEnabled
        updatesSubject.send()
    }

    private func useSDKBottomBar() {
        isCustomBottomBarEnabled = false
    }

    private func presentationRequest(for id: String) -> MeetingRoomPresentationRequest? {
        guard let item = items.first(where: { $0.id == id }) else { return nil }

        switch item.kind {
        case .toggle:
            return nil
        case .dialog:
            return makePresentationRequest(for: item, style: .dialog)
        case .overlay:
            return makePresentationRequest(for: item, style: .overlay)
        case .sheet:
            return makePresentationRequest(for: item, style: .sheet)
        }
    }

    private func makePresentationRequest(
        for item: MeetingRoomCustomizationButtonItem,
        style: MeetingRoomPresentationRequest.Style
    ) -> MeetingRoomPresentationRequest {
        MeetingRoomPresentationRequest(
            id: "\(item.id)-\(style)",
            style: style,
            title: item.label,
            message: "Presented by an extra bottom bar button.",
            sourceButtonId: item.id,
            onDismiss: { [weak self] in
                self?.dismissPresentation(sourceButtonId: item.id)
            }
        )
    }
}
