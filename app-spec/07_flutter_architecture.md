# Azdal — Flutter Architecture & Technical Design

> **Status:** Locked  
> **Source:** Synthesized from `docs/archive/technical-architecture-original.md`, `docs/archive/final-architecture-decision.md`, and `docs/archive/three-agent-analysis.md`

---

## 1. Core Architecture Principle

> **LLM understands and routes — but NEVER calculates, NEVER stores, NEVER makes final financial decisions.**

| Task | Who Does It | Why |
|------|------------|-----|
| Understand user intent (Arabic NLP) | LLM (Gemini Flash) | Natural language processing |
| Classify transactions | LLM (Gemini Flash) | Semantic understanding |
| Generate UI widgets | LLM → JSON → Flutter GenUI | Dynamic interface |
| Calculate balances | SQL (Supabase) | Deterministic, no hallucination |
| Financial projections | Python (Edge Functions) | Controlled math |
| Data storage | Supabase PostgreSQL | Persistent, ACID |
| Voice input | Apple Speech (on-device) | Free, instant, private |
| OCR receipt scanning | Gemini Vision | Best Arabic OCR |

---

## 2. Layer Architecture

```
┌──────────────────────────────────────────────┐
│                PRESENTATION LAYER             │
│  Flutter Chat UI + GenUI/A2UI Widget Catalog │
│  (Single screen, RTL, dark mode, Cairo font) │
├──────────────────────────────────────────────┤
│                APPLICATION LAYER              │
│  Riverpod State Management                   │
│  ChatProvider, TransactionProvider,           │
│  GoalProvider, IntegrityScoreProvider         │
├──────────────────────────────────────────────┤
│                DOMAIN LAYER                   │
│  Financial Rules Engine (Knowledge Layer)     │
│  Purchase Decision Engine ("Can I buy?")      │
│  Cold Start Intelligence                      │
│  Integrity Score Calculator                   │
├──────────────────────────────────────────────┤
│                DATA LAYER                     │
│  Supabase Client (PostgreSQL)                 │
│  Gemini AI Client (Flash + Vision)            │
│  Local SQLite Cache (Isar)                    │
├──────────────────────────────────────────────┤
│                INFRASTRUCTURE                 │
│  Supabase Edge Functions (Python)             │
│  Gemini API (Cloud)                           │
│  Apple Speech (On-Device)                     │
└──────────────────────────────────────────────┘
```

---

## 3. Technology Stack

```yaml
Frontend:
  Framework: Flutter 3.x (Dart)
  State Management: Riverpod
  UI: Material 3 (Arabic RTL — dark mode only)
  Dynamic UI: Flutter GenUI SDK + A2UI protocol
  Local Cache: Isar (SQLite for offline/recent)
  Voice: Apple Speech (on-device STT)
  TTS: AVSpeechSynthesizer (on-device)
  Routing: go_router (single route — chat)

Backend:
  Database: Supabase (PostgreSQL)
  API Layer: Supabase Edge Functions (Deno/Python)
  Auth: Supabase Auth (opt-in — guest-first)
  File Storage: Supabase Storage (receipt images)

AI:
  Primary LLM: Gemini 2.5 Flash (80% of queries)
  Complex LLM: Gemini 2.5 Pro (20% — financial reasoning)
  Vision: Gemini 2.5 Pro Vision (OCR receipt scanning)
  Fallback: DeepSeek V3.2 (cost optimization)
  Knowledge Base: Financial Knowledge Layer (rules engine)

DevOps:
  CI/CD: GitHub Actions
  Secrets: Environment variables per flavor
  Build Flavors: dev, staging, production
  Release: fastlane (iOS + Android)
```

---

## 4. GenUI / A2UI Widget System

### Architecture

The chat interface renders dynamic widgets from a fixed, pre-defined catalog. The AI agent generates JSON that maps to one of 6 widget types. NO arbitrary code execution.

**Flow:**
```
User message → Gemini Flash (intent + widget decision) → JSON payload → Flutter renders from catalog
```

**Safety:**
- JSON is validated against a strict schema before rendering
- If JSON fails validation → fallback to plain text bot message
- Widget catalog is compiled into the app (not dynamically loaded)
- No eval(). No runtime code injection. App Store safe.

### Widget Catalog

| Widget | File | Schema |
|--------|------|--------|
| summary_card | `lib/shared/widgets/summary_card.dart` | `03_user_flows_navigation.md §1` |
| bar_chart | `lib/shared/widgets/bar_chart.dart` | `03_user_flows_navigation.md §2` |
| action_buttons | `lib/shared/widgets/action_buttons.dart` | `03_user_flows_navigation.md §3` |
| quick_input_form | `lib/shared/widgets/quick_input_form.dart` | `03_user_flows_navigation.md §4` |
| goal_progress_card | `lib/shared/widgets/goal_progress_card.dart` | `03_user_flows_navigation.md §5` |
| compound_split_card | `lib/shared/widgets/compound_split_card.dart` | `03_user_flows_navigation.md §6` |

---

## 5. Gemini Integration

### Prompt Architecture

```text
SYSTEM PROMPT (injected every request):
- You are Azdal, a Saudi Arabic financial AI coach
- Speak Saudi dialect ONLY
- Never calculate: suggest using SQL/functions
- Generate widgets using the Azdal Widget JSON schema
- Follow the Financial Knowledge Layer for ALL financial advice
- If unsure → ask clarifying questions. Never guess.
- Green/Gray/Red triage protocol for transaction classification
- Framing: empowerment over restriction
```

### Dual LLM Routing

| Query Type | Model | % of Traffic | Cost |
|-----------|-------|-------------|------|
| Simple: transaction entry, classification, casual chat | Gemini Flash | 80% | Low |
| Complex: "Can I buy?", financial projections, goal analysis | Gemini Pro | 20% | Medium |
| OCR: Receipt scanning | Gemini Vision | Separate call | Per-image |

### Fallback Strategy

| Failure | Action |
|---------|--------|
| Gemini timeout (>10s) | Retry once. If fails → DeepSeek V3.2 |
| Gemini rate limited | Queue message. Show typing indicator. Retry 3x. |
| Invalid JSON widget | Fallback to plain text bot message |
| Both LLMs down | "المساعد المالي مشغول حالياً. حاول بعد دقيقة." |
| No internet | "أنت غير متصل. العمليات المسجلة الآن سترفع عند عودة الاتصال." |

---

## 6. Hybrid Verification Architecture

### The Problem

For B2B Behavioral Credit Scoring to be viable, data must be trustworthy. User self-reporting alone is insufficient — Goodhart's Law.

### The Solution

```
┌──────────────────────────────────────────────┐
│              GROUND TRUTH LAYER               │
│  Open Banking API (deterministic)             │
│  Bank says: 350 SAR, Panda, May 21, 14:30    │
├──────────────────────────────────────────────┤
│              ENRICHMENT LAYER                  │
│  User adds context (voice/OCR):               │
│  "Milk, bread, diapers"                       │
│  AI cross-validates total vs bank amount      │
├──────────────────────────────────────────────┤
│              VALIDATION LAYER                  │
│  Integrity Score = match rate between layers   │
│  Spoofing detection: mismatch → penalty       │
│  Consistency check: does story match history?  │
├──────────────────────────────────────────────┤
│              BEHAVIORAL SCORE LAYER            │
│  Spending patterns + commitment history       │
│  + goal progress + Integrity Score            │
│  = First behavioral credit score in MENA      │
└──────────────────────────────────────────────┘
```

### Hackathon: MOCK this architecture
- Generate mock bank transactions (deterministic ground truth)
- User enriches via voice/OCR (demo flow)
- System shows Integrity Score calculation
- Demonstrate spoofing detection

---

## 7. Riverpod State Management

### Provider Tree

```dart
// Core providers
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {});
final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {});
final goalProvider = StateNotifierProvider<GoalNotifier, GoalState>((ref) {});
final integrityScoreProvider = Provider<IntegrityScore>((ref) {});
final purchaseDecisionProvider = FutureProvider.family<PurchaseVerdict, String>((ref, query) {});

// AI providers
final geminiProvider = Provider<GeminiService>((ref) {});
final ocrProvider = Provider<GeminiVisionService>((ref) {});

// Auth (guest-first)
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {});

// Local cache
final localCacheProvider = Provider<IsarService>((ref) {});
```

---

## 8. Data Flow: "Can I Buy?"

```
1. User types/voices: "أبي أشتري جوال بـ ٣٠٠٠"
2. ChatProvider adds user message to state
3. Gemini Flash extracts: {item: "جوال", amount: 3000, intent: "purchase_check"}
4. PurchaseDecisionProvider retrieves from Supabase:
   - Monthly income
   - Current month spending (aggregated)
   - Active commitments (BNPL + recurring)
   - Days remaining to salary
   - Active savings goals
5. Edge Function calculates:
   - Disposable = income - commitments - current_spend
   - Remaining_for_month = disposable * (days_remaining / days_in_month)
   - Goal_impact = if amount > 0 { delay_by_months for most_affected_goal }
6. Decision matrix:
   - YES: remaining_for_month >= amount AND no_goal_conflict
   - WAIT: remaining_for_month >= amount BUT has_goal_conflict  
   - NO: remaining_for_month < amount
7. Gemini Pro generates explanatory message (Arabic, framed positively)
8. Response widget rendered in chat
```

---

## 9. Security & Key Management

| Secret | Storage | Access |
|--------|---------|--------|
| Gemini API Key | Environment variable | Backend only (env) |
| Supabase Anon Key | Flutter config | Client-safe |
| Supabase Service Key | Environment variable | Edge Functions only |
| User tokens | Supabase Auth | Auto-managed |
| Receipt images | Supabase Storage | Authenticated, RLS |

---

## 10. Key Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|-----------|
| LLM math hallucination | CRITICAL | LLM NEVER calculates — SQL/Python only |
| Goodhart's Law (gaming) | HIGH | Hybrid verification — Open Banking ground truth |
| BNPL regulatory changes | MEDIUM | Phase 1 = no license needed |
| Cold start — no history | HIGH | Progressive Intelligence — never "no data" |
| User retention | HIGH | Behavioral UX — Hook Model + Progress Principle |

---

## Related
- `03_user_flows_navigation.md` — Widget catalog and flows
- `05_data_model_erd.md` — Database schema
- `08_security_privacy.md` — PDPL and security rules
- `docs/archive/technical-architecture-original.md` — Original full TA doc
