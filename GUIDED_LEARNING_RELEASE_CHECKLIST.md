# Guided Learning — Your Release Checklist

> **For:** Jirka
> **What this covers:** everything you personally need to do when the dev work (see `GUIDED_LEARNING_DEV_PLAN.md`) is ready — App Store Connect config, testing, legal copy, submission.
> **What this does NOT cover:** the code implementation. Claude Code handles that separately from the dev plan.

---

## Quick summary of what's new in this version

You're adding a third monetization tier called **Průvodce** (Guided Learning):
- **Subscription:** 79 Kč/month or 690 Kč/year (7-day free trial on both)
- **Lives alongside** existing freemium + 3,99 $ one-time unlock (does not replace either)
- **Adds:** adaptive difficulty per operation, daily 3-session plan, scaffolded hints in challenge mode, weekly parent report
- **Entry points:** new "Průvodce" card on home screen + row in Settings

---

## 1. Before you touch App Store Connect

- [ ] Pull the branch Claude Code worked on
- [ ] Build and run on a physical device (not just simulator) — StoreKit sandbox behaves differently on real hardware
- [ ] Verify on existing installs: users who own the 3,99 $ unlock still have everything they had before (every operation, challenge, print/scan). This is the #1 regression risk.
- [ ] Verify existing free users: addition still free, dashboard still visible, dinosaur theme still works
- [ ] Check that the new "Průvodce" card appears for everyone in locked state

---

## 2. App Store Connect — Subscription setup

Do this in App Store Connect → your app → Monetization → Subscriptions.

- [ ] **Create a Subscription Group** named `Guided Learning` (internal name) / `Průvodce` (display name — this is what users see in Settings > Apple ID > Subscriptions)
- [ ] **Add the monthly product:**
  - Product ID: `com.countwithkids.guided.monthly`
  - Duration: 1 month
  - Price: 79 Kč (CZK tier — check the exact tier Apple maps this to; adjust if within ±5 Kč)
  - Localized display name (cs): `Průvodce – měsíčně`
  - Localized display name (en): `Guide – monthly`
  - Localized display name (he): `מדריך – חודשי`
  - Introductory offer: 7-day free trial, new subscribers only
  - Subscription description (per locale) — 1–2 sentences about what it includes
- [ ] **Add the yearly product:**
  - Product ID: `com.countwithkids.guided.yearly`
  - Duration: 1 year
  - Price: 690 Kč
  - Localized display names (cs/en/he): `Průvodce – ročně` / `Guide – yearly` / `מדריך – שנתי`
  - Introductory offer: 7-day free trial, new subscribers only
- [ ] Upload a **promotional image** for the subscription group (1024×1024, optional but helps conversion)
- [ ] Fill in the **Review Information** box for each subscription — Apple reviewers read this. Mention that this is additive to the existing one-time unlock.
- [ ] Set **Tax Category** to "App Store Software" (default — confirm)

---

## 3. Legal & disclosure updates

Apple rejects subscription apps that omit these. Check each carefully.

- [ ] **Privacy Policy** — update `docs/privacy.html` to mention:
  - Subscription status is synced via Apple's StoreKit (no personal data sent to your servers unless you added a backend)
  - Weekly report notifications use local device data only
- [ ] **Terms of Service** — if you don't have one, Apple's standard EULA suffices. If you do (check `docs/` for any terms doc), update it to mention the subscription.
- [ ] **Update both links in the paywall.** Claude Code adds the link slots; you confirm the URLs point to live pages.
- [ ] Verify the Czech paywall disclosure copy reads exactly:
  > "Obnovuje se automaticky. Zrušit lze kdykoli v Nastavení Apple ID. 7 dní zdarma, pak 79 Kč/měsíc. Navíc k jednorázovému odemčení — nenahrazuje ho."
- [ ] Verify English + Hebrew equivalents are present

---

## 4. Sandbox testing

You need a sandbox tester account for this. Create one in App Store Connect → Users & Access → Sandbox Testers if you don't have one already.

**Remember:** sandbox uses accelerated time — 1 month of subscription = 5 minutes in sandbox. 1 year = ~1 hour. Plan your test session accordingly.

### Happy path
- [ ] Fresh install, no entitlements → open app → tap Průvodce card → paywall opens → subscribe monthly → paywall closes → Průvodce card now shows active state
- [ ] Confirm free trial language appears correctly ("7 dní zdarma")
- [ ] Confirm settings toggle defaulted to ON after purchase
- [ ] Confirm onboarding sheet appeared once

### Entitlement edge cases
- [ ] Subscribe → wait 5 min for sandbox to auto-renew → confirm access is retained
- [ ] Subscribe → cancel from Settings > Apple ID > Subscriptions (sandbox) → wait for expiry → confirm Průvodce card locks again on next launch
- [ ] Subscribe → force refund in Sandbox → confirm access revokes on next launch
- [ ] Grace period: cancel in sandbox, kill the app, launch → confirm access is retained during grace period
- [ ] Restore Purchases on a fresh install with active subscription → confirm access restored

### Coexistence with 3,99 $
- [ ] User who owns ONLY 3,99 $ unlock → Průvodce card shows locked → all other paid features still work
- [ ] User who owns BOTH → everything unlocked, both tiers visible in Settings
- [ ] Subscribe without owning 3,99 $ → Průvodce works, but challenge/print/scan still locked (correct behavior — the tiers are independent)

### Upgrade/downgrade
- [ ] Subscribe monthly → upgrade to yearly via App Store subscription management → confirm no double-charge, access retained
- [ ] Subscribe yearly → downgrade to monthly → confirm change takes effect at renewal, not immediately

### Offline / re-launch
- [ ] Subscribe, turn off WiFi, kill app, relaunch → Průvodce should still work (StoreKit 2 caches entitlements locally)
- [ ] Fresh install, no network → paywall should show a friendly error, not crash

---

## 5. Feature testing (non-StoreKit)

With a force-unlocked build (debug flag), verify the Guided mode end-to-end:

- [ ] Daily plan shows 3 cards on first launch
- [ ] Completing all 3 increments the daily-plan streak
- [ ] Level advancement: complete 3 clean sheets at a given level → kid advances, celebration shows
- [ ] Level drop: complete 2 rough sessions → kid steps back one level
- [ ] Scaffolded hints: stall 5s/10s/20s in challenge mode → three different hint tiers appear
- [ ] Weekly parent report: triggers Sunday at 19:00 (force it via debug menu to verify copy + chart)
- [ ] Theme compatibility: toggle between dinosaur, unicorn, penguin, lion → GuidedHomeView looks right in each
- [ ] Dark mode: entire Guided flow works in dark mode
- [ ] iPad: layouts don't break on iPad screens
- [ ] All three languages: switch between cs/en/he → no missing strings, Hebrew RTL works

---

## 6. App Store listing updates

- [ ] **Screenshots:** add at least 2 new screenshots per device class showing Guided mode (home card, daily plan, mastery map). Replace or augment current screenshots.
- [ ] **App description (cs/en/he):** add a paragraph about Průvodce. Template:
  > "**Nové: Průvodce (předplatné)** — adaptivní výuka, která se přizpůsobuje úrovni vašeho dítěte. Každý den 3 nachystané úlohy. Vyzkoušejte 7 dní zdarma."
- [ ] **What's New (version release notes):** Czech + English + Hebrew
- [ ] **Keywords:** consider adding: `adaptivní, předplatné, denní plán, guided, adaptive, daily plan`
- [ ] **Preview video:** if you have the bandwidth, update the App Preview video to include a Průvodce shot — not required for submission

---

## 7. Build version

- [ ] Bump version in `project.yml` (currently likely 2.x — go to 3.0 given the scope of this release)
- [ ] Bump build number
- [ ] Update `AppStoreTexts.md` with new version notes
- [ ] Archive in Xcode → upload to App Store Connect
- [ ] Wait for processing (15–30 min typically)

---

## 8. Submission

- [ ] **Submit for Review** with both new subscription products attached to the version
- [ ] In the "App Review Information" notes field, tell Apple:
  > "This version introduces a new subscription tier called Průvodce (Guided Learning). It is **additive** to the existing one-time 3,99 $ unlock — it does not replace it. Both monetization options coexist. Test account with active subscription not needed; sandbox will work."
- [ ] Expect 24–48h review time. Subscriptions sometimes get extra scrutiny — if rejected, 90% of the time it's about missing disclosure copy on the paywall. Check Section 3 first.

---

## 9. Post-launch (first 2 weeks)

- [ ] Watch App Store Connect → Subscriptions → Trial conversions. Target is ≥ 30% trial-to-paid.
- [ ] Watch churn in month 2. If > 40%, the weekly parent report or the daily plan may not be producing enough perceived value — revisit with Claude.
- [ ] Watch support emails for confusion between 3,99 $ and subscription — that's the most likely user confusion vector.
- [ ] Respond to early reviews about the new tier within 48h. Parents talk; early reviews set the tone.

---

## 10. Nice-to-have for v1.1 (don't ship in v1.0)

Keep these in a backlog. Resist adding them before launch.

- Multiple child profiles
- Error-type classification ("conceptual vs. careless")
- Recommendations engine
- Streak freezes
- Family Sharing for subscriptions (Apple supports this — you just enable it, but verify it doesn't complicate entitlement logic in edge cases)
- Parent email digest (web-hosted, not just in-app)

---

## Questions to answer before you ship

Things I (Claude) can't decide for you. Write your answers here when you come back:

- [ ] Is Family Sharing enabled for the subscription? (yes = wider reach, no = simpler entitlement code)
- [ ] First-month promo pricing? (e.g., 19 Kč first month) — Apple supports this but it adds complexity
- [ ] Should Czech users see CZK and international users see USD? (App Store does this automatically if pricing tiers are set correctly — verify)
- [ ] Who translates the new Czech copy to English and Hebrew? (keep the same translator as previous versions for consistency)
