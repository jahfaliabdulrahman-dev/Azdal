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

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
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

    if (voiceService.isListening) {
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
    if (mounted) setState(() {});
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
          // Store classification for later confirm — avoids
          // a second (non-deterministic) Gemini call in _confirmTransaction
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
      if (!RegExp(r'\d+').hasMatch(text)) return null;

      // Use Gemini to extract transaction details
      final classifyPrompt = '''
صنف المعاملة التالية واستخرج:
- amount (رقم)
- category (فئة)
- subcategory (فئة فرعية)
- tone (green/gray/red)

إذا كانت تحتوي على عدة عناصر، استخدم compound_split_card.
إذا لم تكن معاملة مالية، أجب بـ "NOT_TRANSACTION".

المعاملة: $text
''';

      final response = await geminiService.sendMessage(classifyPrompt);

      if (response.widget != null) {
        final widgetType = response.widget!['widget'] as String?;

        if (widgetType == 'compound_split_card') {
          return {'type': 'compound', 'widget': response.widget};
        }

        // Try to find amount in response
        final amountMatch = RegExp(r'(\d+)').firstMatch(response.text);
        if (amountMatch != null) {
          return {
            'type': 'simple',
            'amount': int.parse(amountMatch.group(1)!),
            'category': 'متنوع',
            'tone': 'gray',
            'response_text': response.text,
          };
        }
      }

      // Check response for classification hints
      if (response.text.contains('NOT_TRANSACTION') ||
          response.text.contains('ليست معاملة')) {
        return null;
      }

      // Try to extract amount from original response
      final amountMatch = RegExp(r'(\d+)').firstMatch(response.text);
      if (amountMatch != null) {
        return {
          'type': 'simple',
          'amount': int.parse(amountMatch.group(1)!),
          'category': 'متنوع',
          'tone': 'gray',
          'response_text': response.text,
        };
      }

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Auto-classify FAILED — $e');
      return null;
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
        if (_isConfirming) break; // Guard: prevent double-tap
        if (value == 'confirm') {
          // Confirm transaction: save to Supabase
          await _confirmTransaction(chatNotifier);
        } else if (value == 'edit') {
          chatNotifier.addBotMessage('تمام — وش التصنيف الصح؟ اكتب التصنيف الجديد.');
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
        await _handleCompoundSplit(action, chatNotifier);
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
      await txService.saveTransaction(
        amount: (txResult['amount'] as num).toDouble(),
        category: txResult['category'] as String? ?? 'متنوع',
        tone: txResult['tone'] as String? ?? 'gray',
      );

      chatNotifier.addBotMessage('تم تسجيل المعاملة بنجاح ✅');
    } catch (e) {
      chatNotifier.setError('فشل حفظ المعاملة: $e');
    } finally {
      _isConfirming = false;
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

      await txService.saveCompoundSplits(splits: splitData);
      chatNotifier.addBotMessage(
        'تم تسجيل ${splits.length} معاملات بنجاح ✅',
      );
    } catch (e) {
      chatNotifier.setError(e.toString());
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final voiceService = ref.watch(voiceServiceProvider);

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
            isListening: voiceService.isListening,
            onSend: _sendMessage,
            onMic: _toggleVoice,
            onCamera: () {
              // NOT IMPLEMENTED — Stage 3 OCR
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
                      onAction: onWidgetAction,
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
