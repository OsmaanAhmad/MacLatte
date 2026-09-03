import AppKit
import Combine

struct TimerPreset: Identifiable {
    let id = UUID()
    let label: String
    let seconds: TimeInterval
}

/// Drives the keep-awake state machine and publishes it for the SwiftUI popover.
final class KeepAwakeController: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var isIndefinite = false
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var totalSeconds: TimeInterval = 0
    @Published var customMinutes: Double = 60
    @Published var launchAtLoginEnabled: Bool = LaunchAtLogin.isEnabled

    /// Called whenever state changes, so the status bar item can refresh its icon/title.
    var onUpdate: (() -> Void)?

    let presets: [TimerPreset] = [
        TimerPreset(label: "15m", seconds: 15 * 60),
        TimerPreset(label: "30m", seconds: 30 * 60),
        TimerPreset(label: "1h", seconds: 60 * 60),
        TimerPreset(label: "2h", seconds: 2 * 60 * 60),
        TimerPreset(label: "4h", seconds: 4 * 60 * 60),
    ]

    private let power = PowerManager.shared
    private var expiryDate: Date?
    private var expiryTimer: Timer?
    private var countdownTimer: Timer?

    func toggleIndefinite() {
        isActive ? stop() : beginIndefinite()
    }

    func beginIndefinite() {
        clearTimer()
        power.start()
        isActive = true
        isIndefinite = true
        remainingSeconds = 0
        totalSeconds = 0
        onUpdate?()
    }

    func start(seconds: TimeInterval) {
        clearTimer()
        power.start()
        isActive = true
        isIndefinite = false
        totalSeconds = seconds
        let expiry = Date().addingTimeInterval(seconds)
        expiryDate = expiry
        remainingSeconds = Int(seconds)

        expiryTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.stop()
        }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        onUpdate?()
    }

    func startCustom() {
        start(seconds: customMinutes * 60)
    }

    func stop() {
        power.stop()
        clearTimer()
        isActive = false
        isIndefinite = false
        remainingSeconds = 0
        totalSeconds = 0
        onUpdate?()
    }

    func toggleLaunchAtLogin() {
        LaunchAtLogin.isEnabled.toggle()
        launchAtLoginEnabled = LaunchAtLogin.isEnabled
    }

    func quit() {
        power.stop()
        NSApplication.shared.terminate(nil)
    }

    var progressFraction: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / totalSeconds
    }

    var statusText: String {
        if isIndefinite { return "Awake indefinitely" }
        if isActive { return "Awake — \(formattedRemaining) remaining" }
        return "Sleep is allowed"
    }

    var formattedRemaining: String {
        let h = remainingSeconds / 3600
        let m = (remainingSeconds % 3600) / 60
        let s = remainingSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    private func tick() {
        guard let expiryDate else { return }
        remainingSeconds = max(0, Int(expiryDate.timeIntervalSinceNow))
        onUpdate?()
    }

    private func clearTimer() {
        expiryTimer?.invalidate()
        expiryTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        expiryDate = nil
    }
}
