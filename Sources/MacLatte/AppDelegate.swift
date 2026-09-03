import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let power = PowerManager.shared

    private var expiryDate: Date?
    private var expiryTimer: Timer?
    private var countdownTimer: Timer?

    private let awakeSymbol = "cup.and.saucer.fill"
    private let idleSymbol = "cup.and.saucer"

    private let durations: [(title: String, seconds: TimeInterval)] = [
        ("For 15 Minutes", 15 * 60),
        ("For 30 Minutes", 30 * 60),
        ("For 1 Hour", 60 * 60),
        ("For 2 Hours", 2 * 60 * 60),
        ("For 4 Hours", 4 * 60 * 60),
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        refreshUI()
    }

    func applicationWillTerminate(_ notification: Notification) {
        power.stop()
    }

    // MARK: - Actions

    @objc private func toggleIndefinite() {
        if power.isActive {
            stopKeepingAwake()
        } else {
            clearTimer()
            power.start()
            startCountdown()
        }
        refreshUI()
    }

    @objc private func startTimed(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? TimeInterval else { return }
        beginTimed(seconds: seconds)
    }

    @objc private func startCustomTimer() {
        let alert = NSAlert()
        alert.messageText = "Custom Timer"
        alert.informativeText = "Keep the Mac awake for how many minutes?"
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = "60"
        alert.accessoryView = input

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn,
           let minutes = Double(input.stringValue), minutes > 0 {
            beginTimed(seconds: minutes * 60)
        }
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.isEnabled.toggle()
        refreshUI()
    }

    @objc private func quit() {
        power.stop()
        NSApp.terminate(nil)
    }

    // MARK: - Core logic

    private func beginTimed(seconds: TimeInterval) {
        clearTimer()
        power.start()
        expiryDate = Date().addingTimeInterval(seconds)
        expiryTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.stopKeepingAwake()
        }
        startCountdown()
        refreshUI()
    }

    private func stopKeepingAwake() {
        power.stop()
        clearTimer()
        refreshUI()
    }

    private func clearTimer() {
        expiryTimer?.invalidate()
        expiryTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        expiryDate = nil
    }

    private func startCountdown() {
        countdownTimer?.invalidate()
        guard expiryDate != nil else { return }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateStatusItemAppearance()
        }
    }

    // MARK: - UI

    private func refreshUI() {
        updateStatusItemAppearance()
        statusItem.menu = buildMenu()
    }

    private func updateStatusItemAppearance() {
        guard let button = statusItem.button else { return }

        let symbolName = power.isActive ? awakeSymbol : idleSymbol
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "MacLatte")
        image?.isTemplate = true
        button.image = image

        if power.isActive, let expiryDate {
            let remaining = max(0, Int(expiryDate.timeIntervalSinceNow))
            if remaining == 0 {
                button.title = ""
            } else {
                button.title = " " + formatRemaining(remaining)
            }
        } else {
            button.title = ""
        }
    }

    private func formatRemaining(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let statusLabel = NSMenuItem(title: power.isActive ? "Awake — Mac will not sleep" : "Sleep is allowed", action: nil, keyEquivalent: "")
        statusLabel.isEnabled = false
        menu.addItem(statusLabel)
        menu.addItem(.separator())

        let toggleTitle = power.isActive ? "Turn Off" : "Keep Awake Indefinitely"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleIndefinite), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.state = (power.isActive && expiryDate == nil) ? .on : .off
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        for duration in durations {
            let item = NSMenuItem(title: duration.title, action: #selector(startTimed(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = duration.seconds
            item.state = (power.isActive && expiryDate != nil && abs(expiryDate!.timeIntervalSinceNow - duration.seconds) < 1) ? .on : .off
            menu.addItem(item)
        }

        let customItem = NSMenuItem(title: "Custom Timer…", action: #selector(startCustomTimer), keyEquivalent: "")
        customItem.target = self
        menu.addItem(customItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit MacLatte", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }
}
