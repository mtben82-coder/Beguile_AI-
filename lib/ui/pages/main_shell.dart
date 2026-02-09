import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/providers/auth_providers.dart';
import '../../core/theme/theme.dart';
import '../../data/services/analytics_service.dart';
import '../shared/loading_shell.dart';
import 'onboarding/onboarding_page.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final authState = ref.watch(authStateProvider);

    return profileAsync.when(
      data: (profile) {
        // Always show the main shell here; onboarding is handled before login
        return _MainShellContent(child: child);
      },
      loading: () => const LoadingShell(),
      error: (error, stack) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: WFColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile',
                  style: WFTextStyles.h3.copyWith(color: WFColors.error),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: WFTextStyles.bodyMedium.copyWith(color: WFColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MainShellContent extends StatelessWidget {
  final Widget child;

  const _MainShellContent({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WFColors.base,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: WFColors.glassLight,
          border: Border(top: BorderSide(color: WFColors.glassBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 25,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: WFColors.primary,
          unselectedItemColor: WFColors.textTertiary,
          currentIndex: _getCurrentIndex(context),
          onTap: (index) => _onItemTapped(context, index),
          items: const [
            BottomNavigationBarItem(
              icon: Text('👑', style: TextStyle(fontSize: 20)),
              label: 'Mentors',
            ),
            BottomNavigationBarItem(
              icon: Text('🕵️‍♀️', style: TextStyle(fontSize: 20)),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Text('🧠', style: TextStyle(fontSize: 20)),
              label: 'Council',
            ),
            BottomNavigationBarItem(
              icon: Text('🧩', style: TextStyle(fontSize: 20)),
              label: 'Analyze',
            ),
            BottomNavigationBarItem(
              icon: Text('🔒', style: TextStyle(fontSize: 20)),
              label: 'Vault',
            ),
            BottomNavigationBarItem(
              icon: Text('⚙️', style: TextStyle(fontSize: 20)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/mentors')) return 0;
    if (location.startsWith('/scan')) return 1;
    if (location.startsWith('/council')) return 2;
    if (location.startsWith('/analyze')) return 3;
    if (location.startsWith('/vault')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    const tabNames = ['mentors', 'scan', 'council', 'analyze', 'vault', 'settings'];
    AnalyticsService.logTabSelected(tabNames[index]);
    switch (index) {
      case 0:
        context.goNamed('mentors');
        break;
      case 1:
        context.goNamed('scan');
        break;
      case 2:
        context.goNamed('council');
        break;
      case 3:
        context.goNamed('analyze');
        break;
      case 4:
        context.goNamed('vault');
        break;
      case 5:
        context.goNamed('settings');
        break;
    }
  }
}
