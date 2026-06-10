//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI
import UIKit

struct LimitedMultilineTextView: View {
    @Binding var text: String
    let minLines: Int
    let maxLines: Int
    let maxCharacters: Int?
    let lineHeight: CGFloat

    @State private var height: CGFloat

    init(
        text: Binding<String>,
        minLines: Int,
        maxLines: Int,
        maxCharacters: Int?,
        lineHeight: CGFloat = 22
    ) {
        _text = text
        self.minLines = minLines
        self.maxLines = maxLines
        self.maxCharacters = maxCharacters
        self.lineHeight = lineHeight
        _height = State(initialValue: Self.containerHeight(lineHeight: lineHeight, lines: minLines))
    }

    var body: some View {
        LimitedMultilineTextViewRepresentable(
            text: $text,
            minLines: minLines,
            maxLines: maxLines,
            maxCharacters: maxCharacters,
            lineHeight: lineHeight,
            height: $height
        )
        .frame(height: height)
    }

    private static func containerHeight(lineHeight: CGFloat, lines: Int) -> CGFloat {
        lineHeight * CGFloat(lines) + Layout.verticalInset
    }

    private enum Layout {
        static let verticalInset: CGFloat = 16
    }
}

private struct LimitedMultilineTextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    let minLines: Int
    let maxLines: Int
    let maxCharacters: Int?
    let lineHeight: CGFloat
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> LimitedMultilineTextContainer {
        let container = LimitedMultilineTextContainer()
        container.backgroundColor = .clear
        container.setContentHuggingPriority(.required, for: .vertical)
        container.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        container.onLayout = { [weak coordinator = context.coordinator] in
            coordinator?.updateHeight()
        }

        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        Self.configureKeyboard(for: textView)
        textView.text = text
        textView.translatesAutoresizingMaskIntoConstraints = false
        context.coordinator.configureKeyboardAccessory(for: textView)
        container.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: container.topAnchor),
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        context.coordinator.textView = textView
        context.coordinator.container = container
        return container
    }

    func updateUIView(_ uiView: LimitedMultilineTextContainer, context: Context) {
        context.coordinator.parent = self
        uiView.onLayout = { [weak coordinator = context.coordinator] in
            coordinator?.updateHeight()
        }

        guard let textView = context.coordinator.textView else { return }
        if textView.text != text {
            textView.text = text
        }
        context.coordinator.updateHeight()
    }

    private static func configureKeyboard(for textView: UITextView) {
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.inputAssistantItem.leadingBarButtonGroups = []
        textView.inputAssistantItem.trailingBarButtonGroups = []
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: LimitedMultilineTextViewRepresentable
        weak var textView: UITextView?
        weak var container: LimitedMultilineTextContainer?
        var keyboardAccessoryHostingController: UIHostingController<FeedbackKeyboardDoneToolbar>?

        init(parent: LimitedMultilineTextViewRepresentable) {
            self.parent = parent
        }

        func configureKeyboardAccessory(for textView: UITextView) {
            let hostingController = FeedbackKeyboardDoneAccessory.makeHostingController { [weak self] in
                self?.textView?.resignFirstResponder()
            }
            keyboardAccessoryHostingController = hostingController
            textView.inputAccessoryView = hostingController.view
        }

        func textViewDidChange(_ textView: UITextView) {
            let clamped = Self.clamping(
                textView.text ?? "",
                maxLines: parent.maxLines,
                maxCharacters: parent.maxCharacters
            )
            if textView.text != clamped {
                textView.text = clamped
            }
            if parent.text != clamped {
                parent.text = clamped
            }
            updateHeight()
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText: String
        ) -> Bool {
            let current = textView.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return false }
            let updated = current.replacingCharacters(in: swiftRange, with: replacementText)

            if let maxCharacters = parent.maxCharacters, updated.count > maxCharacters {
                return false
            }
            return Self.lineCount(in: updated) <= parent.maxLines
        }

        func updateHeight() {
            guard let textView, let container else { return }

            let width = container.bounds.width
            guard width > 0 else { return }

            let contentSize = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            let minHeight = parent.lineHeight * CGFloat(parent.minLines) + Layout.verticalInset
            let maxHeight = parent.lineHeight * CGFloat(parent.maxLines) + Layout.verticalInset
            let fittingHeight = min(max(contentSize.height, minHeight), maxHeight)

            if parent.height != fittingHeight {
                parent.height = fittingHeight
            }
            textView.isScrollEnabled = contentSize.height > maxHeight
        }

        private static func lineCount(in text: String) -> Int {
            guard !text.isEmpty else { return 1 }
            return text.components(separatedBy: "\n").count
        }

        private static func clamping(_ text: String, maxLines: Int, maxCharacters: Int?) -> String {
            var result = text
            let lines = result.components(separatedBy: "\n")
            if lines.count > maxLines {
                result = lines.prefix(maxLines).joined(separator: "\n")
            }
            if let maxCharacters, result.count > maxCharacters {
                result = String(result.prefix(maxCharacters))
            }
            return result
        }

        private enum Layout {
            static let verticalInset: CGFloat = 16
        }
    }
}

private final class LimitedMultilineTextContainer: UIView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}
