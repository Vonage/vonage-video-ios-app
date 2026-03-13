//
//  Created by Vonage on 12/3/26.
//

#if DEBUG
    import Foundation
    import SwiftUI
    import VERADomain

    extension NoiseSuppressionViewModel {

        /// Preview instance with noise suppression disabled
        static var previewDisabled: WaittingNoiseSuppressionViewModel {
            let viewModel = WaittingNoiseSuppressionViewModel(
                getCurrentPublisher: { throw NSError(domain: "Preview", code: 0) },
                disableNoiseSuppresionUseCase: PreviewDisableNoiseSuppresionUseCase(),
                enableNoiseSuppresionUseCase: PreviewEnableNoiseSuppresionUseCase()
            )
            viewModel.state = .disabled
            return viewModel
        }

        /// Preview instance with noise suppression enabled
        static var previewEnabled: WaittingNoiseSuppressionViewModel {
            let viewModel = WaittingNoiseSuppressionViewModel(
                getCurrentPublisher: { throw NSError(domain: "Preview", code: 0) },
                disableNoiseSuppresionUseCase: PreviewDisableNoiseSuppresionUseCase(),
                enableNoiseSuppresionUseCase: PreviewEnableNoiseSuppresionUseCase()
            )
            viewModel.state = .enabled
            return viewModel
        }

        /// Preview instance with noise suppression disabled
        static var meetingPreviewDisabled: MeetingNoiseSuppressionViewModel {
            let viewModel = MeetingNoiseSuppressionViewModel(
                getCurrentPublisher: PreviewPublisherRepository().getPublisher,
                disableNoiseSuppresionUseCase: PreviewDisableNoiseSuppresionUseCase(),
                enableNoiseSuppresionUseCase: PreviewEnableNoiseSuppresionUseCase()
            )
            viewModel.state = .disabled
            return viewModel
        }

        /// Preview instance with noise suppression enabled
        static var meetingPreviewEnabled: MeetingNoiseSuppressionViewModel {
            let viewModel = MeetingNoiseSuppressionViewModel(
                getCurrentPublisher: PreviewPublisherRepository().getPublisher,
                disableNoiseSuppresionUseCase: PreviewDisableNoiseSuppresionUseCase(),
                enableNoiseSuppresionUseCase: PreviewEnableNoiseSuppresionUseCase()
            )
            viewModel.state = .enabled
            return viewModel
        }
    }

    private final class PreviewEnableNoiseSuppresionUseCase: EnableNoiseSuppresionUseCase {
        func callAsFunction(publisher: any VERADomain.VERAPublisher) {}
    }

    private final class PreviewDisableNoiseSuppresionUseCase: DisableNoiseSuppresionUseCase {
        func callAsFunction() {}
    }

    private final class PreviewPublisherRepository: PublisherRepository {

        public init() {}

        func getPublisher() throws -> any VERAPublisher {
            EmptyVERAPublisher()
        }

        func resetPublisher() {}

        func recreatePublisher(_ settings: PublisherSettings) throws {}
    }

    private final class EmptyVERAPublisher: VERAPublisher {
        var view: AnyView

        var publishAudio: Bool

        var publishVideo: Bool

        var cameraPosition: CameraPosition

        var videoTransformers: [any VERATransformer]

        var audioTransformers: [any VERATransformer]

        var transformerFactory: any VERATransformerFactory

        public init() {
            self.view = AnyView(EmptyView())
            self.publishAudio = true
            self.publishVideo = true
            self.cameraPosition = .front
            self.videoTransformers = []
            self.audioTransformers = []
            self.transformerFactory = PreviewVERATransformerFactory()
        }

        func switchCamera(to cameraDeviceID: String) {}

        func cleanUp() {}

        func addVideoTransformer(_ transformer: any VERADomain.VERATransformer) {}

        func setVideoTransformers(_ transformers: [any VERADomain.VERATransformer]) {}

        func removeTransformer(_ key: String) {}

        func addAudioTransformer(_ transformer: any VERADomain.VERATransformer) {}

        func setAudioTransformers(_ transformers: [any VERADomain.VERATransformer]) {}

        func removeAudioTransformer(_ key: String) {}
    }

    private final class PreviewVERATransformerFactory: VERATransformerFactory {

        public init() {}

        func makeTransformer(for key: String, params: String) throws -> any VERATransformer {
            throw NSError(domain: "test", code: 0, userInfo: nil)
        }

        func makeAudioTransformer(for key: String, params: String) throws -> any VERATransformer {
            throw NSError(domain: "test", code: 0, userInfo: nil)
        }
    }
#endif
