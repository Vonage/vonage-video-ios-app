//
//  Created by Vonage on 10/06/2026.
//

import Foundation
import Observation
import VERACommonUI
import VERADomain

enum FeedbackFormConstants {
    static let maxStandardFieldChars = 100
    static let maxDescriptionChars = 1000
}

@MainActor
@Observable
class FeedbackFormViewModel {

    static let titleKey = "Title"
    static let titleFieldText = "When you noticed this issue, what were you trying to do?"
    static let nameKey = "Name"
    static let nameFieldText = "Tell us your name"
    static let descriptionKey = "Description"
    static let descriptionFieldText = "Describe your issue"
    static let infoKey = "Info"
    static let infoFieldText = "Please do not include any sensitive information."
    static let imageKey = "Image"
    static let imageFieldText = "A screenshot will help us better understand the issue. (optional)"

    static var formTitle: String {
        String(
            localized: "Report issue", bundle: AppLanguageStore.shared.localizedBundle(in: .module),
            locale: AppLanguageStore.shared.locale)
    }

    var title: String { Self.formTitle }
    var isLoading = false
    var toast: ToastItem?
    var feedbackResult: FeedbackReportResult?
    var showValidationErrors = false
    var feedbackFields = [
        FeedbackFieldViewModel(
            maxChars: FeedbackFormConstants.maxStandardFieldChars,
            title: titleFieldText,
            key: titleKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: FeedbackFormConstants.maxStandardFieldChars,
            title: nameFieldText,
            key: nameKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            maxChars: FeedbackFormConstants.maxDescriptionChars,
            title: descriptionFieldText,
            key: descriptionKey,
            type: .text
        ),
        FeedbackFieldViewModel(
            title: "",
            key: infoKey,
            type: .info,
            value: infoFieldText,
            isRequired: false
        ),
        FeedbackFieldViewModel(
            title: "",
            key: imageKey,
            type: .image,
            value: imageFieldText,
            isRequired: false
        ),
    ]

    @ObservationIgnored
    private let feedbackReportUseCase: FeedbackReportUseCase
    @ObservationIgnored
    private let sessionDebugInfoProvider: () -> FeedbackSessionDebugInfo

    init(
        feedbackReportUseCase: FeedbackReportUseCase,
        sessionDebugInfoProvider: @escaping () -> FeedbackSessionDebugInfo = { .empty }
    ) {
        self.feedbackReportUseCase = feedbackReportUseCase
        self.sessionDebugInfoProvider = sessionDebugInfoProvider
    }

    var isValid: Bool {
        feedbackFields.allSatisfy(\.isValid)
    }

    func debugDump() -> String {
        FeedbackDebugDumpBuilder.debugDump(session: sessionDebugInfoProvider())
    }

    func onSubmit() {
        showValidationErrors = true
        guard isValid else { return }

        Task { @MainActor in
            await submitReport()
        }
    }

    @MainActor
    private func submitReport() async {
        isLoading = true
        defer {
            isLoading = false
        }
        do {
            feedbackResult = try await feedbackReportUseCase(
                .init(
                    title: fieldValue(
                        forKey: Self.titleKey),
                    name: fieldValue(
                        forKey: Self.nameKey),
                    issue: fieldValue(
                        forKey: Self.descriptionKey),
                    image: imageField()?.attachedImage,
                    debugDump: debugDump()
                )
            )
        } catch {
            toast = .init(
                message: String(
                    localized: "Something failed, please try again",
                    bundle: AppLanguageStore.shared.localizedBundle(in: .module),
                    locale: AppLanguageStore.shared.locale), mode: .failure)
        }
    }

    private func fieldValue(forKey key: String) -> String {
        feedbackFields.first { $0.key == key }?.value.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func imageField() -> FeedbackFieldViewModel? {
        feedbackFields.first { $0.type == .image }
    }
}
