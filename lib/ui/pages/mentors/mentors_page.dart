import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/constants.dart';
import '../../../data/models/mentor_models.dart';
import '../../../core/theme/theme.dart';
import '../../atoms/glass_card.dart';
import 'mentor_detail_page.dart';
import 'realm_list_screen.dart'; // NEW: Import realm list screen
import '../../../widgets/tab_header.dart';
import '../../../data/services/analytics_service.dart';

class MentorsPage extends ConsumerWidget {
  const MentorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AnalyticsService.logScreenView('mentors_page');
    // Simply show the RealmListScreen as the mentors tab entry point
    return const RealmListScreen();
  }
}

// Keep old implementation commented for reference/backwards compatibility
/*
class _MentorsPageOld extends ConsumerStatefulWidget {
  const _MentorsPageOld({super.key});

  @override
  ConsumerState<_MentorsPageOld> createState() => _MentorsPageState();
}

class _MentorsPageState extends ConsumerState<_MentorsPageOld> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WFColors.base,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [WFColors.baseGradientStart, WFColors.baseGradientMid, WFColors.baseGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading ? const _LoadingShell() : const _MentorsContent(),
        ),
      ),
    );
  }
}
*/

/*
class _MentorsContent extends ConsumerWidget {
  const _MentorsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(WFDims.paddingL),
      child: Column(
        children: [
          const TabHeader(
            title: 'Beguile AI',
            subtitle: 'MENTORS',
          ),

          const SizedBox(height: WFDims.spacingXXL),

          // Mentors grid (2 columns that scale gracefully with screen size)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
            children: MentorConstants.mentors.map((mentor) {
              return _MentorCard(mentor: mentor);
            }).toList(),
          ),

          // Remove the debug fallback grid
          const SizedBox(height: WFDims.spacingXXL),
          // Add extra bottom padding to prevent overflow
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _MentorCard extends ConsumerStatefulWidget {
  final Mentor mentor;

  const _MentorCard({required this.mentor});

  @override
  ConsumerState<_MentorCard> createState() => _MentorCardState();
}

class _MentorCardState extends ConsumerState<_MentorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing based on screen dimensions
    final portraitSize = screenWidth < 400
        ? 80.0
        : screenWidth < 600
            ? 100.0
            : 120.0;
    final titleFontSize = screenWidth < 400
        ? 14.0
        : screenWidth < 600
            ? 16.0
            : 18.0;
    final subtitleFontSize = screenWidth < 400
        ? 10.0
        : screenWidth < 600
            ? 12.0
            : 14.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isHovered ? 1.05 : _scaleAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: GestureDetector(
                  onTap: () => _selectMentor(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          // Big portrait container (takes most of the card height)
                          Expanded(
                            flex: 4,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(WFDims.radiusLarge),
                                  topRight: Radius.circular(WFDims.radiusLarge),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.15),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: portraitSize,
                                      height: portraitSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.2),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.4),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 15,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/mentors/${widget.mentor.id}.png',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient:
                                                    WFGradients.purpleGradient,
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                size: portraitSize * 0.5,
                                                color: WFColors.textPrimary,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getMentorSubtitle(),
                                        style: TextStyle(
                                          fontSize: subtitleFontSize,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Name section (takes 1/5 of the card height)
                          Expanded(
                            flex: 1,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: WFColors.gray800.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft:
                                      Radius.circular(WFDims.radiusLarge),
                                  bottomRight:
                                      Radius.circular(WFDims.radiusLarge),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  widget.mentor.name,
                                  style: WFTextStyles.h5.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: titleFontSize,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMentorSubtitle() {
    switch (widget.mentor.id) {
      case 'casanova':
        return 'Charm Master';
      case 'cleopatra':
        return 'Queen of Influence';
      case 'machiavelli':
        return 'Strategy Sage';
      case 'sun_tzu':
        return 'War Artisan';
      case 'marcus_aurelius':
        return 'Wisdom Keeper';
      case 'churchill':
        return 'Resolve Forger';
      default:
        return 'Legendary Mentor';
    }
  }

  void _selectMentor(BuildContext context) {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    ref.read(selectedMentorProvider.notifier).state = widget.mentor;

    // Initialize with greeting
    ref
        .read(mentorMessagesProvider(widget.mentor.id).notifier)
        .addGreeting(widget.mentor.greeting);

    // Navigate to mentor detail
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MentorDetailPage(mentor: widget.mentor),
      ),
    );
  }
}

// ===== LOADING SHELL =====
class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(WFColors.purple400),
          ),
          SizedBox(height: WFDims.spacingL),
          Text(
            'Loading mentors...',
            style: TextStyle(
              color: WFColors.textTertiary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
*/
