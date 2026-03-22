import Foundation

/// A simple debouncer that delays execution until a quiet period elapses.
/// Each call to `schedule` resets the timer. When no new calls arrive within `delay`,
/// the latest action runs.
///
/// Usage:
///   let debouncer = Debouncer(delay: 0.3)
///   debouncer.schedule { /* do work */ }
final class Debouncer {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delay: TimeInterval

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    /// Schedule an action to run after the debounce delay.
    /// If called again before the delay elapses, the previous action is canceled.
    func schedule(_ action: @escaping () -> Void) {
        workItem?.cancel()
        let item = DispatchWorkItem(block: action)
        workItem = item
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }

    /// Cancel any scheduled action.
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

/// A throttler that ensures actions run at most once per interval.
/// If multiple calls occur during the interval, the latest is saved and executed once the window ends.
///
/// Usage:
///   let throttler = Throttler(interval: 0.5)
///   throttler.run { /* do work */ }
final class Throttler {
    private let queue: DispatchQueue
    private let interval: TimeInterval
    private var isThrottling = false
    private var pendingWork: (() -> Void)?

    init(interval: TimeInterval, queue: DispatchQueue = .main) {
        self.interval = interval
        self.queue = queue
    }

    /// Run the action respecting the throttle interval.
    /// If already throttling, the latest action is stored and executed when the window ends.
    func run(_ action: @escaping () -> Void) {
        if isThrottling {
            pendingWork = action
            return
        }

        isThrottling = true
        action()

        queue.asyncAfter(deadline: .now() + interval) { [weak self] in
            guard let self = self else { return }
            self.isThrottling = false

            if let work = self.pendingWork {
                self.pendingWork = nil
                self.run(work)
            }
        }
    }

    /// Cancel any pending work and reset throttling state.
    func cancel() {
        pendingWork = nil
        isThrottling = false
    }
}

// Example integration ideas:
// - Debounce map camera idle events before firing network requests.
// - Debounce text field changes before running a search.
// - Throttle frequent button taps or sensor updates to a reasonable rate.
