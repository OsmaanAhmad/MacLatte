import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let controller = KeepAwakeController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self

        let hostingController = NSHostingController(rootView: ContentView(controller: controller))
        hostingController.sizingOptions = [.preferredContentSize]

        popover.behavior = .transient
        popover.contentViewController = hostingController
        // NSHostingController reports a zero-sized preferredContentSize until it has
        // gone through a layout pass. Without this, the popover shows at that zero
        // size first and grows upward once SwiftUI lays out, ending up overlapping
        // the menu bar with no arrow. Forcing fittingSize here measures the SwiftUI
        // content synchronously so the popover is positioned correctly from frame one.
        popover.contentSize = hostingController.view.fittingSize

        controller.onUpdate = { [weak self] in self?.updateStatusItemAppearance() }
        updateStatusItemAppearance()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.stop()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Activate before showing: SwiftUI's Material only renders its vibrant
            // blur once its window is key. Activating after show() left the popover
            // non-key for its first frame, so it appeared flat/opaque until a click
            // made the window key and the material caught up.
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateStatusItemAppearance() {
        guard let button = statusItem.button else { return }

        let symbolName = controller.isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "MacLatte")
        image?.isTemplate = true
        button.image = image

        if controller.isActive && !controller.isIndefinite {
            button.title = " " + controller.formattedRemaining
        } else {
            button.title = ""
        }
    }
}
