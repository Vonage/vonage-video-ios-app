//
//  Created by Vonage on 06/07/26.
//

#if canImport(UIKit)
    import SwiftUI
    import VERACommonUI

    /// Bottom sheet presenting audio output testing controls.
    ///
    /// This view displays an audio output selector and a test button to verify
    /// the selected audio device is working correctly. It can be presented as a sheet
    /// from any screen (Waiting Room, Meeting Room, etc.).
    ///
    /// Matches the style of other bottom sheets like VideoEffectsSheet.
    public struct AudioDiagnosticsView: View {

        @ObservedObject var viewModel: AudioOutputControlViewModel

        public init(viewModel: AudioOutputControlViewModel) {
            self.viewModel = viewModel
        }

        public var body: some View {
            VStack {
                DragIndicatorView()

                ScrollView {
                    VStack(spacing: 24) {
                        // Instructions
                        VStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)

                            Text("Audio Output Test", bundle: .module)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(VERACommonUIAsset.SemanticColors.onBackground.swiftUIColor)

                            Text(
                                "Select your audio output device and tap Play to verify it is working correctly.",
                                bundle: .module
                            )
                            .font(.body)
                            .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        }
                        .padding(.top, 16)

                        // Audio control panel
                        AudioOutputControlPanel(viewModel: viewModel)
                            .padding(.horizontal, 4)
                    }
                    .padding(.bottom, 8)
                }
                .background(VERACommonUIAsset.SemanticColors.background.swiftUIColor)
            }
            .onDisappear {
                viewModel.stopSpeaker()
            }
        }
    }

    // MARK: - Previews

    #if DEBUG
        struct AudioDiagnosticsView_Previews: PreviewProvider {
            static var previews: some View {
                AudioDiagnosticsView(
                    viewModel: AudioOutputControlViewModel(speakerTestService: NullSpeakerTestService())
                )
                .preferredColorScheme(.dark)
            }
        }
    #endif

#endif
