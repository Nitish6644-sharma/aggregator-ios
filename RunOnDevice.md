# Running AggregatorBuddy on your iPhone

Notes for keeping the app on your personal iPhone. This project is signed with a
**free Apple ID ("Personal Team")**, which is fine for personal use but has a
**7-day expiry**.

## First-time setup (already done)
1. iPhone on iOS 17+, **Developer Mode** on (Settings → Privacy & Security → Developer Mode).
2. Xcode → project → **Signing & Capabilities**: "Automatically manage signing" on, Team = your Personal Team, for **both** targets (app + share extension).
3. Connect iPhone via USB, select it as the run destination, press **Run (▶)**.
4. On the phone, trust the developer cert once:
   **Settings → General → VPN & Device Management → [Apple Development: …] → Trust.**

## The 7-day renewal (the recurring bit)
Apps signed with a free account stop launching after ~7 days ("app cannot be
opened" / crashes on launch). To renew for another 7 days:

1. Connect the iPhone to the Mac (USB).
2. Open `AggregatorBuddy.xcodeproj` in Xcode.
3. Select your iPhone as the destination.
4. Press **Run (▶)**.

That reinstalls a freshly-signed build and resets the 7-day clock.

- ✅ **Do NOT delete the app** when it expires — just re-run. Your saved links
  persist as long as the app stays installed.
- Between renewals you can use the app fully **without** the Mac connected.
- You normally won't need to re-trust the certificate each time (only if the
  cert changes).

## Want it to last a year instead of 7 days?
Enroll in the **Apple Developer Program** ($99/year). Then builds last a year
and you skip the weekly renewal. Nothing in the code needs to change — just the
account type in signing.

## Troubleshooting
- **"Untrusted Developer" on launch** → re-do the Trust step above.
- **App Groups / provisioning error after connecting device** → make sure both
  targets use the same Team; press "Try Again" in Signing & Capabilities.
- **Extension not showing in the share sheet** → open the main app once after
  installing, then try sharing again.
