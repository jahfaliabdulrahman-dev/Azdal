import 'package:go_router/go_router.dart';

import 'package:azdal/features/auth/login_screen.dart';
import 'package:azdal/features/auth/signup_screen.dart';
import 'package:azdal/features/bank/bank_link_flow_screen.dart';
import 'package:azdal/features/journey/journey_screen.dart';
import 'package:azdal/features/launch/onboarding_screen.dart';
import 'package:azdal/features/launch/splash_screen.dart';
import 'package:azdal/features/shell/main_shell.dart';

/// Application router.
///
/// Flow: / (splash) → /onboarding (first launch only) → /home (tab shell).
/// /bank-linking, /journey, /login, /signup are PUSHED on top of /home so
/// the system back button returns to the shell. Tabs inside /home are NOT
/// routes — they live in an IndexedStack so ChatScreen mounts exactly
/// once and keeps its state.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const MainShell()),
    GoRoute(
      path: '/bank-linking',
      builder: (context, state) => const BankLinkFlowScreen(),
    ),
    GoRoute(
      path: '/journey',
      builder: (context, state) => const JourneyScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
  ],
);
