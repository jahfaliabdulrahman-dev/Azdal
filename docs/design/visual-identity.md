# Azdal — Visual Identity Guidelines

> **Date:** 2026-05-20
> **Amended:** 2026-07-12 (DEC-013) — logo and theme updated to match what's actually in production/the AMAD deck, not the original brief
> **Source:** Gemini logo design + Sulaiman spec (superseded logo/theme sections below)

---

## 1. Logo

### Primary Logo
- **File:** `assets/branding/azdal-logo.png`
- **Design:** Shield outline in a navy-to-cyan gradient, containing three ascending bars (bar chart) with a diagonal upward sweep beneath them — reads as "growth, protected"
- **Arabic text:** "أزدل" in geometric Kufic script
- **Tagline (Arabic):** "أزدل — من مديون... إلى مستثمر"
- **Tagline (English):** "Azdal — Spend Aware"

**Note:** the original brief called for a Solomon's Seal (🜔) symbol. That was dropped at some point before the AMAD submission in favor of the shield+chart mark below — nobody logged the change, so this doc was stale until the 2026-07-12 team review (see `FEEDBACK.md` Q2, `12_decision_log.md` DEC-013).

### Logo Elements

| Element | Description |
|---------|-------------|
| Ascending bar chart | Central symbol — growth, financial progress |
| Shield shape | Financial protection and resilience |
| Diagonal sweep | Momentum, forward motion |
| Navy-to-cyan gradient | #001F5E → #32C2FF — trust transitioning to growth/clarity |

### Logo Variations

| Use Case | Format |
|----------|--------|
| App icon | Shield+chart mark only, navy-cyan gradient |
| Splash screen | Full logo + tagline "من مديون... إلى مستثمر" on light background |
| App header | Shield+chart icon (small) + "أزدل" text |
| Pitch deck / Dark BG | White/cyan version on navy |
| Pitch deck / Light BG | Navy-cyan gradient version on white |

---

## 2. Color Palette — Light Mode (amended 2026-07-12, DEC-013)

> Values below are proposed light-theme equivalents inferred from the AMAD demo screenshots, keeping Navy/Cyan as the unchanged brand anchors. **Not pixel-exact** — confirm against Deema's actual Visily source file before final build.

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Primary** | Navy | `#001F5E` | App header, bot bubbles, logo background, primary buttons |
| **Secondary** | Cyan | `#32C2FF` | Highlights, chart bars, active states, send button, links |
| **Surface** | Off-White | `#F7F8FA` | Main app background |
| **Input Bar** | Light Gray | `#F1F3F5` | Bottom input bar background |
| **Card** | Card White | `#FFFFFF` | Cards, elevated surfaces (with subtle border/shadow) |
| **User Bubble** | Light Navy Tint | `#E3E8F5` | User message bubbles |
| **On Surface** | Near-Black | `#1B1B1F` | Primary text |
| **Muted** | Gray | `#6B7280` | Secondary text, timestamps, placeholders |
| **Success** | Green | `#2E7D32` | Positive verdicts, completed states |
| **Warning** | Amber | `#B7791F` | Caution, "wait" verdict |
| **Danger** | Red | `#D32F2F` | Negative verdicts, "no" states |
| **Border** | Border Gray | `#E1E4E8` | Subtle borders for cards and inputs |

---

## 3. Typography

### App UI Font (Primary)
| Property | Value |
|----------|-------|
| **Family** | **Cairo** (Google Fonts) |
| **Weights** | Regular (400), SemiBold (600), Bold (700), Black (900) |
| **Usage** | ALL app text — chat, buttons, cards, charts, labels |
| **Why** | Designed for Arabic. Excellent legibility at all sizes. Clean geometric feel. |
| **Fallback** | System Arabic font (never needed — Cairo is loaded in Flutter) |

| Text Style | Size | Weight |
|------------|------|--------|
| Headline | 20px | Bold (700) |
| Title | 18px | Bold (700) |
| Body | 14px | Regular (400) |
| Caption | 12px | Regular (400) |
| Button | 13px | SemiBold (600) |
| Timestamp | 10px | Regular (400) |

### Logo Font
| Property | Value |
|----------|-------|
| **Family** | **Noto Kufi Arabic** or geometric Kufic (for Arabic "أزدل") |
| **Usage** | Logo ONLY — not in app UI |
| **Why** | Kufic = geometric, timeless, Islamic heritage. Matches the shield mark's geometric aesthetic. |

---

## 4. Numerals

| Rule | Details |
|------|---------|
| **Use Western numerals** | 1, 2, 3... (NOT ١, ٢, ٣) |
| **Currency** | "ريال" or "SAR" after numbers |
| **Format** | 1,250 (comma separator for thousands) |
| **Decimals** | 87.50 (dot separator) |

---

## 5. Spacing & Clear Space

| Element | Rule |
|---------|------|
| Logo clear space | Minimum 1x logo height on all sides |
| App icon | 1024×1024 px source (standard iOS/Android) |
| Shield+chart mark | Always centered in its container |

---

## 6. RTL Rules

| Rule | Details |
|------|---------|
| All text | Right-to-left alignment |
| Numerals | Stay left-to-right (Western) |
| Icons | Mirror where meaningful (arrows, navigation) |
| Status bar | NEVER mirrors — iOS/Android status bar is fixed |

---

## 7. Assets Checklist

| File | Type | Size | Status |
|------|------|------|--------|
| `azdal-logo.png` | Full logo (shield+chart) | — | ✅ Ready |
| App icon (to generate) | Shield+chart on navy-cyan gradient | 1024×1024 | ⬜ Needed |
| Splash screen | Logo + tagline, light background | 1284×2778 | ✅ In deck (Visily) |
| Favicon | Shield+chart mark | 32×32 | ⬜ Needed |
| Pitch deck logo | Light + Dark variants | SVG | ⬜ Needed |
