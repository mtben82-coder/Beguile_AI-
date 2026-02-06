import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';
import '../../../data/services/constants.dart';
import '../../../data/models/mentor_models.dart';
import '../../../widgets/app_header.dart';

/// Epic Mentorverse introduction - shows all 79 mentors in cinematic sequence
class MentorverseIntro extends StatefulWidget {
  final VoidCallback onComplete;

  const MentorverseIntro({super.key, required this.onComplete});

  @override
  State<MentorverseIntro> createState() => _MentorverseIntroState();
}

class _MentorverseIntroState extends State<MentorverseIntro>
    with TickerProviderStateMixin {
  int _phase = 0; // 0=rapid flash, 1=realm reveal, 2=final message
  int _currentMentorIndex = 0;
  int _currentRealmIndex = 0;
  late AnimationController _flashController;
  late AnimationController _realmController;

  // Select 12 representative mentors (one per realm)
  final List<Map<String, dynamic>> _representatives = [];

  @override
  void initState() {
    super.initState();
    
    // Get one mentor from each realm
    for (final realm in RealmConstants.realms) {
      final mentors = MentorConstants.getMentorsByRealm(realm.id);
      if (mentors.isNotEmpty) {
        _representatives.add({
          'mentor': mentors.first,
          'realm': realm,
          'role': _getRoleWord(realm.id),
        });
      }
    }
    
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    
    _realmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _startSequence();
  }

  @override
  void dispose() {
    _flashController.dispose();
    _realmController.dispose();
    super.dispose();
  }

  String _getRoleWord(String realmId) {
    switch (realmId) {
      case 'strategy': return 'STRATEGIST';
      case 'power': return 'RULER';
      case 'seduction': return 'SEDUCER';
      case 'emotion': return 'POET';
      case 'philosophy': return 'PHILOSOPHER';
      case 'genius': return 'VISIONARY';
      case 'warrior': return 'WARRIOR';
      case 'dark': return 'TRICKSTER';
      case 'creators': return 'ARTIST';
      case 'rebels': return 'REVOLUTIONARY';
      case 'legends': return 'LEGEND';
      case 'femme_force': return 'ICON';
      default: return 'MASTER';
    }
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // PHASE 1: RAPID MENTOR FLASH (12 representatives, 900ms each)
    for (int i = 0; i < _representatives.length; i++) {
      if (!mounted) return;
      setState(() {
        _currentMentorIndex = i;
        _phase = 0;
      });
      _flashController.reset();
      _flashController.forward();
      await Future.delayed(const Duration(milliseconds: 900));
    }
    
    // PHASE 2: REALM REVEAL
    if (!mounted) return;
    setState(() {
      _phase = 1;
      _currentRealmIndex = 0;
    });
    
    // Show realms one by one
    for (int i = 0; i < RealmConstants.realms.length; i++) {
      if (!mounted) return;
      setState(() => _currentRealmIndex = i);
      _realmController.reset();
      _realmController.forward();
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    
    // PHASE 3: FINAL MESSAGE
    if (!mounted) return;
    setState(() => _phase = 2);
    await Future.delayed(const Duration(milliseconds: 3000));
    
    // Complete
    if (mounted) {
      widget.onComplete();
    }
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Purple header with logo ──
        const AppHeader(),
        // ── Existing cinematic content (expanded to fill remaining space) ──
        Expanded(
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                // PHASE 1: Rapid mentor flash
                if (_phase == 0 && _currentMentorIndex < _representatives.length)
                  _buildMentorFlash(_representatives[_currentMentorIndex]),

                // PHASE 2: Realm reveals
                if (_phase == 1 && _currentRealmIndex < RealmConstants.realms.length)
                  _buildRealmReveal(
                    RealmConstants.realms[_currentRealmIndex],
                    _currentRealmIndex,
                  ),

                // PHASE 3: Final message
                if (_phase == 2) _buildFinalMessage(),

                // Skip button (top right, always visible)
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: widget.onComplete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'SKIP',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMentorFlash(Map<String, dynamic> rep) {
    final mentor = rep['mentor'] as Mentor;
    final role = rep['role'] as String;
    
    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        final progress = _flashController.value;
        
        // Fast fade in, hold, fast fade out
        double opacity;
        if (progress < 0.2) {
          opacity = progress / 0.2;
        } else if (progress < 0.7) {
          opacity = 1.0;
        } else {
          opacity = (1.0 - progress) / 0.3;
        }
        
        final scale = 0.8 + (0.2 * Curves.easeOut.transform(progress));
        
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mentor portrait (square with rounded corners)
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _parseColor(mentor.color[0]).withOpacity(0.6),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        mentor.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _parseColor(mentor.color[0]),
                                  _parseColor(mentor.color[1]),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                mentor.avatar,
                                style: const TextStyle(fontSize: 80),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Name (huge, bold, CENTERED)
                  Text(
                    mentor.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Role (colored, glowing)
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        _parseColor(mentor.color[0]),
                        _parseColor(mentor.color[1]),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      role,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
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

  Widget _buildRealmReveal(MentorRealm realm, int index) {
    final mentors = MentorConstants.getMentorsByRealm(realm.id);
    final previewMentors = mentors.take(4).toList();
    
    return AnimatedBuilder(
      animation: _realmController,
      builder: (context, child) {
        final progress = _realmController.value;
        final opacity = Curves.easeIn.transform(progress);
        final scale = 0.9 + (0.1 * Curves.easeOut.transform(progress));
        
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Realm icon (huge)
                  Text(
                    realm.icon,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 24),
                  
                  // Realm name (CENTERED)
                  Text(
                    realm.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtitle (gradient)
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        _parseColor(realm.gradient[0]),
                        _parseColor(realm.gradient[1]),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      realm.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Preview mentor faces (4 squares)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: previewMentors.map((mentor) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _parseColor(realm.gradient[0]).withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            mentor.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: _parseColor(realm.gradient[0]).withOpacity(0.2),
                                child: Center(
                                  child: Text(
                                    mentor.avatar,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinalMessage() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Epic number
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: WFColors.beguileGradient,
                  ).createShader(bounds),
                  child: Text(
                    '79',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  'LEGENDARY MENTORS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                
                Text(
                  '12 Realms',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Infinite Wisdom',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'They shaped civilizations.\nNow they\'re yours.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      color: WFColors.primary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

