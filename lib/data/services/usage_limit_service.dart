import 'package:shared_preferences/shared_preferences.dart';
import 'paywall_service.dart';

/// Tracks daily free usage. Free users get 5 AI interactions per day.
/// After hitting the limit, the paywall is triggered.
class UsageLimitService {
  static const int dailyFreeLimit = 5;
  static const String _usageCountKey = 'daily_usage_count_v1';
  static const String _usageDateKey = 'daily_usage_date_v1';

  /// Check if the user can make another free request.
  /// Returns true if they have remaining uses OR are a paying subscriber.
  static Future<bool> canUse() async {
    // Paying users have unlimited access
    if (await PaywallService.isEntitled()) return true;

    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final storedDate = prefs.getString(_usageDateKey) ?? '';

    // New day = reset counter
    if (storedDate != today) {
      await prefs.setString(_usageDateKey, today);
      await prefs.setInt(_usageCountKey, 0);
      return true;
    }

    final count = prefs.getInt(_usageCountKey) ?? 0;
    return count < dailyFreeLimit;
  }

  /// Record one usage. Call this AFTER a successful AI interaction.
  static Future<void> recordUsage() async {
    // Don't count usage for paying users
    if (await PaywallService.isEntitled()) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final storedDate = prefs.getString(_usageDateKey) ?? '';

    if (storedDate != today) {
      await prefs.setString(_usageDateKey, today);
      await prefs.setInt(_usageCountKey, 1);
    } else {
      final count = prefs.getInt(_usageCountKey) ?? 0;
      await prefs.setInt(_usageCountKey, count + 1);
    }
  }

  /// Get remaining free uses for today.
  static Future<int> remainingUses() async {
    if (await PaywallService.isEntitled()) return -1; // unlimited

    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final storedDate = prefs.getString(_usageDateKey) ?? '';

    if (storedDate != today) return dailyFreeLimit;

    final count = prefs.getInt(_usageCountKey) ?? 0;
    return (dailyFreeLimit - count).clamp(0, dailyFreeLimit);
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
