# App Store Submission Checklist — Count with Kids

## Prerequisites

- [X] **Enroll in Apple Developer Program** ($99/year) at [developer.apple.com](https://developer.apple.com)
- [X] **Note your Team ID** — 7PL4QQ4G6R
- [X] **Replace placeholder Team ID** in `project.yml` and `fastlane/Appfile`

## App Store Connect Setup

- [ ] **Register Bundle ID** `com.countwithkids.app` in Certificates, Identifiers & Profiles
- [ ] **Create App Record** in App Store Connect
  - Platform: iOS
  - Name: Count with Kids
  - Primary Language: English (U.S.)
  - Bundle ID: com.countwithkids.app
  - SKU: countwithkids

## App Configuration

- [ ] **Set Pricing** — Paid, Tier 1 ($0.99)
- [ ] **Set Age Rating** — 4+ (no objectionable content)
- [ ] **Set Category** — Primary: Education, Secondary: Games (optional)
- [ ] **Export Compliance** — "No" to encryption (app uses no encryption)

## App Icon

- [X] **Design app icon** — 1024x1024px PNG, no alpha/transparency
  - Kid-friendly math concept (numbers, +/- symbols)
  - Dinosaur theme colors (teal #1ABC9C, coral #FF6B6B, cream #FFF9F0)
  - Rounded, playful style
- [X] **Place** `AppIcon.png` in `CountWithKids/Resources/Assets.xcassets/AppIcon.appiconset/`

## Screenshots

- [ ] **Capture screenshots** for iPhone 16 Pro Max (6.9") and iPhone 15 Pro Max (6.7")
- [ ] **Three locales** — en-US, cs, he
- [ ] **Suggested screens:** Settings (theme picker), Practice (in progress), Dashboard (with data), Results (clean sheet)
- [ ] **Upload** via Fastlane (`fastlane screenshots`) or manually in App Store Connect

## Metadata

- [X] **Verify all metadata files** in `fastlane/metadata/` for en-US, cs, and he
- [ ] **Update placeholder URLs** in `privacy_url.txt` and `support_url.txt`

## Privacy

- [ ] **Host privacy policy** at a public URL (GitHub Pages recommended)
- [ ] **Update** `fastlane/metadata/en-US/privacy_url.txt` with the real URL
- [ ] **App Privacy section** in App Store Connect — select "Data Not Collected"

## Signing & Build

- [X] **Configure signing** in Xcode — Automatic, Team 7PL4QQ4G6R
- [X] **Verify** project builds successfully
- [ ] **Test on real device**
- [ ] **Archive** via Xcode (Product > Archive) or `fastlane build`
- [ ] **Upload** via Xcode Organizer or `fastlane beta` (TestFlight) / `fastlane release` (App Store)

## TestFlight (Recommended)

- [ ] **Upload build** to TestFlight via `fastlane beta`
- [ ] **Test on real devices** — verify all 3 themes, all 3 languages, dashboard, timer
- [ ] **Add external testers** if desired

## Final Submission

- [ ] **Select build** in App Store Connect
- [ ] **Review all metadata** — name, subtitle, description, keywords in all locales
- [ ] **Verify screenshots** display correctly for all devices and locales
- [ ] **Submit for Review**
- [ ] **Monitor review status** — typical review takes 24-48 hours

## Post-Launch

- [ ] **Monitor Crash Reports** in App Store Connect
- [ ] **Respond to reviews** if applicable
- [ ] **Plan updates** based on user feedback
