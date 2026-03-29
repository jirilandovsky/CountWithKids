# Count with Kids — Product Page Specification

## Overview

A single-page product website showcasing the "Count with Kids" iOS math practice app for children. The page will use the same visual identity as the mobile app (Dinosaur theme as default) and highlight features, screenshots, and external recognition.

---

## Design System (from mobile app)

### Colors (Dinosaur Theme — Default)
| Role            | Hex       | Usage                          |
|-----------------|-----------|--------------------------------|
| Primary         | `#1ABC9C` | Headings, buttons, accents     |
| Secondary       | `#FF6B6B` | CTAs, highlights, badges       |
| Accent          | `#FFD93D` | Stars, decorative elements     |
| Background      | `#FFF9F0` | Page background (warm cream)   |
| Text            | `#333333` | Body text                      |
| Text muted      | `#666666` | Secondary text, captions       |
| Card background | `#FFFFFF` | Feature cards, content sections |

### Typography
- **Font family:** System rounded font — use CSS `system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif` with `font-optical-sizing: auto`
- **Style:** Playful, rounded feel (matching iOS `.rounded` design)
- **Heading weight:** Bold (700)
- **Body weight:** Regular (400) / Medium (500)

### Visual Style
- Rounded corners (10–16px border-radius)
- Soft shadows for cards
- Playful, child-friendly feel
- Mascot emoji: dinosaur theme uses sauropod emoji where appropriate
- Responsive design (mobile-first)

---

## Page Structure

### 1. Hero Section
- **App icon** (from `AppIcon.png` — 1024x1024, will be sized down)
- **App name:** "Count with Kids"
- **Tagline:** "Fun Math Practice for Kids"
- **Short description:** "Help your child master math with fun themes, instant feedback, and progress tracking. No ads, no data collection — just pure learning. Perfect for ages 4+."
- **CTA buttons:**
  - "Download on the App Store" (link to App Store — use Apple badge style)
  - "View on Educational App Store" (secondary link)
- **5-star badge:** Mention the 5-star rating from Educational App Store

### 2. Screenshots Gallery
- Horizontal scrollable gallery of app screenshots
- Source files (from `fastlane/screenshots/en-US/`):
  - `EN_01.png` — Home/Welcome screen
  - `en-US_02_PracticeInProgress.png` — Practice in progress
  - `en-US_03_Dashboard.png` — Dashboard with charts
  - `en-US_04_Settings.png` — Settings screen
- Display inside phone mockup frames or with rounded corners + shadow

### 3. Features Section
Key features to highlight (from App Store description):

- **Four Math Operations** — Addition, subtraction, multiplication, and division
- **Adjustable Difficulty** — Counting ranges from 10 up to 1,000
- **Instant Feedback** — Correct answers appear right away so kids learn from mistakes
- **Clean Sheet Celebrations** — Special celebration when every answer is correct
- **Progress Dashboard** — Bar charts showing average errors, completion time, and clean sheet streaks filtered by day, week, month, or year
- **Fun Themes** — Dinosaur, Unicorn, Penguin, and Lion themes to keep kids engaged
- **Trophies & Streaks** — Gold cups, silver medals, and streak tracking for motivation
- **Customizable Sessions** — Set number of problems (1–10) and optional countdown timer
- **Three Languages** — English, Czech, and Hebrew with full RTL support
- **100% Private** — No ads, no tracking, no internet required, COPPA compliant

### 4. "Designed for Kids" Section
- Age range: 4+
- No ads, no tracking, no internet required
- No in-app purchases
- All data stays on the device
- COPPA compliant

### 5. Educational App Store Recognition
- 5-star rating badge/banner
- Link to the review: `https://www.educationalappstore.com/app/count-with-kids`
- Brief mention that the app has been independently evaluated and awarded 5 stars

### 6. Footer
- Links to Privacy Policy (`privacy.html`) and Support (`support.html`)
- Copyright notice
- Small app icon or name

---

## Assets to Copy into Product Page Folder

| Source | Destination | Purpose |
|--------|-------------|---------|
| `CountWithKids/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | `assets/app-icon.png` | App icon in hero |
| `fastlane/screenshots/en-US/EN_01.png` | `assets/screenshot-home.png` | Home screen screenshot |
| `fastlane/screenshots/en-US/en-US_02_PracticeInProgress.png` | `assets/screenshot-practice.png` | Practice screenshot |
| `fastlane/screenshots/en-US/en-US_03_Dashboard.png` | `assets/screenshot-dashboard.png` | Dashboard screenshot |
| `fastlane/screenshots/en-US/en-US_04_Settings.png` | `assets/screenshot-settings.png` | Settings screenshot |

---

## External Links

- **App Store:** `https://apps.apple.com/app/count-with-kids/id6743891197` (use Apple "Download on the App Store" badge)
- **Educational App Store review:** `https://www.educationalappstore.com/app/count-with-kids`

---

## Technical Requirements

- Single HTML file (`index.html`) with inline CSS (or a separate `style.css`)
- No JavaScript frameworks required — vanilla HTML/CSS
- Responsive: works on mobile, tablet, and desktop
- Fast loading — optimize image references
- Semantic HTML5 structure
- Accessible (alt text for images, proper heading hierarchy)
- The page replaces the existing minimal `docs/index.html` — but this is a new standalone page in the `CountWithKids_Page` folder

---

## File Structure

```
CountWithKids_Page/
  index.html          # The product page
  SPEC.md             # This specification
  assets/
    app-icon.png      # App icon
    screenshot-home.png
    screenshot-practice.png
    screenshot-dashboard.png
    screenshot-settings.png
```
