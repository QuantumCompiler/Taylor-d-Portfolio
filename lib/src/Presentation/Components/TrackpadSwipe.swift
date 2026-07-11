//
//  TrackpadSwipe.swift
//  Taylor'd Portfolio
//
//  Presentation · Components — respond to two-finger trackpad swipes (no click).
//

import SwiftUI
import AppKit

extension View {
    /// Lets the view respond to a **two-finger trackpad swipe** (horizontal scroll)
    /// without a click-drag. `onChanged` reports the live horizontal translation (in
    /// points, positive = swiping right); `onEnded` reports the final translation when
    /// the fingers lift. Vertical scrolls pass straight through, so an inner `ScrollView`
    /// keeps working. No-op (and installs nothing) when `isEnabled` is false.
    func trackpadSwipe(
        isEnabled: Bool = true,
        onChanged: @escaping (CGFloat) -> Void,
        onEnded: @escaping (CGFloat) -> Void
    ) -> some View {
        background {
            if isEnabled {
                TrackpadSwipeCatcher(onChanged: onChanged, onEnded: onEnded)
                    .allowsHitTesting(false)
            }
        }
    }
}

/// Installs a local scroll-wheel monitor for its lifetime and forwards **horizontally
/// dominant, precise (trackpad)** scroll gestures as a swipe. The empty `NSView` is just
/// a lifecycle anchor — the work happens in the monitor, so nothing is drawn or hit-tested.
private struct TrackpadSwipeCatcher: NSViewRepresentable {
    var onChanged: (CGFloat) -> Void
    var onEnded: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onChanged: onChanged, onEnded: onEnded) }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.install()
        return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.remove()
    }

    final class Coordinator {
        var onChanged: (CGFloat) -> Void
        var onEnded: (CGFloat) -> Void

        private var monitor: Any?
        private var translation: CGFloat = 0
        /// Whether the in-flight gesture has been claimed as a horizontal swipe (so we keep
        /// consuming it); a gesture that starts vertical is never claimed and passes through.
        private var claimed = false

        init(onChanged: @escaping (CGFloat) -> Void, onEnded: @escaping (CGFloat) -> Void) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        func install() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handle(event) ?? event
            }
        }

        func remove() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }

        /// Returns `nil` to consume the event (it's part of a horizontal swipe) or the event
        /// itself to let it flow on (vertical scroll, momentum, or a plain mouse wheel).
        private func handle(_ event: NSEvent) -> NSEvent? {
            guard event.hasPreciseScrollingDeltas else { return event }   // trackpad only

            let phase = event.phase
            if phase.contains(.began) {
                translation = 0
                claimed = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY)
                guard claimed else { return event }
                accumulate(event)
                return nil
            } else if phase.contains(.changed) {
                if !claimed {
                    // The gesture began ambiguous/vertical — only claim it once the
                    // horizontal component clearly dominates.
                    guard abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) else { return event }
                    claimed = true
                }
                accumulate(event)
                return nil
            } else if phase.contains(.ended) || phase.contains(.cancelled) {
                let wasClaimed = claimed
                if wasClaimed { onEnded(translation) }
                translation = 0
                claimed = false
                return wasClaimed ? nil : event
            }
            return event   // momentum / stationary / mouse wheel → not our gesture
        }

        private func accumulate(_ event: NSEvent) {
            translation += event.scrollingDeltaX
            onChanged(translation)
        }
    }
}
