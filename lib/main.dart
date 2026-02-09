import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
// ❌ removed: import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'data/services/cache_service.dart';
import 'core/taxonomy/tag_migration.dart';
import 'core/streak/streak_service.dart';
import 'app.dart';
import 'data/services/onboarding_service.dart';
import 'data/services/billing_service.dart';
import 'data/services/vault_service.dart';
import 'data/services/analytics_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ❌ removed dotenv load (no .env needed)
  // await dotenv.load(fileName: ".env");

  // Initialize Firebase (skip on Linux - not supported)
  if (!defaultTargetPlatform.toString().contains('linux')) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    print('⚠️ Skipping Firebase initialization on Linux (not supported)');
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Run tag migration to update old category names to new IDs
  await migrateTagNamesToIds();

  // Initialize streak service
  await StreakService.init();

  // Initialize cache service
  await CacheService.init();

  // Initialize onboarding service (reads flag)
  await OnboardingService.init();

  // Initialize vault service
  await VaultService.init();

  // Initialize billing (IAP) service (skip on web if fails)
  try {
    await BillingService.init();
  } catch (e) {
    print('Billing service init failed (likely web): $e');
  }

  // Set analytics user ID when auth state changes
  if (!defaultTargetPlatform.toString().contains('linux')) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        AnalyticsService.setUserId(user.uid);
      } else {
        AnalyticsService.setUserId(null);
      }
    });
  }

  runApp(
    const ProviderScope(
      child: BeguileApp(),
    ),
  );
}
