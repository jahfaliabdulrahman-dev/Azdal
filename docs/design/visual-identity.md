# Azdal — Visual Identity Guidelines

> **Date:** 2026-05-20
> **Source:** Gemini logo design + Sulaiman spec

---

## 1. Logo

### Primary Logo
- **File:** `AZDAL Logo.png` (5.6MB — print-ready)
- **Design:** Solomon's Seal (🜔) shield with digital circuit weave patterns
- **Arabic text:** "أزدل" in geometric Kufic script
- **Tagline (Arabic):** "أزدل — درعك المالي"
- **Tagline (English):** "Azdal — Spend Aware"

### Logo Elements

| Element | Description |
|---------|-------------|
| 🜔 Solomon's Seal | Central symbol — wisdom, strength, protection |
| Shield shape | Financial protection and resilience |
| Digital circuit weave | Technology/AI integration |
| Geometric paths | Financial journey, guidance |
| Navy background | #001F5E — trust, authority |
| Cyan accents | #32C2FF — intelligence, clarity |

### Logo Variations

| Use Case | Format |
|----------|--------|
| App icon | 🜔 symbol only, navy background, cyan seal outline |
| Splash screen | Full logo + tagline on navy background |
| App header | 🜔 icon (small) + "أزدل" text |
| Pitch deck / Dark BG | White/cyan version on navy |
| Pitch deck / Light BG | Navy version on white |

---

## 2. Color Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Primary** | Navy | `#001F5E` | App header, bot bubbles, logo background, primary buttons |
| **Secondary** | Cyan | `#32C2FF` | Highlights, chart bars, active states, send button, links |
| **Surface** | Dark Gray | `#1B1B1F` | Main app background |
| **Input Bar** | Input Gray | `#161B22` | Bottom input bar background |
| **Card** | Card Gray | `#161B22` | Cards, elevated surfaces |
| **User Bubble** | Bubble Gray | `#30363D` | User message bubbles |
| **On Surface** | White | `#E6E1E5` | Primary text |
| **Muted** | Gray | `#8B949E` | Secondary text, timestamps, placeholders |
| **Success** | Green | `#3FB950` | Positive verdicts, completed states |
| **Warning** | Yellow | `#D29922` | Caution, "wait" verdict |
| **Danger** | Red | `#F85149` | Negative verdicts, "no" states |
| **Border** | Border Gray | `#30363D` | Subtle borders for cards and inputs |

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
| **Why** | Kufic = geometric, timeless, Islamic heritage. Matches 🜔 seal aesthetic. |

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
| 🜔 symbol | Always centered in its container |

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
| `AZDAL Logo.png` | Full logo | 5.6MB | ✅ Ready |
| App icon (to generate) | 🜔 on navy bg | 1024×1024 | ⬜ Needed |
| Splash screen (to generate) | Logo + tagline | 1284×2778 | ⬜ Needed |
| Favicon | 🜔 | 32×32 | ⬜ Needed |
| Pitch deck logo | Light + Dark variants | SVG | ⬜ Needed |
