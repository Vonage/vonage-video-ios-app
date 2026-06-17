import SwiftUI
import VERADomain

/// A reusable modifier that shows a `ToastView` when the provided binding becomes non-nil.
///
/// Behavior:
/// - When `toast` transitions to a non-nil value the modifier animates the toast into view.
/// - After `visibleDuration` seconds the toast is animated out and, after `resetDelay` seconds
///   from the initial showing, the binding is set back to nil.
public struct ToastModifier: ViewModifier {
    @Binding private var toast: ToastItem?
    private let visibleDuration: TimeInterval
    private let resetDelay: TimeInterval
    private let placement: Edge
    private let verticalPadding: CGFloat?

    @State private var showToast: Bool = false

    /// Create a ToastModifier.
    /// - Parameters:
    ///   - toast: Binding to optional `ToastItem` that drives the toast visibility and content.
    ///   - visibleDuration: How long the toast stays visible before hiding animation starts (default 3s).
    ///   - resetDelay: How long after initial show the binding will be set to nil (default 4.5s).
    ///   - placement: Edge where the toast should appear (.top or .bottom). Default .top.
    ///   - verticalPadding: Additional padding from the safe area on the selected edge.
    public init(
        toast: Binding<ToastItem?>,
        visibleDuration: TimeInterval = 3,
        resetDelay: TimeInterval = 4.5,
        placement: Edge = .top,
        verticalPadding: CGFloat? = nil
    ) {
        self._toast = toast
        self.visibleDuration = visibleDuration
        self.resetDelay = resetDelay
        self.placement = placement
        self.verticalPadding = verticalPadding
    }

    public func body(content: Content) -> some View {
        let alignment: Alignment = (placement == .top) ? .top : .bottom

        ZStack(alignment: alignment) {
            content
            if showToast, let item = toast {
                ToastView(item: item)
                    .transition(.move(edge: placement).combined(with: .opacity))
                    .padding(.horizontal, 12)
                    .padding(placement == .top ? .top : .bottom, verticalPadding ?? 8)
            }
        }
        .onChange(of: toast) { newToast in
            if newToast != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showToast = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + visibleDuration) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showToast = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + (resetDelay - visibleDuration)) {
                        DispatchQueue.main.async {
                            _toast.wrappedValue = nil
                        }
                    }
                }
            }
        }
    }
}

public extension View {
    /// Attach a toast to the view.
    ///
    /// Example:
    ///     .toast(toast: $viewModel.toast)
    func toast(
        toast: Binding<ToastItem?>,
        visibleDuration: TimeInterval = 3,
        resetDelay: TimeInterval = 4.5,
        placement: Edge = .top,
        verticalPadding: CGFloat? = nil
    ) -> some View {
        modifier(ToastModifier(
            toast: toast,
            visibleDuration: visibleDuration,
            resetDelay: resetDelay,
            placement: placement,
            verticalPadding: verticalPadding
        ))
    }
}
