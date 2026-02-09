import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/auth_providers.dart';
import '../../ui/pages/main_shell.dart';
import '../../ui/pages/scan/scan_page.dart';
import '../../ui/pages/council/council_page.dart';
import '../../ui/pages/mentors/mentors_page.dart';
import '../../ui/pages/analyze/analyze_page.dart';
import '../../ui/pages/profile/profile_page.dart';
import '../../ui/pages/settings/settings_page.dart';
import '../../ui/pages/onboarding/onboarding_page.dart';
import '../../ui/pages/auth/login_page.dart';
import '../../ui/pages/paywall/paywall_page.dart';
import '../../data/services/paywall_service.dart';
import '../../data/services/onboarding_service.dart';
import '../../data/services/analytics_service.dart';
import '../../ui/shared/loading_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    observers: [AnalyticsService.observer],
    initialLocation: '/onboarding', // New users start at onboarding
    redirect: (context, state) {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authStateProvider);
      
      final location = state.matchedLocation;
      final isOnLogin = location == '/login';
      final isOnSignup = location == '/signup';
      final isOnOnboarding = location == '/onboarding';
      final isOnRootOrHome = location == '/' || location == '/home';
      final isOnPaywall = location == '/paywall';

      // During auth loading - if onboarding complete, don't show it
      if (authState == AuthState.loading) {
        if (isOnOnboarding && OnboardingService.isCompleted) {
          return null; // Stay on current route, don't redirect
        }
        return null;
      }

      // If we're on root/home, immediately route based on auth state to avoid blank screen
      if (isOnRootOrHome) {
        if (authState == AuthState.authenticated) return '/mentors';
        // If onboarding already completed previously, skip to login
        return OnboardingService.isCompleted ? '/login' : '/onboarding';
      }

      // Unauthenticated: show onboarding first; allow onboarding -> paywall -> login
      if (authState == AuthState.unauthenticated) {
        if (isOnOnboarding || isOnPaywall || isOnLogin || isOnSignup) return null;
        // If onboarding already completed in a prior session, skip it this time
        return OnboardingService.isCompleted ? '/login' : '/onboarding';
      }

      // Authenticated: send to mentors from login/onboarding/paywall
      if (authState == AuthState.authenticated && (isOnLogin || isOnSignup || isOnOnboarding)) {
return '/mentors';
      }
      return null;
    },
    routes: [
      // Root alias (prevents 404 on initial load when state is still resolving)
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const LoadingShell(message: 'Initializing Beguile AI...'),
      ),
      // Alias: /home (no UI, just a path that gets redirected in redirect())
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const SizedBox.shrink(),
      ),

      // Login route (outside shell)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      // Signup route (outside shell)
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const LoginPage(initialSignUp: true),
      ),
      // Onboarding route (outside shell)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      // Paywall route (outside shell)
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        builder: (context, state) => const PaywallPage(),
      ),
      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/scan',
            name: 'scan',
            builder: (context, state) => const ScanPage(),
          ),
          GoRoute(
            path: '/council',
            name: 'council',
            builder: (context, state) => const CouncilPage(),
          ),
          GoRoute(
            path: '/mentors',
            name: 'mentors',
            builder: (context, state) => const MentorsPage(),
          ),
          GoRoute(
            path: '/analyze',
            name: 'analyze',
            builder: (context, state) => const AnalyzePage(),
          ),
          GoRoute(
            path: '/vault',
            name: 'vault',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
