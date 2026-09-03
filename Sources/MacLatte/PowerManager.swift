import Foundation
import IOKit.pwr_mgt

/// Wraps an IOKit power management assertion, the same mechanism `caffeinate` uses
/// to prevent the display and system from sleeping.
final class PowerManager {
    static let shared = PowerManager()

    private var assertionID: IOPMAssertionID = 0
    private(set) var isActive = false

    private init() {}

    @discardableResult
    func start(reason: String = "MacLatte keep-awake enabled") -> Bool {
        guard !isActive else { return true }

        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )

        isActive = result == kIOReturnSuccess
        return isActive
    }

    func stop() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        isActive = false
    }
}
