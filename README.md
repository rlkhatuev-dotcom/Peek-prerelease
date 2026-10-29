# peek. — iOS native prototype, distraction-control milestone

## Installation (Mac + Xcode required)
1. Create a SwiftUI iOS app in Xcode, deployment target iOS 17+.
2. Replace generated app sources with the five `.swift` files in this folder; add them to the app target.
3. For `ScreenTimeAccess.swift`, enable the Family Controls capability/entitlement in Signing & Capabilities. Apple approval and correct provisioning may be required; without it, exclude this optional file and remove the `NavigationLink("Настроить Screen Time")` line from ContentView.swift.
4. Run on an iPhone and grant notifications and, if supported, Screen Time permission.

## What works in this source
- Wall-clock focus and manual distraction timers, local JSON persistence, active session recovery.
- Foreground/background lifecycle detection: after returning to peek., elapsed time away is shown for confirmation. The app **does not** claim it knows whether that interval was a call, lock screen, or another app.
- A Screen Time permission request and system app-selection picker are provided as an **integration starting point**, not full automatic app-usage tracking.
- Finance, journal, demo steps, separate mode settings.

## Not implemented
- Real-time detection of every other app opened, unlocks, or cellular calls. iOS does not expose a universal event stream for this.
- DeviceActivity Monitor extension, Screen Time usage thresholds and reports, Live Activity/Widget extension, HealthKit step data.
- iOS build/device tests: Xcode and iOS SDK unavailable in this environment.

## Verification
Swift sources syntax-parsed with Linux swiftc; this does not type-check Apple frameworks or verify iOS compilation.
