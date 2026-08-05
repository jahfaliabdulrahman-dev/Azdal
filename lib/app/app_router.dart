import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:azdal/features/auth/forgot_password_screen.dart';
import 'package:azdal/features/auth/login_screen.dart';
import 'package:azdal/features/auth/signup_screen.dart';
import 'package:azdal/features/bank/bank_link_flow_screen.dart';
import 'package:azdal/features/journey/journey_screen.dart';
import 'package:azdal/features/launch/onboarding_screen.dart';
import 'package:azdal/features/launch/splash_screen.dart';
import 'package:azdal/features/shell/main_shell.dart';

/// Protected routes an unauthenticated user may not reach (DEC-051).
const _protected = {'/home', '/bank-linking', '/journey'};

/// Auth screens a signed-in user should be bounced away from.
const _authScreens = {'/login', '/signup'};

/// Application router.
///
/// DEC-051: login is required from first launch. The [redirect] gate sends any
/// unauthenticated attempt to reach a protected route to /login, and bounces a
/// signed-in user off the auth screens back to /home. Splash (`/`) still shows
/// briefly, then routes to /home where the gate takes over.
///
/// /bank-linking, /journey, /login, /signup are PUSHED on top of /home so the
/// system back button returns to the shell. Tabs inside /home are NOT routes —
/// they live in an IndexedStack so ChatScreen mounts exactly once.
final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: _AuthRefresh(),
  redirect: (context, state) {
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    final loc = state.matchedLocation;
    if (!loggedIn && _protected.contains(loc)) return '/login';
    if (loggedIn && _authScreens.contains(loc)) return '/home';
    return null;
  },
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
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
  ],
);

/// Re-runs the router's [redirect] whenever auth state changes (login/logout),
/// so a successful login on /login immediately moves to /home and a sign-out
/// from anywhere falls back to /login.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    _sub = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
