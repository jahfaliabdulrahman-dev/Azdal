import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/features/chat/providers/chat_provider.dart';
import 'package:azdal/features/chat/models/chat_message.dart';

void main() {
  late ChatProvider provider;

  setUp(() {
    provider = ChatProvider();
  });

  group('ChatProvider', () {
    test('initial state is empty', () {
      expect(provider.state.messages, isEmpty);
      expect(provider.state.isLoading, isFalse);
      expect(provider.state.error, isNull);
    });

    test('addUserMessage appends message and sets isLoading', () {
      provider.addUserMessage('مرحباً');
      expect(provider.state.messages.length, 1);
      expect(provider.state.messages.first.content, 'مرحباً');
      expect(provider.state.messages.first.role, 'user');
      expect(provider.state.isLoading, isTrue);
    });

    test('addBotMessage appends message and clears isLoading', () {
      provider.addUserMessage('مرحباً');
      provider.addBotMessage('أهلاً بك');
      expect(provider.state.messages.length, 2);
      expect(provider.state.messages.last.content, 'أهلاً بك');
      expect(provider.state.messages.last.role, 'bot');
      expect(provider.state.isLoading, isFalse);
    });

    test('addBotMessage with widget payload', () {
      provider.addBotMessage('test', widget: {'widget': 'summary_card'});
      expect(provider.state.messages.last.hasWidget, isTrue);
      expect(provider.state.messages.last.widget?['widget'], 'summary_card');
    });

    test('setError sets error field and clears isLoading', () {
      provider.addUserMessage('test');
      expect(provider.state.isLoading, isTrue);
      provider.setError('Network error');
      expect(provider.state.error, 'Network error');
      expect(provider.state.isLoading, isFalse);
    });

    test('clearError clears the error', () {
      provider.setError('error');
      provider.clearError();
      expect(provider.state.error, isNull);
    });

    test('reset clears all state', () {
      provider.addUserMessage('test');
      provider.reset();
      expect(provider.state.messages, isEmpty);
      expect(provider.state.isLoading, isFalse);
      expect(provider.state.error, isNull);
    });
  });

  group('ChatMessage', () {
    test('isUser and isBot convenience getters', () {
      final userMsg = ChatMessage(
        id: '1',
        role: 'user',
        content: 'hello',
        timestamp: DateTime.now(),
      );
      final botMsg = ChatMessage(
        id: '2',
        role: 'bot',
        content: 'hi',
        timestamp: DateTime.now(),
      );

      expect(userMsg.isUser, isTrue);
      expect(userMsg.isBot, isFalse);
      expect(botMsg.isUser, isFalse);
      expect(botMsg.isBot, isTrue);
    });

    test('hasWidget returns true only when widget is non-empty', () {
      final noWidget = ChatMessage(
        id: '1',
        role: 'bot',
        content: 'test',
        timestamp: DateTime.now(),
      );
      final withWidget = ChatMessage(
        id: '2',
        role: 'bot',
        content: 'test',
        widget: {'widget': 'bar_chart'},
        timestamp: DateTime.now(),
      );
      final emptyWidget = ChatMessage(
        id: '3',
        role: 'bot',
        content: 'test',
        widget: {},
        timestamp: DateTime.now(),
      );

      expect(noWidget.hasWidget, isFalse);
      expect(withWidget.hasWidget, isTrue);
      expect(emptyWidget.hasWidget, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final original = ChatMessage(
        id: '1',
        role: 'user',
        content: 'hello',
        timestamp: DateTime(2024, 1, 1),
      );

      final copy = original.copyWith(content: 'updated');
      expect(copy.id, '1');
      expect(copy.role, 'user');
      expect(copy.content, 'updated');
      expect(copy.timestamp, DateTime(2024, 1, 1));
      expect(copy.hasWidget, isFalse);
    });
  });
}
