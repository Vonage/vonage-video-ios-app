//
//  Created by Vonage on 17/10/26.
//

import SwiftUI
import VERACommonUI

/// The audio-first On-the-Go call screen.
///
/// Portrait: title + Exit pill, active-speaker line, big mic toggle filling the
/// remaining space, optional shared-content row, and a bottom bar with the
/// audio-route picker and Leave. Landscape (compact vertical size class):
/// info/actions column on the left, mic toggle on the right.
public struct OnTheGoView: View {

    @Environment(\.meetingRoomTheme) private var theme
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @Bindable private var viewModel: OnTheGoViewModel

    public init(viewModel: OnTheGoViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if verticalSizeClass == .compact {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .accessibilityIdentifier(OnTheGoAccessibilityID.screen)
        .onChange(of: viewModel.snapshot.isMicEnabled) { _, isMicEnabled in
            announceMicChange(isMicEnabled)
        }
        .sheet(isPresented: sharedContentBinding) {
            OnTheGoSharedContentSheet(viewModel: viewModel)
        }
    }

    // MARK: - Portrait

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("On-the-Go".localized)
                        .font(.title3.weight(.semibold))
                    Text("%lld participants".localized(args: viewModel.snapshot.participantCount))
                        .font(.footnote)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                exitButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)

            activeSpeakerLine
                .padding(.horizontal, 20)
                .padding(.top, 16)

            OnTheGoMuteButton(isMicEnabled: viewModel.snapshot.isMicEnabled) {
                viewModel.toggleMic()
            }
            .padding(20)

            if viewModel.snapshot.screenShareParticipant != nil {
                sharedContentRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }

            bottomBar
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
        }
    }

    // MARK: - Landscape

    private var landscapeLayout: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 0) {
                Text("On-the-Go".localized)
                    .font(.title3.weight(.semibold))
                Text("%lld participants".localized(args: viewModel.snapshot.participantCount))
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)

                activeSpeakerLine
                    .padding(.top, 12)

                Spacer(minLength: 0)

                if viewModel.snapshot.screenShareParticipant != nil {
                    sharedContentRow
                        .padding(.bottom, 10)
                }

                VStack(spacing: 10) {
                    audioRouteButton
                    leaveButton
                }
            }
            .frame(width: 220)

            ZStack(alignment: .topTrailing) {
                OnTheGoMuteButton(isMicEnabled: viewModel.snapshot.isMicEnabled) {
                    viewModel.toggleMic()
                }
                exitButton
                    .background(Color.black.opacity(0.25), in: Capsule())
                    .padding(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    // MARK: - Subviews

    private var exitButton: some View {
        Button(action: viewModel.exit) {
            HStack(spacing: 6) {
                Image(systemName: "xmark")
                Text("Exit".localized)
            }
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .overlay(
                Capsule().strokeBorder(Color.primary, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.primary)
        .accessibilityIdentifier(OnTheGoAccessibilityID.exitButton)
        .accessibilityLabel("Exit On-the-Go mode".localized)
    }

    private var activeSpeakerLine: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.snapshot.activeSpeakerName == nil ? Color.gray : theme.success)
                .frame(width: 9, height: 9)
                .shadow(
                    color: viewModel.snapshot.activeSpeakerName == nil
                        ? .clear : theme.success.opacity(0.4),
                    radius: 4
                )
            if let speaker = viewModel.snapshot.activeSpeakerName {
                Text("%@ is speaking".localized(args: speaker))
                    .font(.callout)
            } else {
                Text("No one is speaking".localized)
                    .font(.callout)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityIdentifier(OnTheGoAccessibilityID.activeSpeakerLabel)
        .accessibilityElement(children: .combine)
    }

    private var sharedContentRow: some View {
        Button(action: viewModel.presentSharedContent) {
            HStack(spacing: 8) {
                VERACommonUIAsset.Images.screenShareSolid.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
                Text("View shared content".localized)
                    .font(.subheadline.weight(.semibold))
                Text("LIVE".localized)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.error, in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(theme.onError)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.primary)
        .background(theme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).strokeBorder(theme.primary, lineWidth: 1)
        )
        .accessibilityIdentifier(OnTheGoAccessibilityID.sharedContentButton)
        .accessibilityLabel("View shared content".localized)
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            audioRouteButton
            leaveButton
        }
    }

    private var audioRouteButton: some View {
        HStack(spacing: 8) {
            #if canImport(UIKit)
                AudioRoutePickerView.button(size: 24, iconColor: .label)
            #endif
            Text("Speaker".localized)
                .font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(theme.vGray4, in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(theme.textSecondary)
        .accessibilityIdentifier(OnTheGoAccessibilityID.audioRouteButton)
        .accessibilityLabel("Audio route picker".localized)
    }

    private var leaveButton: some View {
        Button(action: viewModel.leaveCall) {
            HStack(spacing: 8) {
                VERACommonUIAsset.Images.endCallSolid.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
                Text("Leave".localized)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.onError)
        .background(theme.error, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier(OnTheGoAccessibilityID.leaveButton)
        .accessibilityLabel("Leave call".localized)
    }

    // MARK: - Helpers

    private var sharedContentBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isSharedContentPresented },
            set: { if !$0 { viewModel.dismissSharedContent() } }
        )
    }

    private func announceMicChange(_ isMicEnabled: Bool) {
        guard viewModel.state == .active else { return }
        #if canImport(UIKit)
            UIAccessibility.post(
                notification: .announcement,
                argument: isMicEnabled
                    ? "Microphone is on".localized
                    : "Microphone is off".localized
            )
        #endif
    }
}

#if DEBUG
    #Preview("Mic on") {
        OnTheGoView(viewModel: .preview())
    }

    #Preview("Muted + share") {
        OnTheGoView(viewModel: .preview(isMicEnabled: false, withScreenShare: true))
    }
#endif
