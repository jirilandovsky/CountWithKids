# StoreKit Testing Checklist — Count with Kids v2.0

The `Configuration.storekit` file lives at the project root and is wired into the `CountWithKids` scheme's Run action. Building + running will use it automatically.

---

## 1. First launch (fresh install, no purchase)

- [X] Xcode → **Product → Clean Build Folder** (⇧⌘K)
- [X] Run on an iOS 17+ simulator
- [X] Erase the simulator: **Device → Erase All Content and Settings** (ensures SwiftData starts empty so `isUnlocked = false`)
- [X] Launch app — free tier UI visible:
  - [X] Only `+` operation toggle is active; `−`, `×`, `÷` show lock overlay
  - [X] Counting range picker shows only "To 10" / "To 20"
  - [X] "Larger ranges (to 100, 1000)" locked row visible
  - [X] Examples per page stepper greyed out
  - [X] Deadline stepper greyed out
  - [X] Penguin theme NOT in theme picker; "Penguin theme" locked row visible
  - [X] "Unlock full version $3.99" section visible at top of Settings
  - [X] Practice screen: Print and Scan buttons show lock icon

## 2. Paywall entry points

Tap each and confirm the paywall sheet appears:

- [X] Settings → "Unlock full version" row
- [X] Settings → Counting range "Larger ranges" locked row
- [X] Settings → `−` operation toggle
- [X] Settings → `×` operation toggle
- [X] Settings → `÷` operation toggle
- [X] Settings → "Penguin theme" locked row
- [X] Practice → tap mascot (Challenge entry)
- [X] Practice → Print button
- [X] Practice → Scan button

## 3. Purchase flow

- [X] From any paywall, tap **"Unlock for $3.99"**
- [X] Confirm the StoreKit test dialog → "Purchase"
- [X] Paywall sheet auto-dismisses
- [X] Settings now shows **"Full version unlocked"** (green checkmark)
- [X] All previously-locked features now enabled:
  - X ] `−`, `×`, `÷` operation toggles work
  - [X] Range picker shows 10 / 20 / 100 / 1000
  - [X] Examples per page stepper works
  - [X] Deadline stepper works
  - [X] Penguin theme appears in theme picker
  - [X] Print / Scan buttons lose lock icon
  - [X] Mascot tap opens Challenge (not paywall)

## 4. Restore flow

- [X] In Xcode, open `Configuration.storekit` → **Editor → Delete All Transactions**
- [X] Kill and relaunch the app — `isUnlocked` still `true` (local SwiftData flag, expected)
- [X] Erase the simulator (Device → Erase All Content and Settings)
- [X] Reinstall the app — free tier again
- [X] Settings → tap **Restore Purchases**
- [ ] App re-unlocks automatically via `Transaction.currentEntitlements`
- [ ] Settings shows "Full version unlocked"

## 5. Legacy customer path (v1.x → v2.0 auto-unlock)

This tests that existing paying users of the $1 app get full access automatically.

- [ ] With the app running in Xcode, open `Configuration.storekit`
- [ ] Find **App Transaction** settings (⚙️ gear icon in editor top-right, or **Editor** menu while .storekit file is active)
- [ ] Set:
  - [ ] **Application Version:** `2.0`
  - [ ] **Original Application Version:** `1.4.1` (or any 1.x)
  - [ ] **Original Purchase Date:** any past date
- [ ] **Editor → Delete All Transactions** (clear any leftover unlock purchase)
- [ ] Erase the simulator + reinstall the app
- [ ] On first launch: `StoreManager.checkLegacyPurchase()` reads `originalAppVersion = "1.4.1"`, parses major = 1, sees `1 < 2`, auto-unlocks
- [ ] App launches already in unlocked state — no paywall anywhere
- [ ] Settings shows "Full version unlocked"

## 6. Reverse test — new user on v2+

- [ ] In `Configuration.storekit`, change **Original Application Version** to `2.0`
- [ ] **Editor → Delete All Transactions**
- [ ] Erase simulator + reinstall
- [ ] Expect free tier — all paywalls active (legacy path should NOT trigger because `2 < 2` is false)

---

## Important notes

- `AppTransaction` legacy testing **only works with Xcode's StoreKit configuration file** — not TestFlight sandbox. Must test in the simulator.
- The "App Transaction" / "Edit Default App Version" menu location varies by Xcode version. Look for a gear icon in the `.storekit` editor toolbar, or the **Editor** menu while the `.storekit` file is the active document.
- If `AppTransaction.shared` throws in test mode, the legacy check silently ignores the error. If legacy unlock doesn't happen, add a breakpoint in `checkLegacyPurchase()` in `StoreManager.swift`.

## If something doesn't work

Most likely failure modes:

1. **Product doesn't load** (price stays as "$3.99" fallback placeholder)
   → Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration should show `Configuration.storekit`

2. **Paywall doesn't dismiss after purchase**
   → `.onChange(of: settings.isUnlocked)` in `PaywallView` should fire. Verify `StoreManager` is receiving the same `AppSettings` instance via `store.start(settings:)` in `ContentView.onAppear`.

3. **Legacy unlock doesn't trigger**
   → Most likely the default app version in `.storekit` is still `1.0` so it looks "legacy" by default, or `AppTransaction` throws because the config isn't fully set up. Check the Xcode console log on app launch.

---

## Pre-flight checklist before submitting to App Store

- [ ] Create the IAP in App Store Connect: non-consumable, product ID `com.countwithkids.fullunlock`, price tier **$3.99**, **Family Sharing enabled**
- [ ] Change app from Paid to Free in App Store Connect
- [ ] Version set to **2.0** (already done in pbxproj + Settings About section)
- [ ] New screenshots if any show locked features as freely available
- [ ] Updated app description mentioning one-time unlock
