import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'core/routing/app_router.dart';
import 'data/services/analytics_service.dart';

class BeguileApp extends ConsumerWidget {
  const BeguileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Beguile AI',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: WFTheme.darkTheme,
    );
  }
}
