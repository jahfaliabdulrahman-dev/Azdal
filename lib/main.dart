import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_router.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kqhyjngtquutzdvjfbnf.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtxaHlqbmd0cXV1dHpkdmpmYm5mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE5NjYxMjMsImV4cCI6MjA2NzU0MjEyM30.bP4rPq7IFb2fnmCrYqhziQ7hBa48o6rIlEULskL6Bik',
  );

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
