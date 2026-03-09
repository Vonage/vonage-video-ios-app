//
//  Created by Vonage on 16/02/2026.
//

import SwiftUI

/// Animation constants for the balloon-rise effect.
enum BalloonAnimationConstants {
    /// Duration of the spring inflate animation (seconds).
    static let inflateDuration: Double = 0.4

    /// Duration of the linear upward rise (seconds).
    static let riseDuration: Double = 5.0

    /// Duration of the final shrink-and-fade-out (seconds).
    static let shrinkDuration: Double = 1.2

    /// Total animation duration from inflate to fully faded out (seconds).
    ///
    /// The shrink phase overlaps with the end of the rise, so the total
    /// equals the point at which the shrink completes:
    /// `inflateDuration * 0.5 + riseDuration`.
    static let totalDuration: Double = inflateDuration * 0.5 + riseDuration

    /// Ratio of the container height the emoji travels upward.
    ///
    /// The emoji starts at 85 % of the container height, so `0.85`
    /// makes it rise from its starting position to the top edge.
    static let travelDistanceRatio: CGFloat = 0.85

    /// Initial scale factor before the inflate phase.
    static let startScale: CGFloat = 0.1

    /// Scale factor after the inflate phase completes.
    static let fullScale: CGFloat = 1.0

    /// Scale factor at the end of the shrink phase.
    static let endScale: CGFloat = 0.0

    /// Horizontal sway amplitude in each direction (points).
    static let swayAmount: CGFloat = 18

    /// Duration for one full sway cycle, left → right → left (seconds).
    static let swayDuration: Double = 2.0

    /// Maximum rotation angle during sway (degrees).
    static let swayRotation: Double = 10
}

/// A `ViewModifier` that applies a balloon-rise animation to a view.
///
/// The animation progresses through three sequential phases:
///
/// 1. **Inflate** – springs from a small scale to full size.
/// 2. **Rise & sway** – floats upward linearly while oscillating
///    horizontally with a slight rotation tilt.
/// 3. **Shrink & fade** – scales down and fades out near the top.
private struct BalloonAnimationModifier: ViewModifier {

    let containerHeight: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isInflated = false
    @State private var isRising = false
    @State private var isShrinking = false
    @State private var isSwayingRight = false

    // Reduce Motion: simple fade in → fade out
    @State private var isVisible = false
    @State private var isFadingOut = false

    /// Vertical distance derived from the container height.
    private var travelDistance: CGFloat {
        containerHeight * BalloonAnimationConstants.travelDistanceRatio
    }

    func body(content: Content) -> some View {
        if reduceMotion {
            reducedMotionBody(content: content)
        } else {
            fullAnimationBody(content: content)
        }
    }

    // MARK: - Reduced Motion

    /// A simplified animation that fades in and then fades out,
    /// respecting the user's Reduce Motion accessibility setting.
    @ViewBuilder
    private func reducedMotionBody(content: Content) -> some View {
        content
            .opacity(isFadingOut ? 0 : (isVisible ? 1 : 0))
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    isVisible = true
                }
                let fadeOutDelay = BalloonAnimationConstants.totalDuration - 1.0
                withAnimation(.easeOut(duration: 1.0).delay(fadeOutDelay)) {
                    isFadingOut = true
                }
            }
    }

    // MARK: - Full Animation

    @ViewBuilder
    private func fullAnimationBody(content: Content) -> some View {
        content
            .scaleEffect(currentScale)
            .opacity(isShrinking ? 0 : 1)
            .offset(
                x: isSwayingRight ? BalloonAnimationConstants.swayAmount : -BalloonAnimationConstants.swayAmount,
                y: isRising ? -travelDistance : 0
            )
            .rotationEffect(
                .degrees(
                    isSwayingRight ? BalloonAnimationConstants.swayRotation : -BalloonAnimationConstants.swayRotation)
            )
            .onAppear {
                // Phase 1: Inflate like a balloon with spring bounce
                withAnimation(.spring(response: BalloonAnimationConstants.inflateDuration, dampingFraction: 0.6)) {
                    isInflated = true
                }

                // Continuous sway: slow repeating left-right oscillation
                withAnimation(
                    .easeInOut(duration: BalloonAnimationConstants.swayDuration)
                        .repeatForever(autoreverses: true)
                ) {
                    isSwayingRight = true
                }

                // Phase 2: Float upward at constant slow speed
                withAnimation(
                    .linear(duration: BalloonAnimationConstants.riseDuration)
                        .delay(BalloonAnimationConstants.inflateDuration * 0.5)
                ) {
                    isRising = true
                }

                // Phase 3: Shrink and fade as it reaches the top
                let shrinkDelay =
                    BalloonAnimationConstants.inflateDuration * 0.5
                    + BalloonAnimationConstants.riseDuration
                    - BalloonAnimationConstants.shrinkDuration
                withAnimation(
                    .easeIn(duration: BalloonAnimationConstants.shrinkDuration)
                        .delay(shrinkDelay)
                ) {
                    isShrinking = true
                }
            }
    }

    private var currentScale: CGFloat {
        if isShrinking {
            return BalloonAnimationConstants.endScale
        } else if isInflated {
            return BalloonAnimationConstants.fullScale
        } else {
            return BalloonAnimationConstants.startScale
        }
    }
}

extension FloatingEmojiView {

    /// Applies the balloon-rise animation to this emoji view.
    ///
    /// - Parameter containerHeight: The height of the overlay container,
    ///   used to calculate travel distance.
    /// - Returns: A view with the balloon animation applied.
    func balloonAnimation(containerHeight: CGFloat) -> some View {
        modifier(BalloonAnimationModifier(containerHeight: containerHeight))
    }
}
