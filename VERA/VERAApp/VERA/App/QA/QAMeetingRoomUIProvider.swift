//
//  Created by Vonage on 29/6/26.
//

#if DEBUG
    import Combine
    import SwiftUI
    import VERAMeetingRoom

    struct QAMeetingRoomButtonItem: Identifiable, Equatable {
        let id: String
        let label: String
        let systemImageName: String
        var isActive: Bool

        var accessibilityIdentifier: String {
            "qa-meeting-room-button-\(id)"
        }
    }

    final class QAMeetingRoomUIProvider: ObservableObject, MeetingRoomUIProvider {
        @Published private(set) var items: [QAMeetingRoomButtonItem] = []

        private let updatesSubject = PassthroughSubject<Void, Never>()
        private var nextButtonNumber = 1
        private let systemImageNames = [
            "star.fill",
            "bolt.fill",
            "bell.fill",
            "flag.fill",
            "heart.fill",
        ]

        var updates: AnyPublisher<Void, Never> {
            updatesSubject.eraseToAnyPublisher()
        }

        @MainActor
        func bottomBarButtons() -> [BottomBarButton] {
            items.map { item in
                BottomBarButton(
                    id: item.id,
                    label: item.label,
                    accessibilityIdentifier: item.accessibilityIdentifier,
                    image: Image(systemName: item.systemImageName),
                    isActive: item.isActive
                ) { [weak self] in
                    Task { @MainActor in
                        self?.toggleButton(id: item.id)
                    }
                }
            }
        }

        @MainActor
        func addButton() {
            let item = QAMeetingRoomButtonItem(
                id: "qa-\(nextButtonNumber)",
                label: "QA \(nextButtonNumber)",
                systemImageName: systemImageNames[(nextButtonNumber - 1) % systemImageNames.count],
                isActive: false)

            nextButtonNumber += 1
            items.append(item)
            updatesSubject.send()
        }

        @MainActor
        func removeLastButton() {
            guard !items.isEmpty else { return }

            items.removeLast()
            updatesSubject.send()
        }

        @MainActor
        func clearButtons() {
            guard !items.isEmpty else { return }

            items.removeAll()
            updatesSubject.send()
        }

        @MainActor
        func toggleButton(id: String) {
            guard let index = items.firstIndex(where: { $0.id == id }) else { return }

            items[index].isActive.toggle()
            updatesSubject.send()
        }
    }
#endif
