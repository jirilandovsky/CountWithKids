# Guided Learning Tier — Development Plan

> **Audience:** future Claude Code session (or any dev agent) picking this up cold.
> **Written:** 2026-04-22 after product-alignment conversation with Jirka.
> **Goal:** ship a third monetization tier called **"Průvodce"** (Guided Learning) alongside the existing freemium + 3,99 $ unlock. Subscription-based. Must not break or replace either existing tier.

---

## 0. Before you start

**Re-read this file in full.** It contains all product decisions already made. Do not re-litigate them with Jirka unless you find a concrete blocker.

**Verify the codebase state first.** Line numbers below were captured on 2026-04-22 and will drift. Run a fresh `Explore` pass on the files listed in Section 5 before editing them. Suggested invocation:

> Agent tool, subagent_type=Explore (thoroughness=medium): "Locate current state of `StoreManager.swift`, `AppSettings.swift`, `ProblemGenerator.swift`, `PracticeView.swift`, `PaywallView.swift`, `PracticeSession.swift`, `DashboardAggregator.swift`, `StreakCalculator.swift`. Report: current line ranges of key functions, any new models added since 2026-04-22, any changes to SwiftData schema."

**Language:** app is Czech-first with English and Hebrew localizations. Every user-facing string must exist in all three. Check the existing Localizable strings files for naming conventions before adding new keys.

---

## 1. Product decisions (already made — do not revisit)

| Decision | Value |
|---|---|
| Tier name (cs) | Průvodce |
| Tier name (en) | Guide / Guided Learning |
| Pricing model | Subscription (monthly + yearly) |
| Monthly price | 79 Kč (~$2.99) |
| Yearly price | 690 Kč (~$27) |
| Free trial | 7 days |
| Relationship to 3,99 $ unlock | **Additive, not replacement.** Paywall must state this explicitly. |
| Home screen entry | A "Průvodce" card visible to ALL users (locked state if not subscribed). Primary subscribe entry point. |
| Settings entry | "Subscribe" row before purchase; after purchase, becomes "Guided Mode toggle (on/off)" + "Manage subscription" link. |
| First-subscribe UX | Guided toggle defaults **ON** after subscription activates. One-time onboarding sheet: "Průvodce je zapnutý. Vypnout můžete v Nastavení." |
| Free-practice mode | Untouched. Continues to exist side-by-side. |
| Child profiles | **Not in v1.** Single profile. |
| Error classification | **Not in v1.** |
| Curriculum alignment | **Not in v1.** |
| LLM features | **Not in v1.** |

---

## 2. Feature scope (v1)

Four features make up the tier. They ship together.

### 2.1 Adaptive difficulty per operation (the core)
- New SwiftData model: `MasteryProgress` (one row per operation: `+`, `−`, `×`, `÷`).
- Fields: `operation: String`, `level: Int (1–10)`, `consecutiveCleanSheets: Int`, `consecutiveRoughSessions: Int`, `lastPracticedAt: Date`.
- Level ladder (appendix A for starter values — finalize in Task 1.1).
- Advancement rule: 3 consecutive clean sheets at current level → level +1. 2 sessions with 3+ errors → level −1. Floor at 1, ceiling at 10.
- `ProblemGenerator` gets a new overload: `generate(for operation: String, level: Int) -> [Problem]` that maps level → range + constraints (e.g., with/without carrying).
- Regular free-practice generator stays unchanged.

### 2.2 Daily plan
- 3 cards shown on the guided home page: **Warmup**, **Focus**, **Challenge**.
- `DailyPlanBuilder` (pure function) takes: `[MasteryProgress]`, recent `PracticeSession`s, today's date → returns 3 session configs.
  - **Warmup**: kid's strongest operation, one level below current (build confidence).
  - **Focus**: kid's weakest operation at current level.
  - **Challenge**: mixed-operation set at median level across unlocked ops.
- Completion state persists per day. Completing all 3 increments a **daily-plan streak** (distinct from existing clean-sheet streak).
- Skippable. No dark-pattern guilt copy.

### 2.3 Scaffolded hints in mascot challenge
- **Only in challenge mode, not in regular practice.** Keeps the drill experience pure.
- If kid stalls 5+ seconds on a problem, mascot speech bubble rotates:
  - **5s:** generic nudge ("Tak co, zkusíme to?")
  - **10s:** operation-specific strategy ("Zkus počítat po desítkách.")
  - **20s:** worked example ("8 + 8 = 16, takže 8 + 7 = ?")
- No time penalty. No scoring impact. Keep the vibe light.
- Strategy/example strings live in a new `HintLibrary` keyed by `(operation, level, problemShape)`. Start narrow — 20–30 hints covering the common cases — don't over-build.

### 2.4 Weekly parent report
- Triggered on Sunday evening (local time) via a local notification.
- Tap → in-app card with 3 Czech sentences + 1 chart.
- Template: "Tento týden [jméno | "Vaše dítě"] zvládl/a [X] čistých sérií. Nejvíc se zlepšil/a v [operaci]. Teď pracuje na [další cíl]."
- Chart: weekly clean sheets per operation, stacked bars.
- Single screen. No navigation further. Minimum viable.

---

## 3. Out of scope (v1) — resist scope creep

Do **not** implement any of these even if they seem small. Each is a separate product decision.
- Multiple child profiles / per-kid mastery
- Error-type classification (conceptual vs. careless)
- Teacher/parent dashboard web version
- Recommendations engine beyond Daily Plan
- Difficulty scaling within a single session (only between sessions)
- Hints in regular practice mode
- Cross-device sync of mastery progress beyond iCloud default
- Streak freezes / streak protection
- Badges beyond existing trophies
- Any LLM / AI-generated content

---

## 4. Build sequence (phased)

Each phase ends in a runnable, testable state. Do not merge phases together — they're sized for independent verification.

### Phase 1 — Mastery engine (behind a compile-time flag)
**Goal:** adaptive generator works in isolation. No UI yet.

- **Task 1.1: Design level ladder.** Agent: Plan (subagent_type=Plan).
  Prompt: "Design a 10-level ladder for each of +, −, ×, ÷ for Czech children aged 6–10. Each level must define: max operand, min operand, special constraints (e.g., 'no carrying', 'no borrowing', 'divisor ≤ 5'). Output as a Swift struct or dictionary. Target: level 1 trivial, level 10 = Czech 2nd-grade mastery. Use appendix A as a starting point and refine."
  DoD: `LevelLadder.swift` committed with a reviewable table of constraints.

- **Task 1.2: Add `MasteryProgress` SwiftData model.** Direct implementation.
  Files: new `CountWithKids/Models/MasteryProgress.swift`. Add to `ModelContainer` schema registration (find it near the App's `@main`).
  DoD: model compiles, app launches without migration errors on an existing install.

- **Task 1.3: Extend `ProblemGenerator`.** Direct implementation.
  Add `generate(for operation: String, level: Int, count: Int) -> [Problem]` that reads `LevelLadder` and reuses existing dedup/shuffle logic.
  DoD: unit tests cover level 1, 5, 10 for each of 4 operations.

- **Task 1.4: Mastery advancement service.** Direct implementation.
  New `CountWithKids/Services/MasteryService.swift`. Single entry point: `recordSession(_ session: PracticeSession)` updates `MasteryProgress` rows per the advancement rule in 2.1.
  DoD: unit tests for level-up after 3 clean sheets; level-down after 2 rough sessions; floor/ceiling enforcement.

- **Task 1.5: Dev-only debug screen.** Direct implementation.
  Add a debug-only view (gated on `#if DEBUG`) that shows current `MasteryProgress` rows with buttons to simulate clean/rough sessions. Wire into app via shake gesture or hidden settings tap.
  DoD: can manually verify level progression on a simulator.

**Phase 1 exit criterion:** Can run a CLI-style debug flow that advances a simulated kid from all level-1 to all level-10 and back down.

### Phase 2 — Guided UI
**Goal:** the subscriber experience is visible and usable, assuming subscription is force-enabled via debug.

- **Task 2.1: Force-unlock dev flag.** 30-min task.
  Add a debug toggle to pretend `isGuidedActive == true`. This unblocks all subsequent UI work without needing StoreKit wired.

- **Task 2.2: Home screen Guided card.** Agent: general-purpose.
  Add card to the main menu (find the home/menu view — likely `ContentView.swift` or similar). Two visual states: locked (tap → paywall) and active (tap → Guided home). Match existing card style.

- **Task 2.3: Guided home page.** Agent: general-purpose.
  New `CountWithKids/Views/Guided/GuidedHomeView.swift`. Shows:
  - 3 Daily Plan cards (from `DailyPlanBuilder`)
  - Mastery map (4 operations, current level shown visually — e.g., a 10-step dot indicator per op)
  - Daily-plan streak indicator
  DoD: visually polished, matches theme system (dinosaur/unicorn/etc.).

- **Task 2.4: `DailyPlanBuilder`.** Direct implementation. Pure function per 2.2. Unit-tested.

- **Task 2.5: Guided practice session flow.** Direct implementation.
  Reuse existing `PracticeView` / `PracticeViewModel` but inject problems from adaptive generator. On completion, call `MasteryService.recordSession`. Show level-up celebration if advanced.

- **Task 2.6: Scaffolded hints.** Direct implementation.
  New `HintLibrary.swift`. Hook into `ChallengeViewModel` (existing file) — add a timer that escalates hint tier at 5s/10s/20s.
  DoD: toggleable in debug to test all three hint tiers without waiting.

**Phase 2 exit criterion:** With the force-unlock flag on, entire guided experience works end-to-end from home card to session completion to level-up.

### Phase 3 — StoreKit subscription
**Goal:** real money flow works in sandbox.

- **Task 3.1: App Store Connect subscription setup.** **This is Jirka's task, not an agent's.** See RELEASE_CHECKLIST.md section 2.

- **Task 3.2: Update `Configuration.storekit`.** Direct implementation.
  Add subscription group with monthly + yearly products. Product IDs:
  - `com.countwithkids.guided.monthly` — 79 Kč
  - `com.countwithkids.guided.yearly` — 690 Kč
  - 7-day intro free trial on both
  - Group ID: `com.countwithkids.guided` (single group enables upgrade/downgrade)

- **Task 3.3: Extend `StoreManager`.** Direct implementation. Current line range of `StoreManager.swift` (as of 2026-04-22): ~8–147.
  - Add subscription product loading
  - Add `isGuidedActive: Bool` as a **computed property** derived from `Transaction.currentEntitlements` — never persist this
  - Extend `Transaction.updates` listener to handle subscription renewals, cancellations, grace-period expiry, revocations (refunds)
  - Add grace period handling: if `subscription.state == .inGracePeriod`, treat as active
  - Re-verify on `UIApplication.didBecomeActiveNotification`
  - Keep legacy-purchase + 3,99 $ code fully intact. Do not refactor it.

- **Task 3.4: Paywall redesign.** Agent: general-purpose, with UI/UX care.
  `PaywallView.swift` now must present two offerings:
  1. Odemknout vše (3,99 $, jednorázově) — the existing one-time
  2. Průvodce (79 Kč/měsíc nebo 690 Kč/rok) — the new subscription
  **Mandatory disclosure copy** for the subscription CTA (Czech — localize to en, he):
  > "Obnovuje se automaticky. Zrušit lze kdykoli v Nastavení Apple ID. 7 dní zdarma, pak [79 Kč/měsíc]. Navíc k jednorázovému odemčení — nenahrazuje ho."

  Also required: ToS link + Privacy link above the subscribe button. These are the #1 rejection reason.
  DoD: screenshots reviewed against Apple's subscription guidelines (§3.1.2).

- **Task 3.5: Settings integration.** Direct implementation.
  - Before purchase: row "Průvodce (předplatné) — Neaktivní" → opens paywall
  - After purchase: row becomes "Průvodce" with on/off toggle + "Spravovat předplatné" link using `AppStore.showManageSubscriptions(in:)`
  - Default the toggle to ON immediately after a successful purchase; show a one-time onboarding sheet (see decision table row 10)

- **Task 3.6: Restore Purchases verification.** Direct implementation.
  Ensure the existing Restore button also surfaces active subscriptions on fresh installs. Test in sandbox.

**Phase 3 exit criterion:** Can buy/restore/cancel subscription in sandbox; entitlement correctly flips `isGuidedActive`; grace period and refund are handled.

### Phase 4 — Polish
- **Task 4.1: Weekly parent report.** Direct implementation per 2.4. Schedule `UNUserNotificationCenter` local notification for Sunday 19:00 local time. Don't trigger first notification until kid has ≥3 guided sessions (avoid empty reports).
- **Task 4.2: Czech copy review by Jirka.** Hand-off task.
- **Task 4.3: English + Hebrew localization.** Hand-off task for Jirka's translators.
- **Task 4.4: Theme compatibility.** Direct implementation. Verify GuidedHomeView renders correctly across all themes (dinosaur, unicorn, penguin, lion, custom emoji).
- **Task 4.5: Dark mode + iPad layouts.** Direct implementation.
- **Task 4.6: Accessibility pass.** Direct implementation. Dynamic type, VoiceOver labels.

### Phase 5 — Ship
- **Task 5.1: Run `simplify` skill on all new code.** Invoke: `Skill("simplify")`.
- **Task 5.2: Run `security-review` skill.** Invoke: `Skill("security-review")`. Focus: receipt validation, StoreKit transaction handling.
- **Task 5.3: Unit + UI test pass.** Fix any regressions in existing tests.
- **Task 5.4: Hand off to Jirka** — see RELEASE_CHECKLIST.md.

---

## 5. Key files & architectural seams

**Verify these paths before editing — repo may have changed.**

| File | Purpose | Touched in |
|---|---|---|
| `CountWithKids/Services/StoreManager.swift` | StoreKit 2 entitlement logic | 3.3 |
| `CountWithKids/Models/AppSettings.swift` | Persisted settings | 2.2, 3.5 |
| `CountWithKids/Services/ProblemGenerator.swift` | Problem generation | 1.3 |
| `CountWithKids/Views/Practice/PracticeView.swift` | Practice screen | 2.5 |
| `CountWithKids/ViewModels/PracticeViewModel.swift` | Session orchestration | 2.5 |
| `CountWithKids/ViewModels/ChallengeViewModel.swift` | Mascot race | 2.6 |
| `CountWithKids/Views/Paywall/PaywallView.swift` | Monetization | 3.4 |
| `CountWithKids/Models/PracticeSession.swift` | Session data | 1.4 |
| `CountWithKids/Services/DashboardAggregator.swift` | Dashboard stats | 4.1 (read-only) |
| `Configuration.storekit` | StoreKit testing config | 3.2 |
| (new) `CountWithKids/Models/MasteryProgress.swift` | Per-op mastery | 1.2 |
| (new) `CountWithKids/Services/MasteryService.swift` | Advancement logic | 1.4 |
| (new) `CountWithKids/Services/DailyPlanBuilder.swift` | Today's 3 sessions | 2.4 |
| (new) `CountWithKids/Services/LevelLadder.swift` | Level → problem constraints | 1.1 |
| (new) `CountWithKids/Services/HintLibrary.swift` | Scaffolded hints | 2.6 |
| (new) `CountWithKids/Views/Guided/GuidedHomeView.swift` | Guided main page | 2.3 |

---

## 6. Gotchas

1. **`isGuidedActive` must NOT be persisted.** It's a computed property from live StoreKit entitlements. Persisting it causes users to retain access after subscription expires — and Apple will find this during review.
2. **Sandbox accelerated time:** 1 month = 5 min, 1 year = 1 hour. Don't be confused when your test subscription expires while you're having coffee.
3. **The 3,99 $ unlock must remain fully functional.** Every test scenario needs to include a user who owns only the one-time unlock — they should see the Guided card in locked state but retain everything they had before.
4. **Apple rejects subscriptions that hide renewal terms.** The paywall disclosure copy in Task 3.4 is mandatory, not decorative. Do not shorten it "for design reasons."
5. **Single SwiftData migration.** Phase 1 adds `MasteryProgress`; use a single schema version bump for all new models. Don't create multiple migrations across phases.
6. **Don't refactor the existing 3,99 $ code while you're in `StoreManager`.** Add alongside. Scope creep here = regression for 100% of paying users.
7. **Weekly notification permission:** request `.alert` permission on first guided session completion, not at app launch. Users say no if asked too early.
8. **Czech typography:** watch for proper spaces in "79 Kč" (non-breaking space between number and unit). Existing strings in the app get this right — copy the pattern.

---

## Appendix A — Starter level ladder (to be refined in Task 1.1)

Addition (`+`):
1. a+b ≤ 5, both operands ≤ 5
2. a+b ≤ 10
3. a+b ≤ 20, no carrying
4. a+b ≤ 20, with carrying
5. a+b ≤ 50, single-digit + double-digit
6. a+b ≤ 100, no carrying
7. a+b ≤ 100, with carrying
8. a+b ≤ 500
9. a+b ≤ 1000
10. Mastered — random within 1000

Subtraction (`−`): mirror addition, distinguish with/without borrowing at levels 3/4 and 6/7.

Multiplication (`×`):
1. ×1, ×2 within 20
2. ×1–5 within 50
3. Times tables ×1–×10, result ≤ 100
4. Times tables ×11, ×12
5. Two-digit × one-digit ≤ 200
6. Two-digit × one-digit ≤ 500
7. ×15, ×20, ×25 patterns
8. Two-digit × two-digit ≤ 1000
9. Mixed two-digit × two-digit ≤ 1000
10. Mastered

Division (`÷`):
1. ÷1, ÷2, exact results ≤ 10
2. ÷1–5, exact results ≤ 20
3. Inverse of ×1–10 tables, exact
4. Two-digit ÷ one-digit, exact, ≤ 100
5. Two-digit ÷ one-digit, exact, ≤ 500
6. Division with remainder, ≤ 100
7. Two-digit ÷ two-digit, exact, ≤ 500
8. Two-digit ÷ two-digit, exact, ≤ 1000
9. Division with remainder, ≤ 1000
10. Mastered

Keep this conservative — it's easier to make levels harder after feedback than to slow a kid down mid-progression.
