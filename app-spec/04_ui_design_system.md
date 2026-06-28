# Azdal — UI Design System

> **Status:** Locked  
> **Source:** Synthesized from `docs/design/design-system-original.md` and `docs/design/visual-identity.md`

---

## Color Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Primary** | Navy | `#001F5E` | App header, bot bubbles, logo BG, primary buttons |
| **Secondary** | Cyan | `#32C2FF` | Highlights, charts, active states, send button, links |
| **Surface** | Dark Gray | `#1B1B1F` | Main app background |
| **Input Bar** | Input Gray | `#161B22` | Bottom input bar background |
| **Card** | Card Gray | `#161B22` | Cards, elevated surfaces |
| **User Bubble** | Bubble Gray | `#30363D` | User message bubbles |
| **On Surface** | White | `#E6E1E5` | Primary text |
| **Muted** | Gray | `#8B949E` | Secondary text, timestamps, placeholders |
| **Success** | Green | `#3FB950` | Positive verdicts, completed states |
| **Warning** | Yellow | `#D29922` | Caution, "wait" verdict |
| **Danger** | Red | `#F85149` | Negative verdicts, "no" states |
| **Border** | Border Gray | `#30363D` | Subtle borders |

---

## Typography

| Property | Value |
|----------|-------|
| Font Family | **Cairo** (Google Fonts) |
| Weights | Regular (400), SemiBold (600), Bold (700), Black (900) |
| Fallback | System Arabic font |

| Text Style | Size | Weight | Usage |
|------------|------|--------|-------|
| Headline | 20px | Bold (700) | Screen titles, major headings |
| Title | 18px | Bold (700) | Widget titles |
| Body | 14px | Regular (400) | Chat messages, content |
| Caption | 12px | Regular (400) | Secondary info, labels |
| Button | 13px | SemiBold (600) | Action buttons |
| Timestamp | 10px | Regular (400) | Message timestamps |

---

## Shape & Border Radius

| Element | Radius |
|---------|--------|
| Chat bubbles | 16px |
| Cards | 16px |
| Buttons | 20px (pill) |
| Input field | 24px (pill) |
| Avatars/Logos | 50% (circle) |

---

## Spacing

| Element | Value |
|---------|-------|
| Chat padding | 16px horizontal |
| Bubble padding | 12px 16px |
| Card padding | 14px |
| Input bar padding | 10px 16px |
| Widget gap | 12px vertical |

---

## Layout Rules

| Rule | Details |
|------|---------|
| Single screen | Chat only — no navigation |
| Dark mode ONLY | No light mode variant |
| RTL layout | All text right-aligned |
| Western numerals | 1, 2, 3 NOT ١, ٢, ٣ |
| Currency format | "1,250 ريال" or "1,250 SAR" |
| Comma separator | Thousands: 1,250 |
| Dot separator | Decimals: 87.50 |

---

## Chat Bubble Styles

| Bubble | Background | Text Color | Border Radius |
|--------|-----------|------------|---------------|
| User message | `#30363D` | `#E6E1E5` | 16px top-right, 16px others |
| Bot message | `#001F5E` | `#E6E1E5` | 16px top-left, 16px others |
| Bot widget card | `#161B22` | `#E6E1E5` | 16px all |

---

## Widget Card Styles

| Widget | Base Style | Special |
|--------|-----------|---------|
| summary_card | Card Gray BG, border `#30363D` | Tone-colored left border (success/warning/danger) |
| bar_chart | Card Gray BG | Cyan bars, muted category labels |
| action_buttons | Transparent BG | Pill buttons: Primary cyan fill, secondary outlined |
| quick_input_form | Card Gray BG | Navy accent input fields |
| goal_progress_card | Card Gray BG | Green progress fill |
| compound_split_card | Card Gray BG | +/- stepper buttons |

---

## Iconography

| Icon | Usage |
|------|-------|
| 🜔 | Solomon's Seal — app header, logo, branding |
| 📷 | Camera button in input bar |
| ↑ | Send button |
| 🍽️ | Food/restaurant category |
| 🛒 | Shopping/groceries |
| 🚗 | Transportation |
| 🎓 | Education |
| 🎉 | Celebrations/milestones |

---

## Logo Usage

| Use Case | Format |
|----------|--------|
| App icon | 🜔 symbol only, navy BG, cyan seal outline |
| Splash screen | Full logo + tagline on navy BG |
| App header | 🜔 icon (small) + "أزدل" text |
| Pitch dark BG | White/cyan version on navy |
| Pitch light BG | Navy version on white |

---

## Typing Indicator

While AI is processing:
- 3 animated dots (cyan, pulse animation)
- In bot bubble area
- Disappears when widget/message arrives

---

## Animation

| Element | Animation |
|---------|-----------|
| Chart bars | Grow from 0 to value (300ms, ease-out) |
| Progress bar | Fill animation (500ms, ease-in-out) |
| Goal celebration | Sparkle burst on completion |
| New bot message | Fade + slide up (200ms) |
| Send button | Scale pulse on tap |

---

## Accessibility

| Rule | Implementation |
|------|---------------|
| Text scaling | Respect system font size (+200% max) |
| Color contrast | WCAG AA minimum (4.5:1 for body text) |
| Screen reader | Semantic labels on all interactive elements |
| RTL | Full RTL support (Flutter Directionality) |

---

## Related
- `03_user_flows_navigation.md` — Widget catalog JSON schemas
- `docs/design/visual-identity.md` — Full visual identity guide
- `docs/design/design-system-original.md` — Original DESIGN.md
