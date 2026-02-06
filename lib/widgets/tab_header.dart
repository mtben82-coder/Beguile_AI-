import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/theme.dart';

class TabHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const TabHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9333EA).withOpacity(0.15),
            Color(0xFF7C3AED).withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF8B5CF6),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Crystal ball emoji logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🔮',
                style: TextStyle(fontSize: 42),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // "Beguile AI" text
          Expanded(
            child: Text(
              'BEGUILE AI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 32,
                letterSpacing: 2.5,
                shadows: [
                  Shadow(
                    color: Color(0xFF8B5CF6).withOpacity(0.6),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // ── SUBSCRIBE CROWN ICON ──
          GestureDetector(
            onTap: () {
              context.push('/paywall');
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '👑',
                  style: TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
