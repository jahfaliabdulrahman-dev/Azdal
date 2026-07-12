import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/features/chat/chat_screen.dart';

void main() {
  testWidgets('ChatScreen renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    // Should show empty state
    expect(find.text('أهلاً بك في أزدل'), findsOneWidget);
    expect(find.text('مساعدك المالي الذكي. بدون تعب. بدون إدخال بيانات.'), findsOneWidget);

    // Input bar should be visible
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Input bar shows mic and camera buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    // Send button, mic, and camera icons should be present
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
  });
}
