import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';
import '../../../data/services/constants.dart';
import '../../../data/services/analytics_service.dart';
import 'mentorverse_intro.dart';

/* ─────────────────────── SLIDE DATA ─────────────────────── */
class OnboardingSlide {
  final String title;
  final String subtitle;
  final String text;
  final String cta;
  final LinearGradient gradient;

  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.text,
    required this.cta,
    required this.gradient,
  });
}

final List<OnboardingSlide> _slides = [
  OnboardingSlide(
    title: 'Beguile AI',
    subtitle: 'The Art of Influence',
    text: 'Every word you send shapes perception. Most people text — you will command.',
    cta: 'Enter the Chamber',
    gradient: WFGradients.onboardingSlide1,
  ),
  OnboardingSlide(
    title: 'This is not a chat app. It\'s a weapon.',
    subtitle: 'Psychological Warfare',
    text: 'Learn the persuasion frameworks of legends — the patterns that built empires and broke hearts.',
    cta: 'Meet the Masters',
    gradient: WFGradients.onboardingSlide2,
  ),
  OnboardingSlide(
    title: 'The Six Mentors',
    subtitle: 'Legends Reforged',
    text: '⚔️ Sun Tzu — The strategist.\n👑 Machiavelli — The political predator.\n💋 Casanova — The seducer.\n⎈ Aurelius — The stoic ruler.\n💎 Cleopatra — The magnetic queen.\n🌹 Monroe — The softness that conquers.',
    cta: 'Witness the Debate',
    gradient: WFGradients.onboardingSlide3,
  ),
  OnboardingSlide(
    title: 'When legends clash, wisdom ignites.',
    subtitle: 'Council Mode',
    text: 'Watch mentors argue in real-time to craft the perfect response — merging charisma, precision, and power.',
    cta: 'See Your Power',
    gradient: WFGradients.onboardingSlide4,
  ),
  OnboardingSlide(
    title: 'Every message hides a secret.',
    subtitle: 'Psy-Ops Scan',
    text: 'Paste any conversation. Our AI X-Ray exposes hidden motives — manipulation, frame control, or weakness.',
    cta: 'Unlock Your Analysis',
    gradient: WFGradients.onboardingSlide5,
  ),
  OnboardingSlide(
    title: 'Seduce. Persuade. Dominate.',
    subtitle: 'Your Mind — Upgraded',
    text: 'Beguile AI is your mentor, analyst, and mirror. From dating to strategy — become the most dangerous version of you.',
    cta: 'Begin Training',
    gradient: WFGradients.onboardingSlide6,
  ),
];

/* ─────────────────────── MENTOR DATA ─────────────────────── */
class MentorData {
  final String name;
  final String asset;
  final Color themeColor;
  final String quote;

  const MentorData({
    required this.name,
    required this.asset,
    required this.themeColor,
    required this.quote,
  });
}

final List<MentorData> _mentors = [
  MentorData(
    name: 'Sun Tzu',
    asset: 'assets/images/mentors/sun_tzu.png',
    themeColor: WFColors.mentorSunTzu,
    quote: 'Appear weak when you are strong, and strong when you are weak.',
  ),
  MentorData(
    name: 'Machiavelli',
    asset: 'assets/images/mentors/machiavelli.png',
    themeColor: WFColors.mentorMachiavelli,
    quote: 'Never attempt to win by force what can be won by deception.',
  ),
  MentorData(
    name: 'Casanova',
    asset: 'assets/images/mentors/casanova.png',
    themeColor: WFColors.mentorCasanova,
    quote: 'Love is three-quarters curiosity.',
  ),
  MentorData(
    name: 'Marcus Aurelius',
    asset: 'assets/images/mentors/marcus_aurelius.png',
    themeColor: WFColors.mentorAurelius,
    quote: 'You have power over your mind — not outside events.',
  ),
  MentorData(
    name: 'Cleopatra',
    asset: 'assets/images/mentors/cleopatra.png',
    themeColor: WFColors.mentorCleopatra,
    quote: 'I will not be triumphed over.',
  ),
  MentorData(
    name: 'Marilyn Monroe',
    asset: 'assets/images/mentors/monroe.png',
    themeColor: WFColors.mentorMonroe,
    quote: 'A smart girl knows her limits; a wise girl knows she has none.',
  ),
];

/* ─────────────────────── MAIN ONBOARDING ─────────────────────── */
class BeguileOnboarding extends ConsumerStatefulWidget {
  final VoidCallback onFinish;
  const BeguileOnboarding({super.key, required this.onFinish});

  @override
  ConsumerState<BeguileOnboarding> createState() => _BeguileOnboardingState();
}

class _BeguileOnboardingState extends ConsumerState<BeguileOnboarding>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;
  bool _isExploding = false;
  bool _showCouncilReveal = false;

  bool _imagesPrecached = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('onboarding');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      _precacheMentorImages();
      _imagesPrecached = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _precacheMentorImages() {
    for (final mentor in _mentors) {
      precacheImage(AssetImage(mentor.asset), context);
    }
  }

  bool _showMentorverseIntro = false;
  
  void _onLastSlideContinue() {
    setState(() => _isExploding = true);
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _isExploding = false;
          _showMentorverseIntro = true; // Show Mentorverse intro first
        });
      }
    });
  }
  
  void _onMentorverseComplete() {
    setState(() {
      _showMentorverseIntro = false;
      _showCouncilReveal = true; // Then show council reveal
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main onboarding slides
            if (!_isExploding && !_showCouncilReveal && !_showMentorverseIntro) _buildMainContent(),
            // Explode animation
            if (_isExploding) _buildExplodeOverlay(),
            // Mentorverse intro (NEW - plays after explosion, before council)
            if (_showMentorverseIntro) MentorverseIntro(
              onComplete: _onMentorverseComplete,
            ),
            // Council reveal sequence
            if (_showCouncilReveal) _CouncilRevealSequence(
              onComplete: widget.onFinish,
            ),
            // ── SKIP BUTTON (visible during cinematic phases) ──
            if (_showMentorverseIntro || _showCouncilReveal)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    // Skip straight to finish (which now goes to login, not paywall)
                    widget.onFinish();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        // PageView with slides
            PageView.builder(
              controller: _controller,
          itemCount: _slides.length,
              onPageChanged: (i) {
                setState(() => _page = i);
                AnalyticsService.logOnboardingStep(i);
              },
          itemBuilder: (context, index) {
            final slide = _slides[index];
            final isLastSlide = index == _slides.length - 1;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(gradient: slide.gradient),
              child: Stack(
                children: [
                  // Background blobs
                  _buildBackgroundBlobs(),
                  // Main content
                  Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                        child: _buildGlassCard(slide, isLastSlide, index),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Bottom UI (page dots)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: IgnorePointer(
                child: Row(
                  children: [
                _PageDots(count: _slides.length, index: _page),
                    const Spacer(),
              ],
                  ),
                ),
              ),
          ],
    );
  }

  Widget _buildBackgroundBlobs() {
    final size = MediaQuery.of(context).size;
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.2,
          child: Stack(
            children: [
              Positioned(
                top: size.height * 0.25,
                left: size.width * 0.25,
                child: _AnimatedBlob(color: WFColors.emerald300, size: 256),
              ),
              Positioned(
                bottom: size.height * 0.25,
                right: size.width * 0.25,
                child: _AnimatedBlob(color: WFColors.fuchsia500, size: 288),
              ),
              Positioned(
                bottom: 40,
                left: 40,
                child: _AnimatedBlob(color: WFColors.purple500, size: 240),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(OnboardingSlide slide, bool isLastSlide, int index) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 672),
      child: ClipRRect(
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
              boxShadow: WFShadows.softWhiteGlow,
            ),
            padding: const EdgeInsets.all(40),
          child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
                // Title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => WFGradients.titleGradient.createShader(bounds),
                  child: Text(
                    slide.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 48,
                    fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  slide.subtitle.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    letterSpacing: 4.0,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Body text
              Text(
                  slide.text,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // CTA button
                _CTAButton(
                  label: slide.cta,
                  onTap: () {
                    if (isLastSlide) {
                      _onLastSlideContinue();
                    } else {
                      _controller.animateToPage(
                        index + 1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplodeOverlay() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 3500),
      curve: Curves.easeInOut,
      builder: (context, progress, child) {
        // Scale: 0.3 → 1.0 → hold → 1.0
        double scale;
        if (progress < 0.29) {  // 0-1000ms: grow
          scale = 0.3 + (progress / 0.29) * 0.7;  // 0.3 → 1.0
        } else if (progress < 0.86) {  // 1000-3000ms: hold at 1.0
          scale = 1.0;
        } else {  // 3000-3500ms: stay at 1.0
          scale = 1.0;
        }

        // Opacity: fade in → hold → fade out
        double opacity;
        if (progress < 0.29) {  // Fade in during grow
          opacity = progress / 0.29;  // 0 → 1.0
        } else if (progress < 0.86) {  // Full opacity during hold
          opacity = 1.0;
        } else {  // Fade out at end
          opacity = 1.0 - ((progress - 0.86) / 0.14);  // 1.0 → 0
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: WFGradients.explodeGradient,
            ),
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: Text(
                  'BEGUILE AI',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 40,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ───────────────────────── COUNCIL REVEAL ───────────────────────── */
class _CouncilRevealSequence extends StatefulWidget {
  final VoidCallback onComplete;

  const _CouncilRevealSequence({required this.onComplete});

  @override
  State<_CouncilRevealSequence> createState() => _CouncilRevealSequenceState();
}

class _CouncilRevealSequenceState extends State<_CouncilRevealSequence>
    with TickerProviderStateMixin {
  int _currentMentorIndex = -1;
  bool _showCouncilGroup = false;
  bool _showTypewriter = false;
  bool _showTagline = false;
  bool _showContinueButton = false;
  late AnimationController _mentorAnimController;

  @override
  void initState() {
    super.initState();
    _mentorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _startSequence();
  }

  @override
  void dispose() {
    _mentorAnimController.dispose();
    super.dispose();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Show mentors one by one (seamless transitions)
    for (int i = 0; i < _mentors.length; i++) {
      if (!mounted) return;
      setState(() => _currentMentorIndex = i);
      _mentorAnimController.reset();
      _mentorAnimController.forward();
      await Future.delayed(const Duration(milliseconds: 2000)); // Match animation duration for seamless transition
    }

    if (!mounted) return;

    setState(() {
      _currentMentorIndex = -1;
      _showCouncilGroup = true;
    });
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;
    setState(() => _showTypewriter = true);
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;
    setState(() => _showTagline = true);
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;
    setState(() => _showContinueButton = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: WFGradients.councilBackground,
      ),
      child: Stack(
            children: [
          // Individual mentor reveal
          if (_currentMentorIndex >= 0)
            _buildMentorReveal(_mentors[_currentMentorIndex]),
          // Council group
          if (_showCouncilGroup) _buildCouncilGroup(),
          // Continue button
          if (_showContinueButton)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: _CTAButton(
                  label: 'Continue',
                  onTap: widget.onComplete,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMentorReveal(MentorData mentor) {
    return AnimatedBuilder(
      animation: _mentorAnimController,
      builder: (context, child) {
        final progress = _mentorAnimController.value;
        // Fade in then out
        double opacity;
        if (progress < 0.15) {
          opacity = progress / 0.15;
        } else if (progress < 0.75) {
          opacity = 1.0;
        } else {
          opacity = (1.0 - progress) / 0.25;
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Portrait with glow
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: WFShadows.mentorGlow(mentor.themeColor),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      mentor.asset,
                      fit: BoxFit.cover,
                      alignment: mentor.name == 'Marilyn Monroe'
                          ? Alignment.topCenter
                          : Alignment.center,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Quote
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                        mentor.quote,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.9),
                  height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '— ${mentor.name}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: mentor.themeColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCouncilGroup() {
    return AnimatedScale(
      scale: _showCouncilGroup ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeOutCubic,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Portrait grid
            Column(
              children: [
                // Top row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCouncilPortrait(_mentors[0]),
                    const SizedBox(width: 16),
                    _buildCouncilPortrait(_mentors[1]),
                    const SizedBox(width: 16),
                    _buildCouncilPortrait(_mentors[2]),
                  ],
                ),
                const SizedBox(height: 16),
                // Bottom row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCouncilPortrait(_mentors[3]),
                    const SizedBox(width: 16),
                    _buildCouncilPortrait(_mentors[4]),
                    const SizedBox(width: 16),
                    _buildCouncilPortrait(_mentors[5]),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
            // "THE COUNCIL" text
            if (_showTypewriter)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 2000),
                builder: (context, progress, child) {
                  const fullText = 'THE COUNCIL';
                  final visibleLength = (fullText.length * progress).round();
                  final visibleText = fullText.substring(0, visibleLength);

                  return ShaderMask(
                    shaderCallback: (bounds) => WFGradients.councilTextGradient.createShader(bounds),
                    child: Text(
                      visibleText,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4.0,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            // Tagline
            if (_showTagline)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 2000),
                builder: (context, opacity, child) {
                  return Opacity(
                    opacity: opacity,
                    child: Text(
                      'Where power, charm, and wisdom converge',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouncilPortrait(MentorData mentor) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: WFShadows.councilPortraitGlow(mentor.themeColor),
      ),
      child: ClipOval(
        child: Image.asset(
          mentor.asset,
          fit: BoxFit.cover,
          alignment: mentor.name == 'Marilyn Monroe'
              ? Alignment.topCenter
              : Alignment.center,
        ),
      ),
    );
  }
}

/* ───────────────────────── HELPER WIDGETS ───────────────────────── */

class _AnimatedBlob extends StatefulWidget {
  final Color color;
  final double size;

  const _AnimatedBlob({required this.color, required this.size});

  @override
  State<_AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<_AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.8 + (_controller.value * 0.4);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
      decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [widget.color, widget.color.withOpacity(0)],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CTAButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _CTAButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
            gradient: WFGradients.ctaButton,
            borderRadius: BorderRadius.circular(12),
            boxShadow: WFShadows.magentaGlow,
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;

  const _PageDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 8),
          width: i == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == index
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: WFColors.gray800.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: WFColors.gray600.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: WFColors.gray300,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
