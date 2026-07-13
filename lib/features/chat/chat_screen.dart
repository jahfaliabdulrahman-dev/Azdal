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

  /// Guard against double-tap on undo action.
  bool _isUndoing = false;

  /// Layer 1 history filter — every sent message is marked immediately
  /// so it won't leak into future sendMessage history. Classification
  /// results overwrite the placeholder later. Keyed by user message id.
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
  }

  // ── Cold Start ──

  Future<void> _checkColdStart() async {
    if (_coldStartDone) return;

    final chatState = ref.read(chatProvider);
    if (chatState.messages.isNotEmpty) return;

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

    final monthlyIncome = double.tryParse(income.toString()) ?? 0;
    final monthlyCommitments = double.tryParse(commitments.toString()) ?? 0;
    final monthlySpend = (double.tryParse(weeklySpend.toString()) ?? 0) * 4;

    final disposableAfterCommitments = monthlyIncome - monthlyCommitments;
    final spendRatio = disposableAfterCommitments > 0
        ? (monthlySpend / disposableAfterCommitments * 100).round()
        : 100;

    // DEC-022 (BRP): use LLM for personalized reaction, with hardcoded fallback
    final geminiService = ref.read(geminiServiceProvider);
    String insight;
    try {
      final reaction = await geminiService.reactToColdStart(
        spendRatio: spendRatio,
        disposableAfterCommitments: disposableAfterCommitments,
      );
      insight = (reaction.error == null && reaction.text.trim().isNotEmpty)
          ? reaction.text.trim()
          : _coldStartFallback(spendRatio);
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Cold start reaction FAILED — $e');
      insight = _coldStartFallback(spendRatio);
    }

    chatNotifier.addBotMessage(insight);

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

  String _coldStartFallback(int spendRatio) {
    if (spendRatio >= 70) {
      return 'تصرف $spendRatio% من دخلك قبل منتصف الشهر. خليني أساعدك — سجل أول عملية بالصوت أو الكتابة.';
    }
    return 'وضعك المالي معقول حالياً. تبي نبدأ نسجل أول عملية؟ اكتب أو استخدم الصوت 🎤';
  }

  // ── Message send (router-first — DEC-021 auto-save) ──

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (!_isOnline) {
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
    final hasDigit = RegExp(r'[0-9٠-٩]').hasMatch(text);

    // Add user message and mark for history filter
    final userMsgId = chatNotifier.addUserMessage(text);
    _storedClassifications[userMsgId] = <String, dynamic>{};

    final allMessages = ref.read(chatProvider).messages;
    final filteredHistory = allMessages.where((m) {
      if (!m.isUser) return true;
      if (m.id == userMsgId) return true;
      return !_storedClassifications.containsKey(m.id);
    }).toList();

    try {
      if (!hasDigit) {
        // ── Conversational coach path (no digit) ──
        final response = await geminiService.sendMessage(
          text,
          history: filteredHistory,
        );

        if (!mounted) return;

        if (response.hasError) {
          chatNotifier.setError(response.error!);
          _storedClassifications.remove(userMsgId);
          return;
        }

        if (response.widget != null) {
          final widgetType = response.widget!['widget'] as String?;
          final isTransactionWidget =
              widgetType == 'compound_split_card' || widgetType == 'action_buttons';

          if (!isTransactionWidget) {
            chatNotifier.addBotMessage(response.text, widget: response.widget);
            _storedClassifications.remove(userMsgId);
            return;
          }
          // Drop transaction widget — but this shouldn't happen on coach path
        }

        chatNotifier.addBotMessage(response.text);
        _storedClassifications.remove(userMsgId); // re-enter history
        return;
      }

      // ── Router path (message contains a digit) ──
      final classifyResponse = await geminiService.classifyTransaction(text);

      if (!mounted) return;

      final data = classifyResponse.widget;
      final kind = data?['kind'] as String?;

      switch (kind) {
        case 'transaction':
          final amount = data!['amount'];
          final amountNum = amount is int
              ? amount
              : (amount is String ? int.tryParse(amount) : null) ?? 0;
          final category = data['category'] as String? ?? 'متنوع';
          final tone = data['tone'] as String? ?? 'gray';
          final reply = data['reply'] as String?;

          await _saveAndAnnounceTransaction(
            chatNotifier,
            txResult: {
              'type': 'simple',
              'amount': amountNum,
              'category': category,
              'tone': tone,
            },
            replyText: (reply != null && reply.isNotEmpty)
                ? reply
                : 'تم تسجيل $amountNum ريال — $category',
          );
          break;

        case 'compound':
          // Keep placeholder in _storedClassifications — confirm reads
          // splits from widget action payload, not this map.
          final reply = data!['reply'] as String?;
          final splits = data['splits'] as List<dynamic>? ?? [];
          final widgetData = <String, dynamic>{
            'widget': 'compound_split_card',
            'splits': splits,
          };

          chatNotifier.addBotMessage(
            (reply != null && reply.isNotEmpty)
                ? reply
                : 'قسمت مصروفك 👇',
            widget: widgetData,
          );
          break;

        case 'clarify':
          final reply = data!['reply'] as String?;
          chatNotifier.addBotMessage(
            (reply != null && reply.isNotEmpty) ? reply : 'وش تقصد بالضبط؟',
          );
          _storedClassifications.remove(userMsgId); // re-enter history
          break;

        case 'chat':
        default:
          // Fall through to coach path — re-enter history
          _storedClassifications.remove(userMsgId);
          final response = await geminiService.sendMessage(
            text,
            history: filteredHistory,
          );
          if (!mounted) return;
          if (response.hasError) {
            chatNotifier.setError(response.error!);
            return;
          }
          chatNotifier.addBotMessage(response.text, widget: response.widget);
          break;
      }
    } catch (e) {
      if (!mounted) return;
      chatNotifier.setError(e.toString());
    }
  }

  /// Save a classified simple transaction and announce it immediately
  /// with the DEC-020 undo bubble. Auto-save — no confirm tap (DEC-021).
  Future<void> _saveAndAnnounceTransaction(
    ChatProvider chatNotifier, {
    required Map<String, dynamic> txResult,
    required String replyText,
  }) async {
    try {
      final txService = ref.read(transactionServiceProvider);
      final saved = await txService.saveTransaction(
        amount: (txResult['amount'] as num).toDouble(),
        category: txResult['category'] as String? ?? 'متنوع',
        tone: txResult['tone'] as String? ?? 'gray',
      );
      final txId = saved['id'] as String;

      chatNotifier.addBotMessage(
        replyText,
        widget: {
          'widget': 'action_buttons',
          'question': replyText,
          'buttons': [
            {'label': '↩️ تراجع', 'value': 'undo_transaction', 'type': 'secondary'},
          ],
          'tx_id': txId,
          'tx_type': 'simple',
        },
      );
    } catch (e) {
      if (mounted) chatNotifier.setError('فشل حفظ المعاملة: $e');
    }
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

        // Only undo_transaction survives DEC-021 (confirm/edit deleted).
        if (value == 'undo_transaction') {
          await _undoTransaction(action, chatNotifier);
        }
        break;

      case 'quick_input_form':
        final values = action['values'] as Map<String, dynamic>?;
        if (values != null) {
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
          chatNotifier.markWidgetAnswered(msgId, 'compound_split_cancel');
          chatNotifier.addBotMessage('تم الإلغاء.');
          break;
        }

        chatNotifier.markWidgetAnswered(msgId, 'compound_split_confirm');
        await _handleCompoundSplit(action, chatNotifier);
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
          await _handleOcrFailureSubmit(action, chatNotifier);
        } else if (ocrAction == 'ocr_retake') {
          // ignore: avoid_print
          print('=== AZDAL DEBUG: OCR retake requested');
          unawaited(_pickReceiptImage());
        }
        break;
    }
  }

  // ── Undo (DEC-020) ──

  Future<void> _undoTransaction(
    Map<String, dynamic> action,
    ChatProvider chatNotifier,
  ) async {
    if (_isUndoing) return;
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

  // ── Compound split (unchanged from DEC-020) ──

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

      chatNotifier.addBotMessage(
        'تم تسجيل ${splits.length} معاملات بنجاح ✅',
        widget: {
          'widget': 'action_buttons',
          'question': 'تم تسجيل ${splits.length} معاملات بنجاح ✅',
          'buttons': [
            {'label': '↩️ تراجع', 'value': 'undo_transaction', 'type': 'secondary'},
          ],
          'tx_id': groupId,
          'tx_type': 'group',
        },
      );
    } catch (e) {
      chatNotifier.setError(e.toString());
    }
  }

  // ── OCR failure manual entry ──

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
            {'label': '↩️ تراجع', 'value': 'undo_transaction', 'type': 'secondary'},
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

  String? _capturedReceiptPath;

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
        print('=== AZDAL DEBUG: Receipt image picked — path=${xFile.path}');
        await _processReceiptImage(xFile.path);
      }
    } catch (e) {
      print('=== AZDAL DEBUG: Image pick FAILED — $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر التقاط الصورة. تأكد من الصلاحيات.')),
        );
      }
    }
  }

  Future<void> _processReceiptImage(String imagePath) async {
    final chatNotifier = ref.read(chatProvider.notifier);

    chatNotifier.addUserMessage('📷 إيصال', imagePath: imagePath);

    final processingId = chatNotifier.addBotMessage(
      '',
      widget: const {'widget': 'ocr_processing'},
    );

    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        chatNotifier.setError('الصورة غير موجودة.');
        return;
      }

      final imageBytes = await imageFile.readAsBytes();

      final geminiService = ref.read(geminiServiceProvider);
      final ocrResult = await geminiService
          .ocrReceipt(imageBytes)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (ocrResult.containsKey('error')) {
        _showOcrFailure(chatNotifier, ocrResult, processingId);
        return;
      }

      final items = ocrResult['items'] as List<dynamic>? ?? [];
      final total = ocrResult['total'];
      final reply = ocrResult['reply'] as String?;

      if (items.isEmpty) {
        _showOcrFailure(chatNotifier, ocrResult, processingId);
        return;
      }

      _showOcrResult(chatNotifier, items, total, reply, imagePath, processingId);
    } on TimeoutException {
      if (!mounted) return;
      print('=== AZDAL DEBUG: OCR timed out after 10s');
      _showOcrFailure(chatNotifier, {'error': 'timeout'}, processingId);
    } catch (e) {
      if (!mounted) return;
      print('=== AZDAL DEBUG: OCR process FAILED — $e');
      _showOcrFailure(chatNotifier, {'error': 'unexpected', 'detail': e.toString()}, processingId);
    }
  }

  void _showOcrFailure(
    ChatProvider chatNotifier,
    Map<String, dynamic> ocrResult,
    String processingId,
  ) {
    chatNotifier.removeMessage(processingId);
    chatNotifier.addBotMessage(
      '',
      widget: const {'widget': 'ocr_failure'},
    );
  }

  void _showOcrResult(
    ChatProvider chatNotifier,
    List<dynamic> items,
    dynamic total,
    String? reply,
    String imagePath,
    String processingId,
  ) {
    chatNotifier.removeMessage(processingId);
    final splits = items.map<Map<String, dynamic>>((item) {
      final map = item as Map<String, dynamic>;
      final name = map['name'] as String? ?? '';
      final price = (map['price'] as num?)?.toInt() ?? 0;
      return {'category': name, 'amount': price};
    }).toList();

    final totalAmount = (total is num) ? total.toInt() : 0;
    _capturedReceiptPath = imagePath;

    final bubbleText = (reply != null && reply.trim().isNotEmpty)
        ? reply.trim()
        : 'تم استخراج ${items.length} بنود من الإيصال:';

    chatNotifier.addBotMessage(
      bubbleText,
      widget: {
        'widget': 'compound_split_card',
        'splits': splits,
        'total': totalAmount,
      },
    );
  }

  // ── Upload receipt to Supabase Storage ───────────────────────────

  Future<String?> _uploadReceiptToStorage(String localPath) async {
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
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
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      print('=== AZDAL DEBUG: Receipt uploaded — path=$storagePath');
      return storagePath;
    } catch (e) {
      print('=== AZDAL DEBUG: Receipt upload FAILED — $e');
      return null;
    }
  }

  void _checkPendingSharedImage() {
    final pendingPath = _getPendingSharedImage();
    if (pendingPath != null && mounted) {
      print('=== AZDAL DEBUG: Processing pending shared image — path=$pendingPath');
      _processReceiptImage(pendingPath);
    }
  }

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
                      if (chatState.error != null &&
                          index == chatState.messages.length) {
                        return ErrorBubble(
                          message: 'حدث خطأ. حاول مرة أخرى.',
                          onRetry: () {
                            ref.read(chatProvider.notifier).clearError();
                          },
                        );
                      }

                      final typingOffset = chatState.error != null ? 1 : 0;
                      if (chatState.isLoading &&
                          index == chatState.messages.length - typingOffset) {
                        return const TypingIndicator();
                      }

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
                    itemExtent: null,
                  ),
          ),

          if (!_isOnline) const OfflineBanner(),

          _InputBar(
            controller: _textController,
            focusNode: _focusNode,
            isOnline: _isOnline,
            isListening: voiceListeningState.isListening,
            onSend: _sendMessage,
            onMic: _toggleVoice,
            onCamera: _pickReceiptImage,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Empty State
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
            Icon(Icons.shield_outlined, size: 64, color: _navy.withAlpha(100)),
            const SizedBox(height: 16),
            const Text(
              'أهلاً بك في أزدل',
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700,
                fontFamily: 'Cairo', color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'مساعدك المالي الذكي. بدون تعب. بدون إدخال بيانات.',
              style: TextStyle(fontSize: 14, color: _muted, fontFamily: 'Cairo'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'اكتب أول مصروف... أو استخدم الصوت 🎤',
              style: TextStyle(fontSize: 14, color: _navy.withAlpha(150), fontFamily: 'Cairo'),
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
  const _MessageBubble({required this.message, this.onWidgetAction});
  final ChatMessage message;
  final void Function(Map<String, dynamic>)? onWidgetAction;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
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
                crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
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
                                child: Icon(Icons.broken_image, color: _muted, size: 32),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (message.content.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? _userBubbleBg : _navy,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                          bottomLeft: const Radius.circular(16),
                          bottomRight: isUser ? const Radius.circular(16) : const Radius.circular(4),
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
                  if (message.hasWidget)
                    renderCatalogWidget(
                      message.widget!,
                      onAction: onWidgetAction != null
                          ? (action) => onWidgetAction!({...action, 'message_id': message.id})
                          : null,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(color: _muted, fontSize: 10, fontFamily: 'Cairo'),
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
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Input Bar
// ─────────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller, required this.focusNode,
    required this.isOnline, required this.isListening,
    required this.onSend, required this.onMic, required this.onCamera,
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
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F5),
        border: Border(top: BorderSide(color: Color(0xFFE1E4E8))),
      ),
      child: SafeArea(
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            _SendButton(isOnline: widget.isOnline, hasText: _hasText, onSend: widget.onSend),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 14, fontFamily: 'Cairo', color: Color(0xFF1B1B1F)),
                decoration: InputDecoration(
                  hintText: 'اكتب مصروف... أو اسأل سؤال',
                  hintStyle: const TextStyle(color: _muted, fontFamily: 'Cairo'),
                  filled: true,
                  fillColor: _white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _cyan, width: 1.5),
                  ),
                ),
                maxLines: 3, minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
            const SizedBox(width: 8),
            _IconButton(
              icon: Icons.mic, isActive: widget.isListening, activeColor: _cyan,
              onTap: widget.onMic,
            ),
            const SizedBox(width: 4),
            _IconButton(
              icon: Icons.camera_alt_outlined, isActive: false, activeColor: _cyan,
              onTap: widget.onCamera,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isOnline, required this.hasText, required this.onSend});
  final bool isOnline;
  final bool hasText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (isOnline && hasText) ? onSend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isOnline && hasText) ? _cyan : _muted,
        ),
        child: const Icon(Icons.arrow_upward, color: _white, size: 20),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.isActive, required this.activeColor, required this.onTap});
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
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? activeColor.withAlpha(30) : Colors.transparent,
          border: Border.all(color: isActive ? activeColor : _muted, width: isActive ? 2 : 1),
        ),
        child: Icon(icon, color: isActive ? activeColor : _muted, size: 20),
      ),
    );
  }
}
