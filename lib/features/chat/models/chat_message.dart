/// Chat message model for Azdal.
///
/// Represents a single message in the chat flow — either from the user or
/// the AI bot.  Bot messages may carry an optional [widget] payload (JSON map)
/// to be rendered inline via the widget catalog.
library;

/// The chat message model.
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.widget,
    required this.timestamp,
  });

  /// Unique message identifier.
  final String id;

  /// 'user' or 'bot'.
  final String role;

  /// Plain-text message body (shown in the chat bubble).
  final String content;

  /// Optional widget payload in JSON-map form.
  /// When present the UI renders the corresponding widget from the catalog
  /// instead of (or in addition to) the plain-text bubble.
  final Map<String, dynamic>? widget;

  /// When this message was created.
  final DateTime timestamp;

  /// Convenience: is this a user message?
  bool get isUser => role == 'user';

  /// Convenience: is this a bot message?
  bool get isBot => role == 'bot';

  /// Convenience: does this message carry a widget payload?
  bool get hasWidget => widget != null && widget!.isNotEmpty;

  /// Copy with optional overrides.
  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    Map<String, dynamic>? widget,
    bool clearWidget = false,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      widget: clearWidget ? null : (widget ?? this.widget),
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() =>
      'ChatMessage(id=$id, role=$role, content=${content.length > 50 ? '${content.substring(0, 50)}...' : content}, hasWidget=$hasWidget)';
}
