import 'package:flutter/material.dart';
import '../../../data/services/constants.dart';
import '../../../data/models/mentor_models.dart';
import '../../../core/theme/theme.dart';
import '../../../widgets/tab_header.dart';
import 'mentor_list_screen.dart';

/// First screen of Mentors tab - shows 12 stunning realm category cards
class RealmListScreen extends StatelessWidget {
  const RealmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WFColors.base,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Purple header matching all other tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: const TabHeader(
                title: 'Beguile AI',
                subtitle: 'MENTORS',
              ),
            ),
          ),
          
          // Subtitle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'Choose a realm to explore legendary mentors from history',
                style: TextStyle(
                  color: WFColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          // Realm cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final realm = RealmConstants.realms[index];
                  return AnimatedRealmCard(
                    realm: realm,
                    index: index,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MentorListScreen(realm: realm),
                        ),
                      );
                    },
                  );
                },
                childCount: RealmConstants.realms.length,
              ),
            ),
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}

/// Animated realm card with stunning UI
class AnimatedRealmCard extends StatefulWidget {
  final MentorRealm realm;
  final int index;
  final VoidCallback onTap;

  const AnimatedRealmCard({
    super.key,
    required this.realm,
    required this.index,
    required this.onTap,
  });

  @override
  State<AnimatedRealmCard> createState() => _AnimatedRealmCardState();
}

class _AnimatedRealmCardState extends State<AnimatedRealmCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start animation
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Widget _buildMentorPreviews(BuildContext context) {
    final mentorsInRealm = MentorConstants.getMentorsByRealm(widget.realm.id);
    final previewMentors = mentorsInRealm.take(3).toList(); // Show 3 mentors (not 4)
    
    if (previewMentors.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 8), // SLIGHTLY move to left (8px from edge)
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: previewMentors.asMap().entries.map((entry) {
          final index = entry.key;
          final mentor = entry.value;
          
          return Container(
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0), // 12px spacing between 3 squares
          width: 80, // Same as mentor list cards
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              mentor.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to gradient with emoji
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      mentor.avatar,
                      style: const TextStyle(fontSize: 36), // Bigger emoji for 80x80
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _isHovered = true),
            onTapUp: (_) => setState(() => _isHovered = false),
            onTapCancel: () => setState(() => _isHovered = false),
            child: AnimatedScale(
              scale: _isHovered ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: Container(
                height: 200, // Increased height to fit bigger mentor squares
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _parseColor(widget.realm.gradient[0]),
                      _parseColor(widget.realm.gradient[1]),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _parseColor(widget.realm.gradient[1])
                          .withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Parallax background pattern
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top section: Mentor preview images (BIG squares)
                          _buildMentorPreviews(context),
                          
                          const SizedBox(height: 16),
                          
                          // Bottom section: Title and Subtitle only (NO icon)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                widget.realm.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Subtitle
                              Text(
                                widget.realm.subtitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow indicator
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
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
    );
  }
}

