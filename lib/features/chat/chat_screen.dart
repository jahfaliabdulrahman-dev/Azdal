import 'package:flutter/material.dart';

/// Placeholder chat screen — minimal scaffold.
///
/// Full chat UI is implemented in Stage 2. This screen is here so the
/// routing scaffold compiles and the app renders something meaningful.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ChatAppBar(),
      body: Center(
        child: Text(
          'مرحباً بك في أزدل',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('أزدل'),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
