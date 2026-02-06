import 'package:shared_preferences/shared_preferences.dart';

class PaywallService {
  static const String _entitledKey = 'premium_entitled_v1';
  static const String _inviteCodeKey = 'premium_invite_code_v1';

  // Paywall bypass - set to true for free access, false to enforce paywall
  static const bool bypassPaywall = false;

  // Optional comma-separated invite codes (--dart-define=INVITE_CODES=CODE1,CODE2)
  static const String inviteCodesEnv =
      String.fromEnvironment('INVITE_CODES', defaultValue: '');

  static Future<bool> isEntitled() async {
    if (bypassPaywall) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_entitledKey) ?? false;
  }

  static Future<void> setEntitled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_entitledKey, value);
  }

  static Future<bool> redeemInvite(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return false;

    final allowed = inviteCodesEnv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final isValid = allowed.isEmpty
        ? (trimmed == 'BETA2025' || trimmed == 'FRIENDS')
        : allowed.any((c) => c.toLowerCase() == trimmed.toLowerCase());

    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_inviteCodeKey, trimmed);
      await prefs.setBool(_entitledKey, true);
      return true;
    }
    return false;
  }

  static Future<void> clearEntitlement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entitledKey);
    await prefs.remove(_inviteCodeKey);
  }
}
