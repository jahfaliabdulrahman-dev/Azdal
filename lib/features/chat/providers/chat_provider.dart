/// Chat state and provider for Azdal.
///
/// Manages the full chat message list, loading/error state, and
/// exposes mutators for adding user/bot messages and toggling state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';

// ─────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────

/// Immutable state for the chat feature.
final class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  /// All chat messages in chronological order.
  final List<ChatMessage> messages;

  /// Whether the AI is currently processing a request.
  final bool isLoading;

  /// Optional error string (shown via ErrorBubble when non-null).
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────

/// [StateNotifier] managing the chat message list and UI state.
final class ChatProvider extends StateNotifier<ChatState> {
  ChatProvider() : super(const ChatState());

  /// Append a user message and enter loading state.
  /// [imagePath] optionally attaches a receipt photo (Stage 3 OCR).
  /// Returns the generated message id.
  String addUserMessage(String text, {String? imagePath}) {
    final message = ChatMessage(
      id: _uuid(),
      role: 'user',
      content: text,
      imagePath: imagePath,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, message],
      isLoading: true,
      clearError: true,
    );
    // ignore: avoid_print
    print('=== AZDAL DEBUG: User message added — id=${message.id} '
        'hasImage=${message.hasImage} '
        'content="${message.content.length > 40 ? '${message.content.substring(0, 40)}...' : message.content}"');
    return message.id;
  }

  /// Append a bot message (optionally with a widget payload) and exit loading.
  /// Returns the generated message id.
  String addBotMessage(String text, {Map<String, dynamic>? widget}) {
    final message = ChatMessage(
      id: _uuid(),
      role: 'bot',
      content: text,
      widget: widget,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, message],
      isLoading: false,
      clearError: true,
    );
    // ignore: avoid_print
    print('=== AZDAL DEBUG: Bot message added — id=${message.id} '
        'hasWidget=${message.hasWidget}');
    return message.id;
  }

  /// Remove a message by its [id].
  ///
  /// If no message with that id exists, this is a no-op.
  /// The UI rebuilds reactively — the bubble disappears from the list.
  void removeMessage(String id) {
    final index = state.messages.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final updated = <ChatMessage>[...state.messages];
    updated.removeAt(index);
    state = state.copyWith(messages: updated);
    // ignore: avoid_print
    print('=== AZDAL DEBUG: Message removed — id=$id');
  }

  /// Mark a message's widget as answered/consumed.
  ///
  /// Merges `_answered: true` and `_selectedValue` into the message's
  /// widget map so renderers can disable all buttons and highlight the
  /// selected one.  Used to prevent duplicate actions after the first tap.
  void markWidgetAnswered(String messageId, String selectedValue) {
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final message = state.messages[index];
    final updatedWidget = <String, dynamic>{
      ...?message.widget,
      '_answered': true,
      '_selectedValue': selectedValue,
    };
    final updated = <ChatMessage>[...state.messages];
    updated[index] = message.copyWith(widget: updatedWidget);
    state = state.copyWith(messages: updated);
    // ignore: avoid_print
    print('=== AZDAL DEBUG: Widget marked answered — id=$messageId '
        'selected=$selectedValue');
  }

  /// Set the error field (shown as ErrorBubble) without adding a message.
  /// The loading flag is cleared so the typing indicator disappears.
  void setError(String message) {
    state = state.copyWith(
      isLoading: false,
      error: message,
    );
    // ignore: avoid_print
    print('=== AZDAL DEBUG: Chat error set — $message');
  }

  /// Clear the current error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset the chat to empty (used for testing / cold start).
  void reset() {
    state = const ChatState();
  }

  // ── Private helpers ──

  static String _uuid() {
    // simple enough for MVP — no external uuid package needed
    final now = DateTime.now().microsecondsSinceEpoch;
    final hash = now.toRadixString(36);
    return '$hash-${identityHashCode(DateTime.now())}';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────

/// The canonical [ChatProvider] instance for the app.
///
/// NOT auto-disposed — the chat state must survive widget rebuilds
/// during navigation (DEC-034: no autoDispose on shared controllers).
final chatProvider = StateNotifierProvider<ChatProvider, ChatState>(
  (ref) => ChatProvider(),
);
