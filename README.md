# peek. — Focus flow milestone (iOS SwiftUI)

This repository contains a SwiftUI iOS app source tree, an XcodeGen project specification (`project.yml`) and an unsigned Codemagic compile-check workflow (`codemagic.yaml`).

## Improvements in this version
- Resume an active focus session from Home or Modes after navigating away or relaunching.
- Session clock uses wall-clock time; active session start and distraction state persist across app restarts.
- Log manual distractions with categories: other app, call, phone unlock or other reason.
- When peek. comes back to the foreground, present the time away for **manual classification**. Never claim the cause is automatically detected.
- Journal now lists recorded distraction reasons and durations; unclassified away time is excluded from the displayed focus time.
- Block starting a second session while another is active.

## iPhone-only build check via Codemagic
1. Upload **contents of this folder** to the root of the `Peek-prerelease` GitHub repository. The `Peek/Sources` folder hierarchy must be retained; delete older root-level Swift files to avoid confusion.
2. Connect the GitHub repository in Codemagic. Choose config from `codemagic.yaml` and workflow `ios-compile-check`.
3. Launch the workflow for `main`; inspect the compile log artifact.
4. This workflow compiles an **unsigned simulator** app. It is **not** an installable iPhone IPA. Actual phone installation requires provisioning/signing and a distribution method such as TestFlight.

## System limitations
- iOS does not let ordinary apps inspect every unlock, phone call, or foreground app transition. Current automatic sensing only detects **peek. itself entering and leaving background**, not what happened outside.
- The reason for time away is entered by the user. App tracking by Screen Time requires FamilyControls / DeviceActivity extensions, entitlements and user approval. `OptionalScreenTime` is intentionally excluded from the current compile-check target.
- Steps are demo values, not HealthKit integration.
- No Live Activity / Dynamic Island is included in this milestone.

## Local validation
Swift frontend syntax parsing performed on all `Peek/Sources/*.swift`. Full iOS SDK compilation requires Xcode/Codemagic and has not yet been verified.
