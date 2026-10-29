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

    /// The voice activity indicator follows the tile, from 16pt up to the standard 32pt.
    var audioIndicatorSize: CGFloat {
        min(32, max(16, min(tileSize.width, tileSize.height) * 0.2))
    }

    /// - Parameter videoAspectRatio: Width over height of the self-view video; the tile takes its shape.
    init(
        container: CGSize, bottomInset: CGFloat, labelClearance: CGFloat = 48, videoAspectRatio: CGFloat = 0.75
    ) {
        let width = max(0, container.width)
        let height = max(0, container.height)
        let horizontalInset = min(12, width / 2)
        let topInset = min(48, height / 2)
        // Keep both bottom corners and the drag area above the remote name label.
        let bottomInset = min(max(labelClearance, bottomInset + 12), height - topInset)
        let availableHeight = max(0, height - topInset - bottomInset)
        // The long side is 192pt (a 144x192 tile at 3:4), shrunk to fit the container.
        let ratio = videoAspectRatio.isFinite && videoAspectRatio > 0 ? videoAspectRatio : 0.75
        let natural = ratio < 1 ? CGSize(width: 192 * ratio, height: 192) : CGSize(width: 192, height: 192 / ratio)
        let scale = max(0, min(1, width * 0.32 / natural.width, availableHeight / natural.height))
        tileSize = CGSize(width: natural.width * scale, height: natural.height * scale)
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
                container: proxy.size, bottomInset: bottomInset, labelClearance: labelClearance,
                videoAspectRatio: selfViewAspectRatio
            )
            let anchor = geometry.center(for: corner)
            let center = geometry.clamped(CGPoint(x: anchor.x + dragOffset.width, y: anchor.y + dragOffset.height))
            ZStack(alignment: .topLeading) {
                Color.clear

                ParticipantVideoCard(
                    participant: participants.local, activeSpeakerId: nil, fillsAvailableSpace: true,
                    audioIndicatorSize: geometry.audioIndicatorSize
                )
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
            .background {
                // The far end fills the whole screen; its labels stay inside the safe area.
                ParticipantVideoCard(
                    participant: participants.remote, activeSpeakerId: nil, fillsAvailableSpace: true,
                    fullScreenOverlayInsets: proxy.safeAreaInsets
                )
                .ignoresSafeArea()
                .trackingVisibility(of: participants.remote)
            }
            .onChange(of: proxy.size) { _, _ in dragOffset = .zero }
            .onChange(of: bottomInset) { _, _ in dragOffset = .zero }
        }
    }

    /// Before the first frame the dimensions are unknown, so the tile keeps its portrait default.
    private var selfViewAspectRatio: CGFloat {
        let dimensions = participants.local.videoDimensions
        guard dimensions.width > 0, dimensions.height > 0 else { return 0.75 }
        return dimensions.width / dimensions.height
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
