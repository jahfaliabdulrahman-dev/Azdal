# 🜔 Azdal — دليل المراجعة | Review Guide

> **المرحلة:** Stage 0 — مراجعة وتدقيق | Review & Audit  
> **قبل:** 1 يونيو — موعد تسجيل AMAD (⚠️ 3 أيام!)  
> **الهدف:** مراجعة كل الملفات، تسجيل الملاحظات، الاتفاق الكامل قبل أي كود

---

## ⚠️ تذكير: موعد التسجيل

| الحدث | التاريخ |
|-------|---------|
| **تسجيل AMAD** | **1 يونيو 2026** |
| إعلان القبول | ~1 يوليو |
| الهاكاثون | 16-18 يوليو |

> إذا لم تسجل بعد → هذا أول شيء! سجل قبل مراجعة الملفات.

---

## كيف تستخدم هذا الدليل؟

1. **اقرأ هذا الملف كاملاً أولاً** (5 دقائق)
2. **اتبع مسار المراجعة** المناسب لدورك
3. **سجل كل ملاحظة في `FEEDBACK.md`** (لا تعدل ملفات app-spec مباشرة!)
4. **بعد مراجعتك الشخصية** → ناقش مع الفريق
5. **بعد الاتفاق الكامل** → أرجع لي بالتغذية الراجعة الموحدة

---

## مسار المراجعة — حسب الدور

### 🜔 عبدالرحمن (تقني / AI / Flutter)

اقرأ بهذا الترتيب:

| # | الملف | ماذا تؤكد؟ | الوقت |
|---|-------|-----------|-------|
| 1 | `app-spec/00_product_discovery.md` | الرؤية والمشكلة والحل — هل هذا بالضبط ما تريد؟ | 10 د |
| 2 | `app-spec/01_prd.md` | النظام 3-tier و 5-phase — هل التفاصيل دقيقة؟ | 15 د |
| 3 | `app-spec/12_decision_log.md` | 10 قرارات معمارية — هل توافق عليها كلها؟ | 10 د |
| 4 | `app-spec/00_lessons_learned.md` | 9 دروس — هل فاتنا شيء مهم؟ | 5 د |
| 5 | `app-spec/07_flutter_architecture.md` | الـ tech stack والـ hybrid architecture | 15 د |
| 6 | `app-spec/05_data_model_erd.md` | 5 جداول — هل هذا يكفي للـ MVP؟ | 10 د |
| 7 | `app-spec/16_implementation_backlog.md` | 35+ مهمة في 4 أسابيع — هل هذا واقعي؟ | 10 د |
| 8 | `app-spec/13_assumptions_risks.md` | 10 افتراضات + 15 خطر — فاتنا شيء؟ | 5 د |

**الوقت المتوقع:** ~80 دقيقة  
**ملفات يمكن تخطيها:** `06_api_contract_openapi.yaml` (فارغ)، `14_admin_panel` (فارغ)، `15_support_operations` (فارغ)

---

### 📋 سجا (نموذج العمل / العرض)

اقرأ بهذا الترتيب:

| # | الملف | ماذا تؤكدين؟ | الوقت |
|---|-------|------------|-------|
| 1 | `app-spec/00_product_discovery.md` | الرؤية العامة والفئة المستهدفة | 10 د |
| 2 | `app-spec/02_monetization_entitlements.md` | نموذج الإيرادات على 4 مراحل — هل هذا منطقي؟ | 10 د |
| 3 | `app-spec/19_financial_model_unit_economics.md` | الأرقام المالية — هل التوقعات صحيحة؟ | 10 د |
| 4 | `docs/business/business-model-canvas.md` | BMC — هل يعكس استراتيجيتنا؟ | 10 د |
| 5 | `docs/business/pitch-deck.md` | الـ pitch — هل هو مقنع للجنة التحكيم؟ | 10 د |
| 6 | `docs/business/swot-analysis.md` | SWOT — هل فاتتنا نقطة قوة/ضعف؟ | 5 د |
| 7 | `docs/business/hackathon-strategy.md` | خطة الهاكاثون — هل Demo Script مناسب؟ | 10 د |

**الوقت المتوقع:** ~65 دقيقة  
**ملفات اختيارية:** `docs/business/pestle-analysis.md`، `docs/business/porters-five-forces.md`، `docs/business/market-research.md`

---

### 🎨 ديما (تصميم الواجهات)

اقرأ بهذا الترتيب:

| # | الملف | ماذا تؤكدين؟ | الوقت |
|---|-------|------------|-------|
| 1 | `app-spec/04_ui_design_system.md` | الألوان، الخطوط، التباعد — هل هذا مناسب؟ | 10 د |
| 2 | `app-spec/03_user_flows_navigation.md` | شاشة وحدة؟ 6 widgets؟ هل هذا كافي؟ | 10 د |
| 3 | `docs/design/visual-identity.md` | الهوية البصرية كاملة — هل تحتاج تعديل؟ | 10 د |
| 4 | `docs/design/design-system-original.md` | التصميم الأصلي — هل نطوره؟ | 5 د |
| 5 | `docs/design/ui-screens.html` | النموذج البصري — افتحيه في المتصفح | 5 د |

**الوقت المتوقع:** ~40 دقيقة

---

## نقاط اتفاق أساسية — يجب تأكيدها

قبل أي مراجعة تفصيلية، هذه 7 نقاط يجب أن يتفق عليها الفريق كاملاً:

| # | السؤال | الحالي | نعم؟ |
|---|--------|--------|------|
| 1 | المسار: Financial Education (التعليم المالي)؟ | ✅ محدد | ⬜ |
| 2 | النظام: 3-tier (Coach → Smart Lender → Wealth Builder)؟ | ✅ محدد | ⬜ |
| 3 | الـ MVP: Tier 1 Coach فقط؟ | ✅ محدد | ⬜ |
| 4 | المدخلات: صوت + كاميرا + محادثة (بدون إدخال يدوي)؟ | ✅ محدد | ⬜ |
| 5 | الواجهة: شاشة محادثة واحدة فقط؟ | ✅ محدد | ⬜ |
| 6 | الألوان: Navy #001F5E + Cyan #32C2FF؟ | ✅ محدد | ⬜ |
| 7 | التطبيق مجاني للمستخدم — الإيرادات من B2B (Phase 2)؟ | ✅ محدد | ⬜ |

---

## أسئلة مفتوحة للنقاش مع الفريق

1. **الاسم:** "أزدل" — هل الجميع مرتاح له؟
2. **الشعار:** Solomon's Seal 🜔 — هل يناسب السوق السعودي؟
3. **الخط:** Cairo — هل ديما موافقة؟
4. **Dark mode فقط** — هل هذا قرار صحيح للجمهور المستهدف؟
5. **التسجيل:** Guest-first بدون تسجيل — هل هذا يناسب خطط النمو؟
6. **اللغة:** الواجهة بالعربي فقط — هل نحتاج إنجليزي لاحقاً؟
7. **الـ Pitch:** هل التركيز على "تحويل المستخدم من مديون إلى مستثمر" هو الرسالة الأقوى؟

---

## ماذا بعد المراجعة؟

```
1. راجع ملفاتك حسب دورك                ← الآن
2. سجل الملاحظات في FEEDBACK.md       ← مع كل ملف
3. ناقش مع الفريق                       ← اجتماع
4. وحّد التغذية الراجعة                ← في FEEDBACK.md
5. ارجع لي بالملاحظات الموحدة          ← أنا أطبق التغييرات
6. بعد الموافقة النهائية ← Stage 1     ← أول كود
```

---

## تنبيهات مهمة

| ⚠️ | التنبيه |
|----|---------|
| 1 | **لا تعدل أي ملف في `app-spec/`** — سجل في `FEEDBACK.md` فقط |
| 2 | ملفات `06_api_contract_openapi.yaml` و `14_admin_panel_specification.md` و `15_support_operations_playbook.md` **قوالب فارغة مقصودة** — ستملأ لاحقاً |
| 3 | `pubspec.yaml` هو **stub فقط** — لم نشغل `flutter create` بعد |
| 4 | `lib/` و `test/` **فارغين تماماً** — لا يوجد كود بعد |
| 5 | إذا اختلف الفريق على قرار → ناقشوه وسجلوا القرار النهائي في FEEDBACK.md |

---

## هيكل الملفات للرجوع السريع

```
Azdal/
├── REVIEW_GUIDE.md          ← أنت هنا
├── FEEDBACK.md              ← سجل ملاحظاتك هنا
├── README.md                ← نظرة عامة
├── app-spec/                ← 25 ملف (مصدر الحقيقة)
│   ├── 00_product_discovery.md       ← ابدأ من هنا
│   ├── 00_project_context.md
│   ├── 00_active_capabilities.md
│   ├── 00_lessons_learned.md
│   ├── 00_project_overrides.md
│   ├── 00_swarm_operating_playbook.md
│   ├── 01_prd.md                     ← مواصفات المنتج
│   ├── 02_monetization_entitlements.md
│   ├── 03_user_flows_navigation.md
│   ├── 04_ui_design_system.md
│   ├── 05_data_model_erd.md
│   ├── 06_api_contract_openapi.yaml  ← (فارغ)
│   ├── 07_flutter_architecture.md    ← العمارة التقنية
│   ├── 08_security_privacy.md
│   ├── 09_testing_acceptance.md
│   ├── 10_devops_release_observability.md
│   ├── 11_ai_agent_operating_contract.md
│   ├── 12_decision_log.md            ← القرارات المعمارية
│   ├── 13_assumptions_risks.md
│   ├── 14_admin_panel_specification.md ← (فارغ)
│   ├── 15_support_operations_playbook.md ← (فارغ)
│   ├── 16_implementation_backlog.md
│   ├── 17_data_architecture_acid_constraints.md
│   ├── 18_zero_trust_red_team_audit.md
│   └── 19_financial_model_unit_economics.md
└── docs/                    ← 23 ملف مرجعي
    ├── business/            ← SWOT, PESTLE, Porter, BMC, Pitch
    ├── research/            ← Financial Knowledge Layer
    ├── design/              ← UI screens, visual identity
    └── archive/             ← جلسات سابقة
```
