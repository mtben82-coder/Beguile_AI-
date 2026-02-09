import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

import '../../../core/theme/theme.dart';
import '../../../data/services/constants.dart';
import '../../../data/models/mentor_models.dart';
import '../../../data/models/vault_models.dart';
import '../../../data/services/vault_service.dart';
import '../../../services/beguile_api.dart';
import '../../../widgets/tab_header.dart';
import '../../../widgets/state_widgets.dart';
import '../../atoms/glass_card.dart';
import '../../widgets/usage_limit_gate.dart';
import '../../../data/services/analytics_service.dart';

// BEGUILE AI — COUNCIL ARENA
// Matches the exact React prototype functionality and styling

class CouncilPage extends ConsumerStatefulWidget {
  const CouncilPage({super.key});

  @override
  ConsumerState<CouncilPage> createState() => _CouncilPageState();
}

class _CouncilPageState extends ConsumerState<CouncilPage>
    with TickerProviderStateMixin {
  String selectedMode = 'rizz';
  int age = 24;
  double tone = 50.0;
  final TextEditingController _inputController = TextEditingController();
  List<CouncilResponse> responses = [];
  Mentor? winner;
  String echo = '';
  bool isPlaying = false;
  bool _hasText = false;
  String? errorMessage;
  List<dynamic> verdicts = [];

  late AnimationController _animationController;

  final Map<String, ModeAccent> modeAccents = {
    'rizz': ModeAccent(0xFFEC4899, 0xFFF472B6, 0xFFFDA4AF),
    'seduction': ModeAccent(0xFFDC2626, 0xFFFB923C, 0xFFFDE68A),
    'power': ModeAccent(0xFF10B981, 0xFFF59E0B, 0xFF34D399),
    'analysis': ModeAccent(0xFF8B5CF6, 0xFF06B6D4, 0xFFA78BFA),
  };

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('council_page');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    );
    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _summonCouncil() async {
    if (_inputController.text.trim().isEmpty || isPlaying) return;

    // Check daily usage limit before proceeding
    if (!await checkUsageLimit(context)) return;

    print("🔥 Calling Council endpoint...");
    
    if (mounted) {
      setState(() {
        isPlaying = true;
        errorMessage = null;
        verdicts = [];
        responses.clear();
        winner = null;
        echo = '';
      });
    }

    try {
      // Call the real Beguile API
      final response = await BeguileApi.council(
        mode: selectedMode,
        age: age,
        tone: tone.round(),
        scenario: _inputController.text.trim(),
      );

      print("✅ Response: $response");

      // Process the transcript from API response
      final transcript = response['transcript'] as List? ?? [];
      
      // Flatten the transcript if it's nested (handle malformed API responses)
      final flatTranscript = <Map<String, dynamic>>[];
      for (final item in transcript) {
        if (item is Map<String, dynamic>) {
          if (item.containsKey('mentorId')) {
            // Direct mentor response
            flatTranscript.add(item);
          } else if (item.containsKey('transcript') && item['transcript'] is List) {
            // Nested transcript - flatten it
            final nested = item['transcript'] as List;
            for (final nestedItem in nested) {
              if (nestedItem is Map<String, dynamic> && nestedItem.containsKey('mentorId')) {
                flatTranscript.add(nestedItem);
              }
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          verdicts = flatTranscript;
        });
      }
      
      // Add each mentor response with animation delay
      for (int i = 0; i < flatTranscript.length; i++) {
        await Future.delayed(const Duration(milliseconds: 950));
        
        final mentorData = flatTranscript[i];
        final backendMentorId = mentorData['mentorId'] as String? ?? 'casanova';
        final mentorId = _mapMentorId(backendMentorId);
        final mentor = _councilMentors.firstWhere(
          (m) => m.id == mentorId,
          orElse: () => _councilMentors.first,
        );
        
        if (mounted) {
          setState(() {
            responses.add(CouncilResponse(
              id: '${mentorId}-${DateTime.now().millisecondsSinceEpoch}',
              mentorId: mentorId,
              text: mentorData['text'] as String? ?? 'Strategic insight...',
            ));
          });
        }
      }

      await Future.delayed(const Duration(milliseconds: 700));
      
      // Set winner from API response
      final winnerData = response['winner'] as Map<String, dynamic>?;
      
      Mentor winnerMentor;
      
      if (winnerData == null || winnerData['id'] == null) {
        print("⚠️ WARNING: Backend did not return valid winner data, picking random mentor");
        print("Winner data received: $winnerData");
        // Fallback: pick a random mentor from those who responded
        winnerMentor = _councilMentors[Random().nextInt(_councilMentors.length)];
        print("🎲 Random winner selected: ${winnerMentor.name}");
      } else {
        final backendWinnerId = winnerData['id'] as String;
        print("🏆 Winner from backend: $backendWinnerId (${winnerData['name']})");
        
        final winnerId = _mapMentorId(backendWinnerId);
        winnerMentor = _councilMentors.firstWhere(
          (m) => m.id == winnerId,
          orElse: () {
            print("⚠️ WARNING: Could not find mentor with ID: $winnerId, picking random");
            return _councilMentors[Random().nextInt(_councilMentors.length)];
          },
        );
      }
      
      if (mounted) {
        setState(() {
          winner = winnerMentor;
          echo = response['echo'] as String? ?? _craftEcho();
          isPlaying = false;
        });
      }

      // Record successful usage
      await recordUsage();

      if (transcript.isEmpty) {
        print("⚠️ No council replies returned");
      } else {
        print("⚡ Rendering ${transcript.length} responses");
      }
    } catch (e) {
      print("❌ Council API error: $e");
      if (mounted) {
        setState(() {
          isPlaying = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  String _craftLine(Mentor mentor, String prevText) {
    final harsh = tone > 66;
    final gentle = tone < 33;
    
    String tune(String soft, String hard) {
      if (harsh) return hard;
      if (gentle) return soft;
      return '$soft $hard';
    }

    String react(String base) {
      if (prevText.isEmpty) return base;
      final nudges = [
        'I agree with the thrust—refine it:',
        'Build on that, but sharper:',
        'Counterpoint—same outcome, different path:',
        'Correction—keep the spirit, change the tactic:',
      ];
      final nudge = nudges[Random().nextInt(nudges.length)];
      return '$nudge $base';
    }

    switch (selectedMode) {
      case 'rizz':
        final options = [
          'Trouble looks good on us.',
          'You give main-character energy.',
          'Coffee or chaos?'
        ];
        return react(tune('Keep it playful:', 'One line, no chase:') + 
            ' "${options[Random().nextInt(options.length)]}"');
      case 'seduction':
        return react('Seduce rhythm, not words: pull back after warmth. Leave a hook they feel.');
      case 'power':
        return react('Withdraw to raise price. Strike once, clean.');
      case 'analysis':
        return react('Identify tactics, deny fuel, exit loops.');
      default:
        return '…';
    }
  }

  Mentor _pickWinner() {
    final favorites = {
      'rizz': 'casanova',
      'seduction': 'cleopatra',
      'power': 'machiavelli',
      'analysis': 'marcus_aurelius',
    };
    final favoriteId = favorites[selectedMode] ?? 'casanova';
    return _councilMentors.firstWhere(
      (m) => m.id == favoriteId,
      orElse: () => _councilMentors.first,
    );
  }

  // Council-specific mentors (includes Monroe for backend compatibility)
  static final List<Mentor> _councilMentors = [
    ...MentorConstants.mentors.where((m) => m.id != 'churchill'), // All except Churchill
    const Mentor(
      id: 'monroe',
      name: 'Marilyn Monroe',
      subtitle: 'Magnetic Charm',
      avatar: '🌹',
      description: 'Control the spotlight—never chase it',
      color: ['#FF99C8', '#F472B6'], // soft pink to fuchsia
      greeting: 'Darling, I am Marilyn Monroe. They only see what you show them. Softness can be armor when you choose it. Charm quietly—power doesn\'t need volume.',
      presets: ['drill', 'advise', 'roleplay', 'chat'],
      realm: 'seduction', // ADDED
      imagePath: 'assets/images/mentors/monroe.png', // ADDED
      longDescription: 'Hollywood icon whose blend of vulnerability and sensuality captivated millions. Her charm was strategic, her softness deliberate.', // ADDED
    ),
  ];

  // Map backend mentor IDs to frontend mentor IDs
  String _mapMentorId(String backendId) {
    final mapping = {
      'sun_tzu': 'sun_tzu',
      'machiavelli': 'machiavelli', 
      'casanova': 'casanova',
      'aurelius': 'marcus_aurelius',
      'cleopatra': 'cleopatra',
      'monroe': 'monroe', // Keep Monroe for Council tab (backend expects Monroe)
    };
    return mapping[backendId] ?? backendId;
  }

  int _generateScore(String mentorId, String metric) {
    // Generate varied but consistent scores based on mentor and metric
    final mentorScores = {
      'sun_tzu': {'dominance': 91, 'charm': 73, 'clarity': 96},
      'machiavelli': {'dominance': 88, 'charm': 85, 'clarity': 92},
      'casanova': {'dominance': 79, 'charm': 97, 'clarity': 84},
      'marcus_aurelius': {'dominance': 94, 'charm': 81, 'clarity': 98},
      'cleopatra': {'dominance': 87, 'charm': 93, 'clarity': 89},
      'monroe': {'dominance': 82, 'charm': 95, 'clarity': 86},
    };
    
    // Mode modifiers
    final modeBonus = {
      'rizz': {'dominance': -3, 'charm': 5, 'clarity': 0},
      'seduction': {'dominance': 0, 'charm': 4, 'clarity': -2},
      'power': {'dominance': 6, 'charm': -4, 'clarity': 2},
      'analysis': {'dominance': 2, 'charm': -5, 'clarity': 7},
    };
    
    final baseScore = mentorScores[mentorId]?[metric] ?? 85;
    final bonus = modeBonus[selectedMode]?[metric] ?? 0;
    final finalScore = (baseScore + bonus).clamp(70, 99);
    
    return finalScore;
  }

  String _craftEcho() {
    // Generate varied council verdicts based on mode and winner
    final verdicts = {
      'rizz': [
        '${winner?.name ?? "The Council"} reads desire like sheet music. Composure creates pull.',
        'Attraction flows to stillness. ${winner?.name ?? "Victory"} proved restraint magnetizes.',
        'Frame control births chemistry. ${winner?.name ?? "The winner"} held the line.',
        'Mystery generates momentum. ${winner?.name ?? "Excellence"} demonstrated scarcity.',
      ],
      'seduction': [
        '${winner?.name ?? "Mastery"} weaponized absence. Desire grows in the gaps.',
        'Influence blooms in silence. ${winner?.name ?? "The verdict"} shows patience dominates.',
        '${winner?.name ?? "The Council"} reveals: withdrawal amplifies worth.',
        'Scarcity is spellcraft. ${winner?.name ?? "Strategy"} makes them chase.',
      ],
      'power': [
        '${winner?.name ?? "The Council"} commands the frame. Dominance flows from stillness.',
        'Control the tempo, control the outcome. ${winner?.name ?? "Power"} executed perfectly.',
        '${winner?.name ?? "Victory"} priced presence properly. Status answers to withdrawal.',
        'Frame defines fate. ${winner?.name ?? "The winner"} owned the exchange.',
      ],
      'analysis': [
        '${winner?.name ?? "The Council"} named the pattern. Clarity kills manipulation.',
        'Facts disarm fog. ${winner?.name ?? "Strategy"} cut through emotional noise.',
        '${winner?.name ?? "Analysis"} starved the loop. Recognition precedes freedom.',
        'Logic exposes leverage. ${winner?.name ?? "The verdict"} identified the tactic.',
      ],
    };
    
    final modeVerdicts = verdicts[selectedMode] ?? verdicts['analysis']!;
    final index = DateTime.now().millisecond % modeVerdicts.length;
    return modeVerdicts[index];
  }

  void _insertSample() {
    _inputController.text = 'She left me on read after I suggested a plan.';
  }

  @override
  Widget build(BuildContext context) {
    final accent = modeAccents[selectedMode]!;
    
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TabHeader(
                  title: 'Beguile AI',
                  subtitle: 'COUNCIL ARENA',
                ),
                const SizedBox(height: 24),
                _buildModeSelector(accent),
                const SizedBox(height: 20),
                _buildPersonalizationPanel(),
                const SizedBox(height: 20),
                _buildInputSection(accent),
                const SizedBox(height: 20),
                if (isPlaying) 
                  const LoadingStateWidget(message: "🔮 Summoning the Council...")
                else if (errorMessage != null) 
                  ErrorStateWidget(error: errorMessage!)
                else if (responses.isEmpty && verdicts.isEmpty) 
                  const EmptyStateWidget(text: "No responses yet")
                else if (responses.isNotEmpty) ...[
                  _buildCouncilFeed(),
                  const SizedBox(height: 20),
                ],
                if (winner != null) _buildWinnerCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WFColors.glassLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WFColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: WFColors.buttonGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(child: Text('🔮', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: WFColors.beguileGradient,
                  ).createShader(bounds),
                  child: const Text(
                    'Beguile AI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Text(
                  'COUNCIL ARENA',
                  style: TextStyle(
                    fontSize: 10,
                    color: WFColors.textTertiary,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ModeAccent accent) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildModeChip('💋 Rizz', 'rizz')),
              const SizedBox(width: 8),
              Expanded(child: _buildModeChip('🔥 Seduction', 'seduction')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildModeChip('⚡ Power', 'power')),
              const SizedBox(width: 8),
              Expanded(child: _buildModeChip('🧠 Analysis', 'analysis')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, String mode) {
    final isActive = selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? WFColors.glassMedium : WFColors.glassLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? WFColors.glassBorder.withOpacity(0.4) : WFColors.glassBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: WFColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalizationPanel() {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Age',
                      style: TextStyle(fontSize: 12, color: WFColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: WFColors.glassBorder),
                      ),
                      child: TextField(
                        style: const TextStyle(color: WFColors.textPrimary),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: age.toString(),
                          hintStyle: const TextStyle(color: WFColors.textTertiary),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          final newAge = int.tryParse(value);
                          if (newAge != null && newAge >= 16 && newAge <= 80) {
                            setState(() => age = newAge);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tone: ${tone < 33 ? "Gentle" : tone > 66 ? "Harsh" : "Balanced"}',
                      style: const TextStyle(fontSize: 12, color: WFColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: WFColors.primary,
                        inactiveTrackColor: WFColors.glassBorder,
                        thumbColor: WFColors.primary,
                        overlayColor: WFColors.primary.withOpacity(0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: tone,
                        min: 0,
                        max: 100,
                        onChanged: (value) => setState(() => tone = value),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ModeAccent accent) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Scenario',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            height: 128,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WFColors.glassBorder),
            ),
            child: TextField(
              controller: _inputController,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: WFColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Describe the situation or paste messages…',
                hintStyle: TextStyle(color: WFColors.textTertiary),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(accent.from), Color(accent.via), Color(accent.to)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(accent.from).withOpacity(0.6),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: (_hasText && !isPlaying) ? _summonCouncil : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      '🧠 Summon Council',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _insertSample,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: WFColors.glassMedium,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Sample',
                    style: TextStyle(color: WFColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouncilFeed() {
    return Column(
      children: responses.map((response) {
        final mentorId = _mapMentorId(response.mentorId);
        final mentor = _councilMentors.firstWhere(
          (m) => m.id == mentorId,
          orElse: () => _councilMentors.first, // Safe fallback
        );
        return _buildMentorResponse(mentor, response);
      }).toList(),
    );
  }

  Widget _buildMentorResponse(Mentor mentor, CouncilResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WFColors.glassLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WFColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(int.parse('0xFF${mentor.color[0].substring(1)}')).withOpacity(0.2),
                  border: Border.all(
                    color: Color(int.parse('0xFF${mentor.color[0].substring(1)}')).withOpacity(0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    mentor.avatar,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(int.parse('0xFF${mentor.color[0].substring(1)}')),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                mentor.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(int.parse('0xFF${mentor.color[0].substring(1)}')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            response.text,
            style: const TextStyle(
              fontSize: 14,
              color: WFColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildActionButton('📋 Copy', () => _copyResponse(mentor, response)),
              const SizedBox(width: 8),
              _buildActionButton('💾 Vault', () => _saveMentorResponseToVault(mentor, response)),
              const SizedBox(width: 8),
              _buildActionButton('📸 Share', () => _shareResponse()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerCard() {
    if (winner == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WFColors.glassLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WFColors.glassBorder, width: 2),
      ),
      child: Stack(
        children: [
          // Winner glow
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(int.parse('0xFF${winner!.color[0].substring(1)}')).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: WFColors.glassLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WFColors.glassBorder),
                ),
                child: Text(
                  'COUNCIL VERDICT • ${selectedMode.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.2,
                    color: WFColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Text(winner!.avatar, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Winner: ${winner!.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse('0xFF${winner!.color[0].substring(1)}')),
                          ),
                        ),
                        Text(
                          winner!.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: WFColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Metrics - Generate varied scores based on winner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WFColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildMetric('🧠 Dominance', '${_generateScore(winner?.id ?? 'default', 'dominance')} %')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetric('💋 Charm', '${_generateScore(winner?.id ?? 'default', 'charm')} %')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetric('✨ Clarity', '${_generateScore(winner?.id ?? 'default', 'clarity')} %')),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  _buildActionButton('💾 Save to Vault', () => _saveToVault()),
                  const SizedBox(width: 8),
                  _buildActionButton('📋 Copy', () => _copyVerdict()),
                  const SizedBox(width: 8),
                  _buildActionButton('📸 Share', () => _shareVerdict()),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WFColors.glassBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: WFColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: winner != null 
                  ? Color(int.parse('0xFF${winner!.color[0].substring(1)}'))
                  : WFColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            winner != null 
                ? Color(int.parse('0xFF${winner!.color[0].substring(1)}')).withOpacity(0.6)
                : WFColors.primary.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? WFColors.buttonGradient[0].withOpacity(0.8) : WFColors.glassMedium,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: WFColors.textPrimary),
        ),
      ),
    );
  }

  void _copyResponse(Mentor mentor, CouncilResponse response) {
    final text = '${mentor.avatar} ${mentor.name}\n"${response.text}"\n\n— Beguile AI Council';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${mentor.name}\'s response!'),
        backgroundColor: WFColors.purple400,
      ),
    );
  }

  void _shareResponse() {
    if (responses.isEmpty) return;
    final allResponses = responses.map((r) {
      final mentorId = _mapMentorId(r.mentorId);
      final mentor = _councilMentors.firstWhere(
        (m) => m.id == mentorId,
        orElse: () => _councilMentors.first,
      );
      return '${mentor.avatar} ${mentor.name}: "${r.text}"';
    }).join('\n\n');
    
    final text = '🧠 Beguile AI Council Debate\n\n$allResponses\n\n— Beguile AI';
    Share.share(text);
  }

  void _copyVerdict() {
    if (winner == null) return;
    final text = '🏆 Council Winner: ${winner!.avatar} ${winner!.name}\n\n"$echo"\n\n— Beguile AI Council';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied verdict to clipboard!'),
        backgroundColor: WFColors.purple400,
      ),
    );
  }

  void _shareVerdict() {
    if (winner == null) return;
    final text = '🏆 Council Winner: ${winner!.avatar} ${winner!.name}\n\n"$echo"\n\n— Beguile AI Council';
    Share.share(text);
  }

  void _saveMentorResponseToVault(Mentor mentor, CouncilResponse response) async {
    try {
      final entry = VaultEntry.fromMentorResponse(
        mentorName: mentor.name,
        mode: selectedMode,
        responseText: response.text,
      );
      
      await VaultService.addEntry(entry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💾 ${mentor.name}\'s response saved to Vault!'),
            backgroundColor: WFColors.purple400,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving to vault: $e'),
            backgroundColor: WFColors.error,
          ),
        );
      }
    }
  }

  void _saveToVault() async {
    if (winner == null || responses.isEmpty) return;
    
    try {
      // Format council responses with structure
      final formattedResponses = responses.map((r) {
        final mentorId = _mapMentorId(r.mentorId);
        final mentor = _councilMentors.firstWhere(
          (m) => m.id == mentorId,
          orElse: () => _councilMentors.first,
        );
        return '${mentor.avatar} ${mentor.name}:\n"${r.text}"';
      }).join('\n\n');
      
      final entry = VaultEntry.fromCouncil(
        echo: echo,
        winnerName: winner!.name,
        mode: selectedMode,
        formattedContent: formattedResponses,
      );
      
      await VaultService.addEntry(entry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💾 Council debate saved to Vault!'),
            backgroundColor: WFColors.purple400,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving to vault: $e'),
            backgroundColor: WFColors.error,
          ),
        );
      }
    }
  }
}

// Data models
class CouncilResponse {
  final String id;
  final String mentorId;
  final String text;

  CouncilResponse({
    required this.id,
    required this.mentorId,
    required this.text,
  });
}

class ModeAccent {
  final int from;
  final int via;
  final int to;

  ModeAccent(this.from, this.via, this.to);
}
