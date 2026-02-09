import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized analytics service for tracking screen views and events.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ─── Screen Views ───────────────────────────────────────────
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      if (kDebugMode) print('📊 Screen: $screenName');
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Mentor Events ─────────────────────────────────────────
  static Future<void> logMentorSelected(String mentorId, String mentorName) async {
    try {
      await _analytics.logEvent(
        name: 'mentor_selected',
        parameters: {
          'mentor_id': mentorId,
          'mentor_name': mentorName,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logMentorMessageSent(String mentorId, String preset) async {
    try {
      await _analytics.logEvent(
        name: 'mentor_message_sent',
        parameters: {
          'mentor_id': mentorId,
          'preset': preset,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logMentorRealmSelected(String realmId) async {
    try {
      await _analytics.logEvent(
        name: 'mentor_realm_selected',
        parameters: {'realm_id': realmId},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Chat Events ───────────────────────────────────────────
  static Future<void> logChatOpened(String mentorId) async {
    try {
      await _analytics.logEvent(
        name: 'chat_opened',
        parameters: {'mentor_id': mentorId},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logChatMessageCopied(String mentorId) async {
    try {
      await _analytics.logEvent(
        name: 'chat_message_copied',
        parameters: {'mentor_id': mentorId},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Analysis Events ──────────────────────────────────────
  static Future<void> logAnalysisStarted(String mode, String tone) async {
    try {
      await _analytics.logEvent(
        name: 'analysis_started',
        parameters: {
          'mode': mode,
          'tone': tone,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logAnalysisCompleted(String mode, String tactic) async {
    try {
      await _analytics.logEvent(
        name: 'analysis_completed',
        parameters: {
          'mode': mode,
          'tactic_detected': tactic,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Council Events ───────────────────────────────────────
  static Future<void> logCouncilStarted() async {
    try {
      await _analytics.logEvent(name: 'council_started');
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logCouncilCompleted() async {
    try {
      await _analytics.logEvent(name: 'council_completed');
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Scan Events ──────────────────────────────────────────
  static Future<void> logScanStarted() async {
    try {
      await _analytics.logEvent(name: 'scan_started');
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logScanCompleted(String tactic) async {
    try {
      await _analytics.logEvent(
        name: 'scan_completed',
        parameters: {'tactic_detected': tactic},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Vault Events ─────────────────────────────────────────
  static Future<void> logVaultEntryViewed(String entryType) async {
    try {
      await _analytics.logEvent(
        name: 'vault_entry_viewed',
        parameters: {'entry_type': entryType},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logVaultEntryShared(String entryType) async {
    try {
      await _analytics.logEvent(
        name: 'vault_entry_shared',
        parameters: {'entry_type': entryType},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logVaultEntryCopied(String entryType) async {
    try {
      await _analytics.logEvent(
        name: 'vault_entry_copied',
        parameters: {'entry_type': entryType},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Subscription / Paywall Events ────────────────────────
  static Future<void> logPaywallViewed() async {
    try {
      await _analytics.logEvent(name: 'paywall_viewed');
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logSubscriptionStarted(String plan) async {
    try {
      await _analytics.logEvent(
        name: 'subscription_started',
        parameters: {'plan': plan},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logInviteCodeRedeemed(String code) async {
    try {
      await _analytics.logEvent(
        name: 'invite_code_redeemed',
        parameters: {'code': code},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Auth Events ──────────────────────────────────────────
  static Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Navigation Events ────────────────────────────────────
  static Future<void> logTabSelected(String tabName) async {
    try {
      await _analytics.logEvent(
        name: 'tab_selected',
        parameters: {'tab_name': tabName},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Onboarding Events ───────────────────────────────────
  static Future<void> logOnboardingStep(int step) async {
    try {
      await _analytics.logEvent(
        name: 'onboarding_step',
        parameters: {'step': step},
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> logOnboardingCompleted() async {
    try {
      await _analytics.logEvent(name: 'onboarding_completed');
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── Usage Limit Events ───────────────────────────────────
  static Future<void> logUsageLimitHit() async {
    try {
      await _analytics.logEvent(name: 'usage_limit_hit');
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // ─── User Properties ─────────────────────────────────────
  static Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  static Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }
}
