import SwiftUI
import VERACommonUI
import VERADomain

/// A camera-only pair. Screen shares and extra tiles keep the user's existing meeting layout.
@MainActor
struct OneToOneParticipants {
    let local: UIParticipant
    let remote: UIParticipant

    init?(participants: [UIParticipant]) {
        guard participants.count == 2,
            !participants.contains(where: \.isScreenshare),
            let local = participants.first(where: { !$0.isRemote }),
            let remote = participants.first(where: \.isRemote)
        else { return nil }
        self.local = local
        self.remote = remote
    }
}

enum FloatingSelfViewCorner: String, CaseIterable, Sendable {
    case topLeft, topRight, bottomLeft, bottomRight
}

/// Value-only geometry stays independent of SDK callbacks and adapts to rotation and control visibility.
struct FloatingSelfViewGeometry {
    let tileSize: CGSize
    let centers: CGRect

    init(container: CGSize, bottomInset: CGFloat, labelClearance: CGFloat = 48) {
        let width = max(0, container.width)
        let height = max(0, container.height)
        let horizontalInset = min(12, width / 2)
        let topInset = min(48, height / 2)
        // Keep both bottom corners and the drag area above the remote name label.
        let bottomInset = min(max(labelClearance, bottomInset + 12), height - topInset)
        let availableHeight = max(0, height - topInset - bottomInset)
        let tileWidth = max(0, min(144, width * 0.32, availableHeight * 0.75))
        tileSize = CGSize(width: tileWidth, height: tileWidth / 0.75)
        centers = CGRect(
            x: horizontalInset + tileSize.width / 2,
            y: topInset + tileSize.height / 2,
            width: max(0, width - 2 * horizontalInset - tileSize.width),
            height: max(0, availableHeight - tileSize.height)
        )
    }

    func center(for corner: FloatingSelfViewCorner) -> CGPoint {
        switch corner {
        case .topLeft: CGPoint(x: centers.minX, y: centers.minY)
        case .topRight: CGPoint(x: centers.maxX, y: centers.minY)
        case .bottomLeft: CGPoint(x: centers.minX, y: centers.maxY)
        case .bottomRight: CGPoint(x: centers.maxX, y: centers.maxY)
        }
    }

    func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, centers.minX), centers.maxX),
            y: min(max(point.y, centers.minY), centers.maxY))
    }

    func nearestCorner(to point: CGPoint) -> FloatingSelfViewCorner {
        if point.y < centers.midY {
            return point.x < centers.midX ? .topLeft : .topRight
        }
        return point.x < centers.midX ? .bottomLeft : .bottomRight
    }
}

@MainActor
struct OneToOneCallLayout: View {
    let participants: OneToOneParticipants
    @Binding var corner: FloatingSelfViewCorner
    let bottomInset: CGFloat
    @State private var dragOffset = CGSize.zero
    @ScaledMetric(relativeTo: .caption) private var labelClearance: CGFloat = 48
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let geometry = FloatingSelfViewGeometry(
                container: proxy.size, bottomInset: bottomInset, labelClearance: labelClearance
            )
            let anchor = geometry.center(for: corner)
            let center = geometry.clamped(CGPoint(x: anchor.x + dragOffset.width, y: anchor.y + dragOffset.height))
            ZStack(alignment: .topLeading) {
                ParticipantVideoCard(participant: participants.remote, activeSpeakerId: nil, fillsAvailableSpace: true)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .trackingVisibility(of: participants.remote)

                ParticipantVideoCard(participant: participants.local, activeSpeakerId: nil, fillsAvailableSpace: true)
                    .frame(width: geometry.tileSize.width, height: geometry.tileSize.height)
                    .contentShape(Rectangle())
                    .position(center)
                    .trackingVisibility(of: participants.local)
                    .accessibilityAnchor("meeting-self-view-floating")
                    .accessibilityAction(named: Text("Move to top left", bundle: .module)) { move(to: .topLeft) }
                    .accessibilityAction(named: Text("Move to top right", bundle: .module)) { move(to: .topRight) }
                    .accessibilityAction(named: Text("Move to bottom left", bundle: .module)) { move(to: .bottomLeft) }
                    .accessibilityAction(named: Text("Move to bottom right", bundle: .module)) {
                        move(to: .bottomRight)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { dragOffset = $0.translation }
                            .onEnded { value in
                                let destination = CGPoint(
                                    x: anchor.x + value.translation.width,
                                    y: anchor.y + value.translation.height)
                                move(to: geometry.nearestCorner(to: destination))
                            }
                    )
            }
            .onChange(of: proxy.size) { _, _ in dragOffset = .zero }
            .onChange(of: bottomInset) { _, _ in dragOffset = .zero }
        }
    }

    private func move(to destination: FloatingSelfViewCorner) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85)) {
            corner = destination
            dragOffset = .zero
        }
    }
}

#Preview {
    let local = UIParticipant(
        participant: Participant(
            id: "local",
            name: "You",
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: CGSize(width: 480, height: 640),
            isRemote: false,
            creationTime: .now,
            isScreenshare: false,
            view: AnyView(Color.blue)
        ))
    MeetingRoomContent(
        participants: [local, PreviewData.uiSingleParticipant],
        layout: .grid,
        activeSpeakerId: nil,
        selfViewBottomInset: BottomBarConstants.totalHeight
    )
    .preferredColorScheme(.dark)
}
