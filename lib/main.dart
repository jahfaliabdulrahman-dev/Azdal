import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_router.dart';
import 'app/theme.dart';

void main() {
  runApp(const ProviderScope(child: AzdalApp()));
}

/// Root widget — RTL, light theme, MaterialApp.router + go_router.
class AzdalApp extends StatelessWidget {
  const AzdalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp.router(
        title: 'أزدل',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
