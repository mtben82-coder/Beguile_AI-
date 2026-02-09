import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';
import '../../../data/services/paywall_service.dart';
import '../../../data/services/billing_service.dart';
import '../../../data/services/analytics_service.dart';

final entitlementProvider = FutureProvider<bool>((ref) async {
  return PaywallService.isEntitled();
});

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage>
    with SingleTickerProviderStateMixin {
  String _selectedPlan = 'monthly';
  bool _isProcessing = false;
  final TextEditingController _inviteController = TextEditingController();
  Map<String, dynamic> _products = const {};
  late AnimationController _animController;

  @override
  void dispose() {
    _inviteController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('paywall_page');
    AnalyticsService.logPaywallViewed();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _initBilling();
  }

  Future<void> _initBilling() async {
    await BillingService.init();
    final products = await BillingService.loadProductsByPlan();
    if (!mounted) return;
    setState(() {
      _products = products;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entitledAsync = ref.watch(entitlementProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: WFGradients.paywallBackground,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: _buildGlassCard(entitledAsync),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(AsyncValue<bool> entitledAsync) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26FFFFFF), // white at 15% opacity
                blurRadius: 60,
                spreadRadius: -10,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHero(),
              const SizedBox(height: 24),
              _buildPlans(),
              const SizedBox(height: 16),
              _buildFeatures(),
              const SizedBox(height: 16),
              _buildInviteUnlock(),
              const SizedBox(height: 24),
              _buildCTA(entitledAsync),
              const SizedBox(height: 8),
              _buildRestoreButton(),
              const SizedBox(height: 16),
              _buildFooter(),
              const SizedBox(height: 8),
              _buildTrustBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6EE7B7), Color(0xFFE879F9)],
          ).createShader(bounds),
          child: Text(
            'Unlock Beguile AI',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Train with your mentors. Decode anyone. Dominate every conversation.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlans() {
    final monthlyLabel = _products['monthly']?.price ?? '£8.99';
    final yearlyLabel = _products['yearly']?.price ?? '£89.99';

    return Row(
      children: [
        Expanded(
          child: _buildPlanCard(
            'monthly',
            '$monthlyLabel/mo',
            'Cancel anytime',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPlanCard(
            'yearly',
            '$yearlyLabel/yr',
            '2 months free',
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(String id, String price, String tag) {
    final isSelected = _selectedPlan == id;
    final isMonthly = id == 'monthly';

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (isMonthly ? WFGradients.monthlyPlan : WFGradients.yearlyPlan)
              : null,
          color: !isSelected ? const Color(0xFF0B0F15) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isMonthly ? const Color(0xFFE879F9) : const Color(0xFF34D399))
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? (isMonthly ? WFShadows.fuchsiaGlow : WFShadows.emeraldGlow)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              price,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tag,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      _FeatureData('🧠', 'Pattern Analysis', 'Decode manipulation and emotional framing instantly.'),
      _FeatureData('👑', 'Mentor Guidance', 'Chat with legendary AI mentors inspired by history\'s greatest minds.'),
      _FeatureData('💬', 'Message Mastery', 'Craft irresistible lines that command attention and respect.'),
      _FeatureData('⚔️', 'Council Mode', 'Watch mentors debate and evolve the perfect response for you.'),
      _FeatureData('🔮', 'Psy-Ops Scan', 'Run message autopsies to reveal hidden power plays.'),
      _FeatureData('📱', 'Offline-Ready', 'Your private vault stays accessible even without signal.'),
    ];

    return Column(
      children: List.generate(
        features.length,
        (i) => _buildFeatureCard(features[i], i),
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureData feature, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Interval(index * 0.05, 1.0, curve: Curves.easeOut),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F15).withOpacity(0.8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    feature.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                        Text(
                          feature.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          feature.desc,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                            height: 1.3,
                      ),
                    ),
                  ],
                ),
                  ),
        ],
      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInviteUnlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Have an invite code?',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inviteController,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter code to unlock...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0B0F15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE879F9),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildRedeemButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildRedeemButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _onRedeem,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD946EF), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Redeem',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildCTA(AsyncValue<bool> entitledAsync) {
    final entitled = entitledAsync.value ?? false;
    final bypassed = PaywallService.bypassPaywall;
    final shouldShowContinue = entitled || bypassed;

    return GestureDetector(
      onTap: _isProcessing ? null : () => _onSubscribe(shouldShowContinue),
      child: Container(
      width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: WFGradients.ctaButton,
          borderRadius: BorderRadius.circular(16),
          boxShadow: WFShadows.whiteGlow,
        ),
        child: _isProcessing
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Text(
                shouldShowContinue ? 'Continue' : 'Unlock Access',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _onRestore,
      child: Text(
        'Restore purchases',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white.withOpacity(0.6),
          decoration: TextDecoration.underline,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'Cancel anytime • Private training unlocked instantly',
      style: GoogleFonts.inter(
        fontSize: 12,
        color: Colors.white.withOpacity(0.5),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTrustBadge() {
    return Text.rich(
      TextSpan(
        text: 'Trusted by ',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white.withOpacity(0.4),
        ),
        children: [
          TextSpan(
            text: '187K+',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE879F9),
            ),
          ),
          TextSpan(
            text: ' initiates worldwide',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _onSubscribe(bool shouldShowContinue) async {
    if (shouldShowContinue) {
      // Already entitled or bypassed, go to login
                  context.go('/login');
                  return;
                }

                setState(() => _isProcessing = true);
                final ok = await BillingService.buyPlan(_selectedPlan);
                setState(() => _isProcessing = false);
    
                if (!mounted) return;
    
                if (ok) {
      ref.invalidate(entitlementProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscription activated')),
                  );
      context.go('/login');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchase failed or canceled')),
                  );
                }
  }

  Future<void> _onRedeem() async {
    setState(() => _isProcessing = true);
    final code = _inviteController.text;
    final ok = await PaywallService.redeemInvite(code);
    setState(() => _isProcessing = false);
    
    if (!mounted) return;
    
    if (ok) {
      ref.invalidate(entitlementProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite accepted. Access unlocked.')),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code.')),
      );
    }
  }

  Future<void> _onRestore() async {
              setState(() => _isProcessing = true);
              final ok = await BillingService.restorePurchases();
              setState(() => _isProcessing = false);
    
              if (!mounted) return;
    
    if (ok) {
      ref.invalidate(entitlementProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchases restored')),
      );
      context.go('/login');
    } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No active purchases found')),
                );
              }
  }
}

class _FeatureData {
  final String icon;
  final String title;
  final String desc;

  _FeatureData(this.icon, this.title, this.desc);
}
