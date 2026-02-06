import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/usage_limit_service.dart';

/// Call this BEFORE making any AI API request.
/// Returns true if the user can proceed. Returns false and shows paywall if limit hit.
Future<bool> checkUsageLimit(BuildContext context) async {
  final canUse = await UsageLimitService.canUse();

  if (!canUse) {
    // Show a brief message then navigate to paywall
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Daily Limit Reached',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'You\'ve used your 5 free sessions today.\n\nUpgrade to Beguile Pro for unlimited access to all mentors, scans, and analysis.',
            style: TextStyle(color: Colors.white70, height: 1.5),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/paywall');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Upgrade Now',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
    return false;
  }
  return true;
}

/// Call this AFTER a successful AI interaction to record usage.
Future<void> recordUsage() async {
  await UsageLimitService.recordUsage();
}
