import CoreGraphics
import SwiftUI
import Testing
import VERADomain
import VERATestHelpers

@testable import VERAMeetingRoom

@Suite("One-to-one layout selection and floating self-view")
@MainActor
struct OneToOneCallLayoutTests {
    private func local() -> UIParticipant {
        UIParticipant(participant: makeMockParticipant(id: "self", isRemote: false))
    }

    private func remote(_ id: String = "remote", screenshare: Bool = false) -> UIParticipant {
        UIParticipant(participant: makeMockParticipant(id: id, isScreenshare: screenshare))
    }

    @Test(
        "A camera-only pair uses the floating layout regardless of tile ordering or selected layout",
        arguments: [MeetingRoomLayout.grid, .activeSpeaker])
    func cameraPair(layout: MeetingRoomLayout) throws {
        for participants in [[local(), remote()], [remote(), local()]] {
            let content = MeetingRoomContent(participants: participants, layout: layout, activeSpeakerId: "self")
            let pair = try #require(content.oneToOneParticipants)
            #expect(pair.local.id == "self")
            #expect(pair.remote.id == "remote")
        }
    }

    @Test("Screen sharing restores the existing layout and removing it restores the one-to-one layout")
    func screenSharingTransition() {
        let cameraPair = [local(), remote()]
        #expect(OneToOneParticipants(participants: cameraPair) != nil)
        #expect(OneToOneParticipants(participants: cameraPair + [remote("share", screenshare: true)]) == nil)
        #expect(OneToOneParticipants(participants: [local(), remote("share", screenshare: true)]) == nil)
        #expect(OneToOneParticipants(participants: cameraPair) != nil)
    }

    @Test("Waiting alone, multiple remote participants and missing self-view keep the existing layout")
    func otherMeetings() {
        #expect(OneToOneParticipants(participants: []) == nil)
        #expect(OneToOneParticipants(participants: [local()]) == nil)
        #expect(OneToOneParticipants(participants: [remote(), remote("second")]) == nil)
        #expect(OneToOneParticipants(participants: [local(), remote(), remote("second")]) == nil)
    }

    @Test("Camera-off participants still use the same one-to-one layout")
    func cameraOff() {
        let participants = [
            UIParticipant(participant: makeMockParticipant(id: "self", isCameraEnabled: false, isRemote: false)),
            UIParticipant(participant: makeMockParticipant(id: "remote", isCameraEnabled: false)),
        ]
        #expect(OneToOneParticipants(participants: participants) != nil)
    }

    @Test("Dragging snaps to each nearest corner", arguments: FloatingSelfViewCorner.allCases)
    func snapping(corner: FloatingSelfViewCorner) {
        let geometry = FloatingSelfViewGeometry(container: CGSize(width: 390, height: 720), bottomInset: 64)
        #expect(geometry.nearestCorner(to: geometry.center(for: corner)) == corner)
    }

    @Test(
        "All corners remain within the content area and clear of controls after resizing",
        arguments: [
            CGSize(width: 390, height: 720), CGSize(width: 780, height: 320),
            CGSize(width: 1, height: 1), .zero,
        ])
    func boundedCorners(container: CGSize) {
        let geometry = FloatingSelfViewGeometry(container: container, bottomInset: 64)
        for corner in FloatingSelfViewCorner.allCases {
            let center = geometry.center(for: corner)
            let rect = CGRect(
                x: center.x - geometry.tileSize.width / 2,
                y: center.y - geometry.tileSize.height / 2,
                width: geometry.tileSize.width,
                height: geometry.tileSize.height)
            #expect(rect.minX >= 0)
            #expect(rect.minY >= 0)
            #expect(rect.maxX <= container.width + 0.001)
            #expect(rect.maxY <= container.height + 0.001)
            if container.height > 150 {
                #expect(rect.maxY <= container.height - 64)
                #expect(rect.minY >= 48 - 0.001)
            }
        }
    }

    @Test(
        "The self-view tile follows the local video aspect ratio in portrait and landscape",
        arguments: [
            (CGSize(width: 390, height: 720), CGFloat(3.0 / 4.0)),
            (CGSize(width: 780, height: 320), CGFloat(16.0 / 9.0)),
            (CGSize(width: 780, height: 320), CGFloat(4.0 / 3.0)),
        ])
    func tileFollowsVideoAspectRatio(container: CGSize, ratio: CGFloat) {
        let geometry = FloatingSelfViewGeometry(container: container, bottomInset: 64, videoAspectRatio: ratio)
        #expect(abs(geometry.tileSize.width / geometry.tileSize.height - ratio) < 0.001)
        #expect(max(geometry.tileSize.width, geometry.tileSize.height) <= 192 + 0.001)
    }

    @Test(
        "The voice activity indicator scales with the self-view tile",
        arguments: [
            (CGSize(width: 390, height: 720), CGFloat(3.0 / 4.0)),
            (CGSize(width: 780, height: 320), CGFloat(16.0 / 9.0)),
            (CGSize(width: 1, height: 1), CGFloat(3.0 / 4.0)),
        ])
    func indicatorScalesWithTile(container: CGSize, ratio: CGFloat) {
        let geometry = FloatingSelfViewGeometry(container: container, bottomInset: 64, videoAspectRatio: ratio)
        let shortSide = min(geometry.tileSize.width, geometry.tileSize.height)
        #expect(geometry.audioIndicatorSize <= 32)
        #expect(geometry.audioIndicatorSize >= 16)
        if shortSide >= 80 {
            #expect(abs(geometry.audioIndicatorSize - shortSide * 0.2) < 0.001)
        }
    }

    @Test("A portrait self-view keeps the existing tile size")
    func portraitTileUnchanged() {
        let geometry = FloatingSelfViewGeometry(container: CGSize(width: 390, height: 720), bottomInset: 64)
        #expect(abs(geometry.tileSize.width - 390 * 0.32) < 0.001)
        #expect(abs(geometry.tileSize.height - 390 * 0.32 / 0.75) < 0.001)
    }

    @Test("Unknown or invalid video dimensions fall back to the portrait tile", arguments: [CGFloat(0), -1, .nan])
    func invalidAspectRatio(ratio: CGFloat) {
        let size = CGSize(width: 390, height: 720)
        let geometry = FloatingSelfViewGeometry(container: size, bottomInset: 64, videoAspectRatio: ratio)
        #expect(geometry.tileSize == FloatingSelfViewGeometry(container: size, bottomInset: 64).tileSize)
    }

    @Test(
        "The composed one-to-one layout renders at the available portrait and landscape sizes",
        arguments: [CGSize(width: 390, height: 720), CGSize(width: 780, height: 320)])
    func rendersLayout(size: CGSize) throws {
        let content = MeetingRoomContent(
            participants: [local(), remote()], layout: .grid, activeSpeakerId: nil, selfViewBottomInset: 64
        )
        .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: content)
        let image = try #require(renderer.cgImage)
        #expect(image.width == Int(size.width))
        #expect(image.height == Int(size.height))
    }

    @Test(
        "Both lower corners clear the remote label when controls are hidden or shown",
        arguments: [CGFloat(0), CGFloat(64)])
    func remoteLabelRemainsVisible(bottomInset: CGFloat) {
        let size = CGSize(width: 390, height: 720)
        for clearance: CGFloat in [48, 72] {
            let geometry = FloatingSelfViewGeometry(
                container: size, bottomInset: bottomInset, labelClearance: clearance
            )
            for corner in [FloatingSelfViewCorner.bottomLeft, .bottomRight] {
                let center = geometry.center(for: corner)
                let tileBottom = center.y + geometry.tileSize.height / 2
                #expect(tileBottom <= size.height - clearance + 0.001)
            }
            let dragged = geometry.clamped(CGPoint(x: 0, y: 10000))
            #expect(dragged.y + geometry.tileSize.height / 2 <= size.height - clearance + 0.001)
        }
    }

    @Test(
        "Local mute is drawn on self-view and remote mute is drawn on the remote tile",
        arguments: [true, false])
    func microphoneIndicatorsStayOnTheirParticipant(localMuted: Bool) throws {
        let size = CGSize(width: 390, height: 720)
        let participants = [
            UIParticipant(
                participant: makeMockParticipant(
                    id: "self", isMicEnabled: !localMuted, isCameraEnabled: false, isRemote: false
                )),
            UIParticipant(
                participant: makeMockParticipant(
                    id: "remote", isMicEnabled: localMuted, isCameraEnabled: false
                )),
        ]
        let content = MeetingRoomContent(participants: participants, layout: .grid, activeSpeakerId: nil)
            .frame(width: size.width, height: size.height)
            .preferredColorScheme(.dark)
        let image = try #require(ImageRenderer(content: content).cgImage)
        let local = participants[0].videoDimensions
        let geometry = FloatingSelfViewGeometry(
            container: size, bottomInset: 0, videoAspectRatio: local.width / local.height
        )
        let localCenter = geometry.center(for: .bottomRight)
        let localIcon = CGRect(
            x: localCenter.x + geometry.tileSize.width / 2 - 48,
            y: localCenter.y - geometry.tileSize.height / 2,
            width: 48,
            height: 48
        )
        let remoteIcon = CGRect(x: size.width - 48, y: 0, width: 48, height: 48)
        #expect(try containsMutedIcon(image, region: localIcon) == localMuted)
        #expect(try containsMutedIcon(image, region: remoteIcon) == !localMuted)
    }

    private func containsMutedIcon(_ image: CGImage, region: CGRect) throws -> Bool {
        let crop = try #require(image.cropping(to: region))
        let rowBytes = crop.width * 4
        var pixels = [UInt8](repeating: 0, count: rowBytes * crop.height)
        return try pixels.withUnsafeMutableBytes { buffer in
            let context = try #require(
                CGContext(
                    data: buffer.baseAddress,
                    width: crop.width,
                    height: crop.height,
                    bitsPerComponent: 8,
                    bytesPerRow: rowBytes,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
                ))
            context.draw(crop, in: CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
            // The muted glyph uses theme.error; the neutral background and enabled mic do not.
            return stride(from: 0, to: buffer.count, by: 4).filter { index in
                let red = Int(buffer[index])
                return red > 100 && red > Int(buffer[index + 1]) * 3 / 2
                    && red > Int(buffer[index + 2]) * 3 / 2
            }.count > 5
        }
    }

    @Test("Dragging beyond the edges remains clamped and hiding controls preserves the chosen corner")
    func clampingAndControls() {
        let size = CGSize(width: 390, height: 720)
        let visible = FloatingSelfViewGeometry(container: size, bottomInset: 64)
        let hidden = FloatingSelfViewGeometry(container: size, bottomInset: 0)
        #expect(visible.clamped(CGPoint(x: -1000, y: -1000)) == visible.center(for: .topLeft))
        #expect(visible.clamped(CGPoint(x: 10000, y: 10000)) == visible.center(for: .bottomRight))
        #expect(hidden.center(for: .bottomRight).y > visible.center(for: .bottomRight).y)
        #expect(hidden.nearestCorner(to: hidden.center(for: .topLeft)) == .topLeft)
    }
}
