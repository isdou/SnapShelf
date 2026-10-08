import AppKit
import ZancunjiaCore

/// macOS does not post a notification when another app copies an image,
/// so the shelf polls the general pasteboard's change count.
@MainActor
final class ClipboardMonitor {
    private let model: ShelfModel
    private var timer: Timer?
    private var sleepObservers: [NSObjectProtocol] = []
    private var isEnabled = false
    private var pendingTasks: [UUID: Task<Void, Never>] = [:]

    init(model: ShelfModel) {
        self.model = model
    }

    func start(enabled: Bool) {
        isEnabled = enabled
        if enabled { startTimer() }
        installSleepObservers()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            model.suppressPasteboard(changeCount: NSPasteboard.general.changeCount)
            startTimer()
        } else {
            stopTimer()
            cancelPendingTasks()
        }
    }

    func stop() {
        isEnabled = false
        stopTimer()
        cancelPendingTasks()
        removeSleepObservers()
    }

    private func cancelPendingTasks() {
        for task in pendingTasks.values { task.cancel() }
        pendingTasks.removeAll()
    }

    private func startTimer() {
        guard timer == nil else { return }
        poll()
        let timer = Timer(timeInterval: 0.3, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func installSleepObservers() {
        guard sleepObservers.isEmpty else { return }
        let center = NSWorkspace.shared.notificationCenter
        let sleepObs = center.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.stopTimer()
            }
        }
        let wakeObs = center.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard self?.isEnabled == true else { return }
                self?.startTimer()
            }
        }
        sleepObservers = [sleepObs, wakeObs]
    }

    private func removeSleepObservers() {
        let center = NSWorkspace.shared.notificationCenter
        for obs in sleepObservers {
            center.removeObserver(obs)
        }
        sleepObservers.removeAll()
    }

    private func poll() {
        guard isEnabled else { return }
        let pasteboard = NSPasteboard.general
        guard model.claimPasteboard(changeCount: pasteboard.changeCount) else { return }
        let id = UUID()
        pendingTasks[id] = Task { [weak self] in
            guard let self else { return }
            defer { pendingTasks.removeValue(forKey: id) }
            let payloads = await ClipboardReader.readMedia(from: pasteboard)
            guard isEnabled, !Task.isCancelled, !payloads.isEmpty else { return }
            await model.importMedia(payloads)
        }
    }
}
