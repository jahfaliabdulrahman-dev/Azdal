import 'package:go_router/go_router.dart';
import 'package:azdal/features/chat/chat_screen.dart';

/// Application router — single route for the chat screen.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ChatScreen(),
    ),
  ],
);
