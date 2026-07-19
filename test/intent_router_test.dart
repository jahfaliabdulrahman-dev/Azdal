/// Unit tests for [IntentRouter].
///
/// Tests every keyword regex against known-good dialectal phrasings
/// and verifies classification cascade order.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/features/chat/routing/intent_router.dart';

void main() {
  group('IntentRouter — normalizeArabic', () {
    test('hamza normalization — أإآ → ا', () {
      expect(IntentRouter.normalizeArabic('أبي أشتري'), 'ابي اشتري');
      expect(IntentRouter.normalizeArabic('إيجار'), 'ايجار');
      expect(IntentRouter.normalizeArabic('آسف'), 'اسف');
    });

    test('alef-maqsura → ي', () {
      expect(IntentRouter.normalizeArabic('مصروفى'), 'مصروفي');
    });

    test('ta-marbuta → ه', () {
      expect(IntentRouter.normalizeArabic('نزاهة'), 'نزاهه');
      expect(IntentRouter.normalizeArabic('ميزانية'), 'ميزانيه');
    });
  });

  group('IntentRouter — setup intent (commitment + goal keywords)', () {
    test('commitment keywords match', () {
      expect(IntentRouter.looksLikeSetupIntent('عندي قسط تمارا'), isTrue);
      expect(IntentRouter.looksLikeSetupIntent('إيجار الشقة'), isTrue);
      expect(IntentRouter.looksLikeSetupIntent('عندي ديون'), isTrue);
      expect(IntentRouter.looksLikeSetupIntent('اشتراك نتفلكس'), isTrue);
    });

    test('goal keywords match', () {
      expect(IntentRouter.looksLikeSetupIntent('أبي أوفر 5000'), isTrue);
      expect(IntentRouter.looksLikeSetupIntent('عندي هدف'), isTrue);
      expect(IntentRouter.looksLikeSetupIntent('صندوق الطوارئ'), isTrue);
      expect(IntentRouter.looksLikeSetupIntent('ابي ادخر'), isTrue);
    });

    test('hamza-drop variants still match', () {
      // User types "ابي اشتري" without hamza
      expect(IntentRouter.looksLikeSetupIntent('ابي ادخر'), isTrue);
    });

    test('non-setup text → false', () {
      expect(IntentRouter.looksLikeSetupIntent('السلام عليكم'), isFalse);
      expect(IntentRouter.looksLikeSetupIntent('شكراً'), isFalse);
    });
  });

  group('IntentRouter — buy intent keywords', () {
    test('buy phrasings match', () {
      expect(IntentRouter.looksLikeBuyIntent('ابي اشتري جوال'), isTrue);
      expect(IntentRouter.looksLikeBuyIntent('ودي اشتري لابتوب'), isTrue);
      expect(IntentRouter.looksLikeBuyIntent('بشتري كتاب'), isTrue);
      expect(IntentRouter.looksLikeBuyIntent('هل اقدر اشتري'), isTrue);
      expect(IntentRouter.looksLikeBuyIntent('ينفع اشتري سيارة'), isTrue);
      expect(IntentRouter.looksLikeBuyIntent('نفسي اشتري'), isTrue);
    });

    test('hamza-drop variant', () {
      // "أبي أشتري" with hamza → normalizes to "ابي اشتري"
      expect(IntentRouter.looksLikeBuyIntent('أبي أشتري جوال'), isTrue);
    });

    test('non-buy text → false', () {
      expect(IntentRouter.looksLikeBuyIntent('كم ساعة نمت'), isFalse);
    });
  });

  group('IntentRouter — integrity query keywords', () {
    test('integrity phrasings match', () {
      expect(IntentRouter.looksLikeIntegrityQuery('كيف ادائي'), isTrue);
      expect(IntentRouter.looksLikeIntegrityQuery('كم درجه النزاهه'), isTrue);
      expect(IntentRouter.looksLikeIntegrityQuery('نزاهتي'), isTrue);
      expect(IntentRouter.looksLikeIntegrityQuery('كيف نزاهتي'), isTrue);
    });

    test('non-integrity text → false', () {
      expect(IntentRouter.looksLikeIntegrityQuery('كيف حالك'), isFalse);
    });
  });

  group('IntentRouter — budget query keywords', () {
    test('budget phrasings match', () {
      expect(IntentRouter.looksLikeBudgetQuery('كم باقي'), isTrue);
      expect(IntentRouter.looksLikeBudgetQuery('باقي من مصروفي'), isTrue);
      expect(IntentRouter.looksLikeBudgetQuery('كم متبقي'), isTrue);
      expect(IntentRouter.looksLikeBudgetQuery('وش وضع ميزانيتي'), isTrue);
    });

    test('hamza-drop variant', () {
      expect(IntentRouter.looksLikeBudgetQuery('كم باقي ميزانيه'), isTrue);
    });

    test('non-budget text → false', () {
      expect(IntentRouter.looksLikeBudgetQuery('كم الساعة'), isFalse);
    });
  });

  group('IntentRouter — classify cascade', () {
    test('setup takes priority over others', () {
      // "عندي قسط وابي اشتري" — both setup and buy keywords present
      expect(
        IntentRouter.classify('عندي قسط تمارا وابي اشتري جوال'),
        GateDecision.setupCommitment,
      );
    });

    test('buy intent classified correctly', () {
      expect(
        IntentRouter.classify('ابي اشتري جوال ب2000'),
        GateDecision.buyIntent,
      );
    });

    test('integrity query classified correctly', () {
      expect(
        IntentRouter.classify('كيف نزاهتي'),
        GateDecision.integrityQuery,
      );
    });

    test('budget query classified correctly', () {
      expect(
        IntentRouter.classify('كم باقي من ميزانيتي'),
        GateDecision.budgetQuery,
      );
    });

    test('fallback to generalChat', () {
      expect(
        IntentRouter.classify('السلام عليكم'),
        GateDecision.generalChat,
      );
      expect(
        IntentRouter.classify('شكراً لك'),
        GateDecision.generalChat,
      );
    });
  });
}
