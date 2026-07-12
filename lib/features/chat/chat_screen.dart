/// Chat screen — the sole UI screen of Azdal.
///
/// Implements the full chat experience:
/// - Scrollable message list with user/bot bubbles
/// - Widget catalog rendering (6 types) via Gemini JSON responses
/// - Voice input via speech_to_text (CHAT-04)
/// - Transaction logging to Supabase (CHAT-05)
/// - Compound transaction splitting (CHAT-06)
/// - Cold Start Intelligence (CHAT-07)
/// - Offline detection with connectivity_plus
/// - Error bubble with retry
/// - Typing indicator
library;

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../main.dart';
import 'models/chat_message.dart';
import 'providers/chat_provider.dart';
import 'widgets/chat_widgets.dart';
import 'widgets/widget_catalog.dart';

// ─────────────────────────────────────────────────────────────────────
// Design token constants (from 04_ui_design_system.md)
// ─────────────────────────────────────────────────────────────────────

const _navy = Color(0xFF001F5E);
const _cyan = Color(0xFF32C2FF);
const _userBubbleBg = Color(0xFFE3E8F5);
const _muted = Color(0xFF6B7280);
const _white = Colors.white;

// ─────────────────────────────────────────────────────────────────────
// ChatScreen
// ─────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  /// Whether the device is currently connected.
  bool _isOnline = true;

  /// Subscription for connectivity changes.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Whether Cold Start has been triggered for this session.
  bool _coldStartDone = false;

  /// Guard against double-tap on confirm/save actions.
  bool _isConfirming = false;

  /// Guard against double-tap on undo action.
  bool _isUndoing = false;

  /// Stored classification results from the first _tryAutoClassify call,
  /// keyed by user message id. Used by _confirmTransaction to avoid a
  /// second (non-deterministic) Gemini call — matching the one that
  /// decided to show the confirm/edit buttons in the first place.
  final Map<String, Map<String, dynamic>> _storedClassifications = {};

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initVoice();
    _checkColdStart();
    // Check for shared images from system share sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingSharedImage();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ── Connectivity ──

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateOnlineStatus(result);
      _connectivitySub = Connectivity().onConnectivityChanged.listen(_updateOnlineStatus);
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Connectivity init error — $e');
    }
  }

  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      setState(() => _isOnline = online);
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Connectivity changed — online=$online');
      // Auto-send queued messages when connectivity returns
      if (online && _isOnline) {
        // Future: process queued messages
      }
    }
  }

  // ── Voice ──

  Future<void> _initVoice() async {
    final voiceService = ref.read(voiceServiceProvider);
    final available = await voiceService.initialize();
    // ignore: avoid_print
    print('=== AZDAL DEBUG: Voice init — available=$available');
  }

  Future<void> _toggleVoice() async {
    final voiceService = ref.read(voiceServiceProvider);
    final voiceListening = ref.read(voiceListeningProvider);

    if (voiceListening.isListening) {
      final text = await voiceService.stopListening();
      if (text.isNotEmpty && mounted) {
        _textController.text = text;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      }
    } else {
      final started = await voiceService.startListening(
        onResult: (text, _) {
          if (mounted) {
            _textController.text = text;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
          }
        },
      );
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تشغيل الميكروفون. تأكد من الصلاحيات.'),
          ),
        );
      }
    }
    // No setState() — voiceListeningProvider rebuilds the icon
    // reactively whenever onStatus fires from the recognizer.
  }

  // ── Cold Start ──

  Future<void> _checkColdStart() async {
    if (_coldStartDone) return;

    // Don't check cold start until chat provider is available
    final chatState = ref.read(chatProvider);
    if (chatState.messages.isNotEmpty) return;

    // Check if user has existing transactions in Supabase
    try {
      final txService = ref.read(transactionServiceProvider);
      final hasTransactions = await txService.hasExistingTransactions();

      if (!hasTransactions && mounted) {
        _coldStartDone = true;
        _triggerColdStart();
      }
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Cold start check FAILED — $e');
    }
  }

  void _triggerColdStart() {
    final chatNotifier = ref.read(chatProvider.notifier);
    chatNotifier.addBotMessage(
      'صباح الخير! عشان أقدر أساعدك — ٣ أسئلة بس:',
      widget: {
        'widget': 'quick_input_form',
        'title': 'معلوماتك المالية',
        'fields': [
          {
            'label': 'الدخل الشهري التقريبي',
            'placeholder': 'مثلاً: 10,000 ريال',
            'key': 'monthly_income',
            'type': 'number',
          },
          {
            'label': 'الالتزامات الشهرية — إيجار، أقساط، فواتير',
            'placeholder': 'مثلاً: 4,000 ريال',
            'key': 'monthly_commitments',
            'type': 'number',
          },
          {
            'label': 'كم تصرف تقريباً بالأسبوع؟',
            'placeholder': 'مثلاً: 1,500 ريال',
            'key': 'weekly_spend',
            'type': 'number',
          },
        ],
        'submit_label': 'إرسال',
      },
    );
  }

  Future<void> _handleColdStartSubmit(Map<String, dynamic> values) async {
    final chatNotifier = ref.read(chatProvider.notifier);
    final income = values['monthly_income'] ?? '0';
    final commitments = values['monthly_commitments'] ?? '0';
    final weeklySpend = values['weekly_spend'] ?? '0';

    // Calculate rough insight
    final monthlyIncome = double.tryParse(income.toString()) ?? 0;
    final monthlyCommitments = double.tryParse(commitments.toString()) ?? 0;
    final monthlySpend = (double.tryParse(weeklySpend.toString()) ?? 0) * 4;

    final disposableAfterCommitments = monthlyIncome - monthlyCommitments;
    final spendRatio = disposableAfterCommitments > 0
        ? (monthlySpend / disposableAfterCommitments * 100).round()
        : 100;

    String insight;
    if (spendRatio >= 70) {
      insight =
          'تصرف $spendRatio% من دخلك قبل منتصف الشهر. خليني أساعدك — سجل أول عملية بالصوت أو الكتابة.';
    } else {
      insight =
          'وضعك المالي معقول حالياً. تبي نبدأ نسجل أول عملية؟ اكتب أو استخدم الصوت 🎤';
    }

    chatNotifier.addBotMessage(insight);

    // Store the cold start data as a transaction (income marker)
    if (monthlyIncome > 0) {
      try {
        final txService = ref.read(transactionServiceProvider);
        await txService.saveTransaction(
          amount: monthlyIncome,
          category: 'دخل',
          subcategory: 'دخل شهري',
          description: 'الدخل الشهري التقريبي (Cold Start)',
          type: 'income',
          tone: 'green',
        );
      } catch (e) {
        // ignore: avoid_print
        print('=== AZDAL DEBUG: Cold start income save FAILED — $e');
      }
    }
  }

  // ── Message send ──

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (!_isOnline) {
      // Offline: show a message but don't clear input
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أنت غير متصل. حاول مرة أخرى عند عودة الاتصال.')),
        );
      }
      return;
    }

    _textController.clear();
    _focusNode.unfocus();

    final chatNotifier = ref.read(chatProvider.notifier);
    final geminiService = ref.read(geminiServiceProvider);

    // Add user message
    chatNotifier.addUserMessage(text);

    // Get current state for history
    final currentMessages = ref.read(chatProvider).messages;

    try {
      // Call Gemini
      final response = await geminiService.sendMessage(
        text,
        history: currentMessages,
      );

      if (!mounted) return;

      if (response.hasError) {
        chatNotifier.setError(response.error!);
        return;
      }

      // Handle widget-based response
      if (response.widget != null) {
        final widgetType = response.widget!['widget'] as String?;

        if (widgetType == 'quick_input_form' &&
            response.widget!['title'] == 'معلوماتك المالية') {
          // Cold start form — handled specially
        }

        chatNotifier.addBotMessage(
          response.text,
          widget: response.widget,
        );
      } else {
        // Check if this looks like a transaction entry
        final txResult = await _tryAutoClassify(text);
        if (txResult != null && mounted) {
          final txType = txResult['type'] as String?;

          if (txType == 'compound') {
            // Multi-item compound split — show the widget directly.
            // The splits come from _tryAutoClassify's own Gemini call
            // (no conversation history → cannot conflate prior items).
            // Confirm reads splits from the widget action payload, not
            // from _storedClassifications.
            chatNotifier.addBotMessage(
              response.text.isNotEmpty ? response.text : 'تم استخراج العناصر:',
              widget: txResult['widget'] as Map<String, dynamic>,
            );
          } else {
            // Simple transaction — store for later confirm, build
            // action_buttons UI locally (single path, same as always).
            final lastUserMsgId = ref.read(chatProvider).messages
                .lastWhere((m) => m.isUser)
                .id;
            _storedClassifications[lastUserMsgId] = txResult;

            chatNotifier.addBotMessage(
              response.text.isNotEmpty
                  ? response.text
                  : 'تم تسجيل ${txResult['amount']} ريال — ${txResult['category']}',
              widget: {
                'widget': 'action_buttons',
                'question': 'هل التصنيف صحيح؟',
                'buttons': [
                  {
                    'label': '✅ صحيح',
                    'value': 'confirm',
                    'type': 'primary',
                  },
                  {
                    'label': '🔄 تعديل',
                    'value': 'edit',
                    'type': 'secondary',
                  },
                ],
              },
            );
          }
        } else {
          chatNotifier.addBotMessage(response.text, widget: response.widget);
        }
      }
    } catch (e) {
      if (!mounted) return;
      chatNotifier.setError(e.toString());
    }
  }

  /// Attempt to auto-classify a transaction entry via Gemini.
  /// Returns parsed data or null if it doesn't look like a transaction.
  Future<Map<String, dynamic>?> _tryAutoClassify(String text) async {
    final geminiService = ref.read(geminiServiceProvider);

    try {
      // Quick check: does this look like it has a number?
      // Match both Western (0-9) and Arabic-Indic (٠-٩) numerals.
      if (!RegExp(r'[0-9٠-٩]').hasMatch(text)) return null;

      // Use Gemini to extract transaction details.
      // Uses dedicated classifyTransaction method — separate system prompt,
      // no conversation history → cannot conflate prior messages.
      final response = await geminiService.classifyTransaction(text);

      // Parse classification result — priority order:
      // 1. Parsed widget (JSON block from Gemini)
      // 2. Raw text fallback (if JSON parsing failed)

      final data = response.widget;

      // Error: not a transaction
      if (data != null && data.containsKey('error')) {
        return null;
      }

      // Compound split
      if (data != null && data['widget'] == 'compound_split_card') {
        return {'type': 'compound', 'widget': data};
      }

      // Simple transaction with structured data
      if (data != null && data.containsKey('amount')) {
        final amount = data['amount'];
        final amountNum = amount is int
            ? amount
            : (amount is String ? int.tryParse(amount) : null) ?? 0;
        if (amountNum > 0) {
          return {
            'type': 'simple',
            'amount': amountNum,
            'category': data['category'] as String? ?? 'متنوع',
            'tone': data['tone'] as String? ?? 'gray',
            'response_text': response.text,
          };
        }
      }

      // Fallback: parse raw text for amount
      final rawText = response.text;
      if (rawText.contains('NOT_TRANSACTION') ||
          rawText.contains('ليست معاملة')) {
        return null;
      }

      // Match both Western and Arabic-Indic numerals
      final amountMatch =
          RegExp(r'([0-9٠-٩]+)').firstMatch(rawText);
      if (amountMatch != null) {
        final digits = amountMatch.group(1)!;
        // Convert Arabic-Indic to Western numerals
        final western = _arabicToWestern(digits);
        final parsed = int.tryParse(western);
        if (parsed != null && parsed > 0) {
          return {
            'type': 'simple',
            'amount': parsed,
            'category': 'متنوع',
            'tone': 'gray',
            'response_text': rawText,
          };
        }
      }

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Auto-classify FAILED — $e');
      return null;
    }
  }

  /// Convert Arabic-Indic numerals (٠-٩) to Western (0-9).
  static String _arabicToWestern(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(arabic[i], western[i]);
    }
    return result;
  }

  // ── Widget action handler ──

  Future<void> _handleWidgetAction(Map<String, dynamic> action) async {
    final chatNotifier = ref.read(chatProvider.notifier);
    final actionType = action['action'] as String?;
    final widgetType = action['widget'] as String?;

    // ignore: avoid_print
    print('=== AZDAL DEBUG: Widget action — $actionType on $widgetType');

    switch (widgetType) {
      case 'action_buttons':
        final value = action['value'] as String?;
        final msgId = action['message_id'] as String?;
        if (value == null || msgId == null) break;
        if (_isConfirming) break; // Guard: prevent double-tap

        // Mark consumed FIRST — before any async work.
        // The widget reads _answered and disables all buttons immediately.
        chatNotifier.markWidgetAnswered(msgId, value);

        if (value == 'confirm') {
          await _confirmTransaction(chatNotifier);
        } else if (value == 'edit') {
          chatNotifier.addBotMessage('تمام — وش التصنيف الصح؟ اكتب التصنيف الجديد.');
        } else if (value == 'undo_transaction') {
          await _undoTransaction(action, chatNotifier);
        }
        break;

      case 'quick_input_form':
        final values = action['values'] as Map<String, dynamic>?;
        if (values != null) {
          // Could be Cold Start or other form
          if (values.containsKey('monthly_income')) {
            await _handleColdStartSubmit(values);
          }
          chatNotifier.addBotMessage('تم استلام المعلومات. شكراً لك! 🙏');
        }
        break;

      case 'compound_split_card':
        final msgId = action['message_id'] as String?;
        if (msgId == null) break;

        if (actionType == 'compound_split_cancel') {
          // Mark consumed, then acknowledge — no Supabase call.
          chatNotifier.markWidgetAnswered(msgId, 'compound_split_cancel');
          chatNotifier.addBotMessage('تم الإلغاء.');
          break;
        }

        // Mark consumed before attempting the save.
        chatNotifier.markWidgetAnswered(msgId, 'compound_split_confirm');
        await _handleCompoundSplit(action, chatNotifier);
        // Upload receipt to storage if this came from OCR
        if (_capturedReceiptPath != null) {
          final receiptUrl =
              await _uploadReceiptToStorage(_capturedReceiptPath!);
          if (receiptUrl != null) {
            // ignore: avoid_print
            print('=== AZDAL DEBUG: Receipt stored — url=$receiptUrl');
          }
          _capturedReceiptPath = null;
        }
        break;

      case 'ocr_failure':
        final ocrAction = action['action'] as String?;
        if (ocrAction == 'ocr_failure_submit') {
          // Manual entry from OCR failure
          await _handleOcrFailureSubmit(action, chatNotifier);
        } else if (ocrAction == 'ocr_retake') {
          // ignore: avoid_print
          print('=== AZDAL DEBUG: OCR retake requested');
          unawaited(_pickReceiptImage());
        }
        break;
    }
  }

  Future<void> _confirmTransaction(ChatProvider chatNotifier) async {
    if (_isConfirming) return; // Guard: prevent double-tap
    _isConfirming = true;
    try {
      // Find the most recent user message
      final messages = ref.read(chatProvider).messages;
      final lastUserMsg = messages.reversed.firstWhere(
        (m) => m.isUser,
        orElse: () => ChatMessage(
          id: '',
          role: 'user',
          content: '',
          timestamp: DateTime(2000),
        ),
      );

      if (lastUserMsg.content.isEmpty) return;

      // Use stored classification from the FIRST _tryAutoClassify call —
      // never call Gemini again (LLM output isn't deterministic).
      final txResult = _storedClassifications[lastUserMsg.id];
      if (txResult == null || txResult['type'] != 'simple') {
        chatNotifier.setError(
          'تعذر حفظ المعاملة — التصنيف غير متوفر. حاول مرة أخرى.',
        );
        return;
      }

      final txService = ref.read(transactionServiceProvider);
      final saved = await txService.saveTransaction(
        amount: (txResult['amount'] as num).toDouble(),
        category: txResult['category'] as String? ?? 'متنوع',
        tone: txResult['tone'] as String? ?? 'gray',
      );
      final txId = saved['id'] as String;

      // DEC-020: Attach undo button — single transaction
      chatNotifier.addBotMessage(
        'تم تسجيل المعاملة بنجاح ✅',
        widget: {
          'widget': 'action_buttons',
          'question': 'تم تسجيل المعاملة بنجاح ✅',
          'buttons': [
            {
              'label': '↩️ تراجع',
              'value': 'undo_transaction',
              'type': 'secondary',
            }
          ],
          'tx_id': txId,
          'tx_type': 'simple',
        },
      );
    } catch (e) {
      chatNotifier.setError('فشل حفظ المعاملة: $e');
    } finally {
      _isConfirming = false;
    }
  }

  /// Soft-delete a confirmed transaction (simple or compound group).
  ///
  /// Called when the user taps "↩️ تراجع" on a success message.
  /// Reads the transaction id and type from [action].
  /// Removes the undo-button message and replaces it with plain text
  /// so the button is gone after use.
  Future<void> _undoTransaction(
    Map<String, dynamic> action,
    ChatProvider chatNotifier,
  ) async {
    if (_isUndoing) return; // Guard: prevent double-tap
    _isUndoing = true;
    try {
      final txId = action['tx_id'] as String?;
      final txType = action['tx_type'] as String?;
      if (txId == null) return;

      final txService = ref.read(transactionServiceProvider);

      if (txType == 'group') {
        await txService.softDeleteTransactionGroup(txId);
      } else {
        await txService.softDeleteTransaction(txId);
      }

      // Find the message with the undo button and replace it
      final messages = ref.read(chatProvider).messages;
      for (final msg in messages.reversed) {
        if (msg.hasWidget && msg.widget!['tx_id'] == txId) {
          chatNotifier.removeMessage(msg.id);
          break;
        }
      }
      chatNotifier.addBotMessage('تم التراجع ✅');
    } catch (e) {
      chatNotifier.setError('فشل التراجع: $e');
    } finally {
      _isUndoing = false;
    }
  }

  Future<void> _handleCompoundSplit(
    Map<String, dynamic> action,
    ChatProvider chatNotifier,
  ) async {
    final splits = action['splits'] as List<dynamic>?;
    if (splits == null || splits.isEmpty) return;

    try {
      final txService = ref.read(transactionServiceProvider);
      final splitData = splits.map((s) {
        final split = s as Map<String, dynamic>;
        return {
          'amount': (split['amount'] as num).toDouble(),
          'category': split['category'] as String? ?? 'متنوع',
          'type': 'expense',
          'tone': 'gray',
        };
      }).toList();

      final results = await txService.saveCompoundSplits(splits: splitData);
      final groupId = results.first['id'] as String;

      // DEC-020: Attach undo button — compound split (group id)
      chatNotifier.addBotMessage(
        'تم تسجيل ${splits.length} معاملات بنجاح ✅',
        widget: {
          'widget': 'action_buttons',
          'question': 'تم تسجيل ${splits.length} معاملات بنجاح ✅',
          'buttons': [
            {
              'label': '↩️ تراجع',
              'value': 'undo_transaction',
              'type': 'secondary',
            }
          ],
          'tx_id': groupId,
          'tx_type': 'group',
        },
      );
    } catch (e) {
      chatNotifier.setError(e.toString());
    }
  }

  /// Handle OCR failure manual entry — save as simple transaction.
  Future<void> _handleOcrFailureSubmit(
    Map<String, dynamic> action,
    ChatProvider chatNotifier,
  ) async {
    final amountStr = action['amount'] as String?;
    final category = action['category'] as String? ?? 'متنوع';

    if (amountStr == null || amountStr.isEmpty) return;

    final amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0) return;

    try {
      final txService = ref.read(transactionServiceProvider);

      // Try to upload receipt first (if we still have it)
      String? receiptUrl;
      if (_capturedReceiptPath != null) {
        receiptUrl = await _uploadReceiptToStorage(_capturedReceiptPath!);
        _capturedReceiptPath = null;
      }

      final saved = await txService.saveTransaction(
        amount: amount,
        category: category,
        description: 'إدخال يدوي (فشل OCR)',
        receiptUrl: receiptUrl,
      );
      final txId = saved['id'] as String;

      chatNotifier.addBotMessage(
        'تم تسجيل $amount ريال — $category ✅',
        widget: {
          'widget': 'action_buttons',
          'question': 'تم تسجيل $amount ريال — $category ✅',
          'buttons': [
            {
              'label': '↩️ تراجع',
              'value': 'undo_transaction',
              'type': 'secondary',
            }
          ],
          'tx_id': txId,
          'tx_type': 'simple',
        },
      );
    } catch (e) {
      chatNotifier.setError('فشل حفظ المعاملة: $e');
    }
  }

  // ── OCR Camera / Gallery / Share Sheet ──────────────────────────

  /// Path of the captured or selected receipt image (temporary file).
  String? _capturedReceiptPath;

  /// Show a bottom sheet to pick receipt from camera or gallery.
  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _navy),
              title: const Text('تصوير الإيصال',
                  style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _navy),
              title: const Text('اختيار من المعرض',
                  style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (xFile != null && mounted) {
        // ignore: avoid_print
        print('=== AZDAL DEBUG: Receipt image picked — '
            'path=${xFile.path}');
        await _processReceiptImage(xFile.path);
      }
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Image pick FAILED — $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر التقاط الصورة. تأكد من الصلاحيات.')),
        );
      }
    }
  }

  /// Process a receipt image: show in chat, trigger OCR, handle result.
  Future<void> _processReceiptImage(String imagePath) async {
    final chatNotifier = ref.read(chatProvider.notifier);

    // Display the image as a user message
    chatNotifier.addUserMessage('📷 إيصال', imagePath: imagePath);

    // Show OCR processing overlay — capture its id so we can remove it
    // when the result (or failure) arrives.
    final processingId = chatNotifier.addBotMessage(
      '',
      widget: const {'widget': 'ocr_processing'},
    );

    try {
      // Read image bytes
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        chatNotifier.setError('الصورة غير موجودة.');
        return;
      }

      final imageBytes = await imageFile.readAsBytes();

      // Run OCR with timeout
      final geminiService = ref.read(geminiServiceProvider);
      final ocrResult = await geminiService
          .ocrReceipt(imageBytes)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      // Check result
      if (ocrResult.containsKey('error')) {
        // State 3: OCR failure → show manual entry
        _showOcrFailure(chatNotifier, ocrResult, processingId);
        return;
      }

      final items = ocrResult['items'] as List<dynamic>? ?? [];
      final total = ocrResult['total'];

      if (items.isEmpty) {
        // State 3: No items extracted
        _showOcrFailure(chatNotifier, ocrResult, processingId);
        return;
      }

      // State 2 or full success: show compound_split_card
      _showOcrResult(chatNotifier, items, total, imagePath, processingId);
    } on TimeoutException {
      if (!mounted) return;
      // ignore: avoid_print
      print('=== AZDAL DEBUG: OCR timed out after 10s');
      _showOcrFailure(chatNotifier, {'error': 'timeout'}, processingId);
    } catch (e) {
      if (!mounted) return;
      // ignore: avoid_print
      print('=== AZDAL DEBUG: OCR process FAILED — $e');
      _showOcrFailure(chatNotifier, {'error': 'unexpected', 'detail': e.toString()}, processingId);
    }
  }

  /// Show OCR failure state (State 3) with manual entry form.
  void _showOcrFailure(
    ChatProvider chatNotifier,
    Map<String, dynamic> ocrResult,
    String processingId,
  ) {
    // Remove the processing bubble, then add failure widget
    chatNotifier.removeMessage(processingId);
    chatNotifier.addBotMessage(
      '',
      widget: const {
        'widget': 'ocr_failure',
      },
    );
  }

  /// Show OCR result as compound_split_card or partial extraction.
  void _showOcrResult(
    ChatProvider chatNotifier,
    List<dynamic> items,
    dynamic total,
    String imagePath,
    String processingId,
  ) {
    // Remove the processing bubble — one bubble only, not three
    chatNotifier.removeMessage(processingId);
    // Convert items to compound_split_card format
    final splits = items.map<Map<String, dynamic>>((item) {
      final map = item as Map<String, dynamic>;
      final name = map['name'] as String? ?? '';
      final price = (map['price'] as num?)?.toInt() ?? 0;
      return {
        'category': name,
        'amount': price,
      };
    }).toList();

    final totalAmount = (total is num) ? total.toInt() : 0;

    // Store receipt path for later upload
    _capturedReceiptPath = imagePath;

    chatNotifier.addBotMessage(
      'تم استخراج ${items.length} بنود من الإيصال:',
      widget: {
        'widget': 'compound_split_card',
        'splits': splits,
        'total': totalAmount,
      },
    );
  }

  /// Upload receipt image to Supabase Storage.
  /// Path: /{user_id}/{timestamp}_receipt.jpg
  Future<String?> _uploadReceiptToStorage(String localPath) async {
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        // ignore: avoid_print
        print('=== AZDAL DEBUG: Receipt upload SKIPPED — no user');
        return null;
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final fileName = '${timestamp}_receipt.jpg';
      final storagePath = '$uid/$fileName';

      final file = File(localPath);
      if (!await file.exists()) return null;

      await client.storage.from('receipts').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
            ),
          );

      // ignore: avoid_print
      print('=== AZDAL DEBUG: Receipt uploaded — path=$storagePath');
      return storagePath;
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Receipt upload FAILED — $e');
      return null;
    }
  }

  /// Check for pending shared image (from system share sheet).
  /// Called once on init. Consumes and clears the pending path.
  void _checkPendingSharedImage() {
    final pendingPath = _getPendingSharedImage();
    if (pendingPath != null && mounted) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Processing pending shared image — '
          'path=$pendingPath');
      _processReceiptImage(pendingPath);
    }
  }

  /// Thread-safe accessor for the module-level pending shared image.
  /// Consumed once, then cleared.
  static String? _getPendingSharedImage() {
    return consumePendingSharedImage();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final voiceListeningState = ref.watch(voiceListeningProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('أزدل'),
        backgroundColor: _navy,
        foregroundColor: _white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Chat messages ──
          Expanded(
            child: chatState.messages.isEmpty && !_coldStartDone
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: chatState.messages.length +
                        (chatState.isLoading ? 1 : 0) +
                        (chatState.error != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Error bubble (shown at the end)
                      if (chatState.error != null &&
                          index == chatState.messages.length) {
                        return ErrorBubble(
                          message: 'حدث خطأ. حاول مرة أخرى.',
                          onRetry: () {
                            ref.read(chatProvider.notifier).clearError();
                          },
                        );
                      }

                      // Typing indicator (shown after messages, before error)
                      final typingOffset = chatState.error != null ? 1 : 0;
                      if (chatState.isLoading &&
                          index ==
                              chatState.messages.length - typingOffset) {
                        return const TypingIndicator();
                      }

                      // Adjust index past loading/error placeholders
                      final adjustedIndex = chatState.isLoading &&
                              index >= chatState.messages.length
                          ? chatState.messages.length - 1
                          : index.clamp(0, chatState.messages.length - 1);

                      if (adjustedIndex >= chatState.messages.length) {
                        return const SizedBox.shrink();
                      }

                      final message = chatState.messages[adjustedIndex];
                      return _MessageBubble(
                        message: message,
                        onWidgetAction: _handleWidgetAction,
                      );
                    },
                    // Auto-scroll to bottom
                    itemExtent: null,
                  ),
          ),

          // ── Offline banner ──
          if (!_isOnline) const OfflineBanner(),

          // ── Input bar ──
          _InputBar(
            controller: _textController,
            focusNode: _focusNode,
            isOnline: _isOnline,
            isListening: voiceListeningState.isListening,
            onSend: _sendMessage,
            onMic: _toggleVoice,
            onCamera: () {
              _pickReceiptImage();
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Empty State (first launch, before Cold Start)
// ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 64,
              color: _navy.withAlpha(100),
            ),
            const SizedBox(height: 16),
            const Text(
              'أهلاً بك في أزدل',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
                color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'مساعدك المالي الذكي. بدون تعب. بدون إدخال بيانات.',
              style: TextStyle(
                fontSize: 14,
                color: _muted,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'اكتب أول مصروف... أو استخدم الصوت 🎤',
              style: TextStyle(
                fontSize: 14,
                color: _navy.withAlpha(150),
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    this.onWidgetAction,
  });

  final ChatMessage message;
  final void Function(Map<String, dynamic>)? onWidgetAction;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              margin: EdgeInsets.only(
                left: isUser ? 16 : 40,
                right: isUser ? 40 : 16,
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  // Image thumbnail (receipt photo) — user messages only
                  if (message.isUser && message.hasImage)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _userBubbleBg,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(message.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              color: _userBubbleBg,
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: _muted, size: 32),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Text bubble
                  if (message.content.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? _userBubbleBg : _navy,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: isUser
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                          bottomLeft: const Radius.circular(16),
                          bottomRight: isUser
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: isUser ? _navy : _white,
                          fontSize: 14,
                          fontFamily: 'Cairo',
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),

                  // Widget (if present)
                  if (message.hasWidget)
                    renderCatalogWidget(
                      message.widget!,
                      onAction: onWidgetAction != null
                          ? (action) => onWidgetAction!({
                              ...action,
                              'message_id': message.id,
                            })
                          : null,
                    ),

                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Input Bar (fixed, 56px)
// ─────────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isOnline,
    required this.isListening,
    required this.onSend,
    required this.onMic,
    required this.onCamera,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isOnline;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onMic;
  final VoidCallback onCamera;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F5),
        border: Border(
          top: BorderSide(color: Color(0xFFE1E4E8)),
        ),
      ),
      child: SafeArea(
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // Send button (left in RTL = end)
            _SendButton(
              isOnline: widget.isOnline,
              hasText: _hasText,
              onSend: widget.onSend,
            ),
            const SizedBox(width: 8),

            // Text input
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Cairo',
                  color: Color(0xFF1B1B1F),
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب مصروف... أو اسأل سؤال',
                  hintStyle: const TextStyle(
                    color: _muted,
                    fontFamily: 'Cairo',
                  ),
                  filled: true,
                  fillColor: _white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: _cyan, width: 1.5),
                  ),
                ),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
            const SizedBox(width: 8),

            // Mic button
            _IconButton(
              icon: Icons.mic,
              isActive: widget.isListening,
              activeColor: _cyan,
              onTap: widget.onMic,
            ),
            const SizedBox(width: 4),

            // Camera button (Stage 3 — not yet implemented)
            _IconButton(
              icon: Icons.camera_alt_outlined,
              isActive: false,
              activeColor: _cyan,
              onTap: widget.onCamera,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Send Button
// ─────────────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isOnline,
    required this.hasText,
    required this.onSend,
  });

  final bool isOnline;
  final bool hasText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (isOnline && hasText) ? onSend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isOnline && hasText) ? _cyan : _muted,
        ),
        child: const Icon(
          Icons.arrow_upward,
          color: _white,
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Icon Button (mic, camera)
// ─────────────────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? activeColor.withAlpha(30) : Colors.transparent,
          border: Border.all(
            color: isActive ? activeColor : _muted,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : _muted,
          size: 20,
        ),
      ),
    );
  }
}
