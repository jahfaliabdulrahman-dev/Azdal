import 'package:flutter/material.dart';

import 'package:azdal/app/brand.dart';
import 'package:azdal/features/account/account_screen.dart';
import 'package:azdal/features/chat/chat_screen.dart';
import 'package:azdal/features/courses/courses_screen.dart';

/// Tab shell. IndexedStack keeps ChatScreen mounted exactly once —
/// all chat state survives tab switches with ZERO changes to its
/// internals (ChatScreen's own Scaffold/AppBar nest cleanly inside
/// this body).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Default resizeToAvoidBottomInset (true): when the chat keyboard
      // opens, the NavigationBar rides above it — accepted for MVP.
      // Verify on device; if the founder dislikes it, set
      // resizeToAvoidBottomInset: false here and re-verify there is no
      // gap between the chat input bar and the keyboard.
      body: IndexedStack(
        index: _index,
        children: const [ChatScreen(), CoursesScreen(), AccountScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Brand.cyanTint,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Brand.navy),
            label: 'المحادثة',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: Brand.navy),
            label: 'الدورات',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Brand.navy),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
