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

// BEGUILE AI — SCAN TAB
// Matches the exact React prototype functionality and styling

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  // Original 6 mentors for scan page
  static final List<Mentor> _scanMentors = [
    MentorConstants.getMentorById('casanova'),
    MentorConstants.getMentorById('cleopatra'),
    MentorConstants.getMentorById('machiavelli'),
    MentorConstants.getMentorById('sun_tzu'),
    MentorConstants.getMentorById('marcus_aurelius'),
    MentorConstants.getMentorById('monroe'),
  ].whereType<Mentor>().toList();

  // Helper to get mentor portrait asset path
  String _getMentorAsset(String mentorId) {
    switch (mentorId) {
      case 'casanova':
        return 'assets/images/mentors/casanova.png';
      case 'cleopatra':
        return 'assets/images/mentors/cleopatra.png';
      case 'machiavelli':
        return 'assets/images/mentors/machiavelli.png';
      case 'sun_tzu':
        return 'assets/images/mentors/sun_tzu.png';
      case 'marcus_aurelius':
        return 'assets/images/mentors/marcus_aurelius.png';
      case 'monroe':
        return 'assets/images/mentors/monroe.png';
      default:
        return 'assets/images/mentors/casanova.png'; // fallback
    }
  }

  // Helper to get mentor theme color
  Color _getMentorThemeColor(String mentorId) {
    switch (mentorId) {
      case 'casanova':
        return WFColors.mentorCasanova;
      case 'cleopatra':
        return WFColors.mentorCleopatra;
      case 'machiavelli':
        return WFColors.mentorMachiavelli;
      case 'sun_tzu':
        return WFColors.mentorSunTzu;
      case 'marcus_aurelius':
        return WFColors.mentorAurelius;
      case 'monroe':
        return WFColors.mentorMonroe;
      default:
        return WFColors.purple400;
    }
  }

  late Mentor selectedMentor;
  String perspective = 'you'; // 'you' | 'them'
  final TextEditingController _inputController = TextEditingController();
  ScanResult? result;
  bool isScanning = false;
  bool _hasText = false;
  String? errorMessage;
  List<dynamic> verdicts = [];

  @override
  void initState() {
    super.initState();
    // Initialize selected mentor
    selectedMentor = _scanMentors.isNotEmpty ? _scanMentors[0] : MentorConstants.mentors[0];
    
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
    _inputController.dispose();
    super.dispose();
  }

  final List<PowerMove> powerMovesYou = [
    PowerMove('⚔️', 'Frame Control', 'You set terms calmly and didn\'t chase.'),
    PowerMove('🧊', 'Strategic Silence', 'You let tension expose the truth.'),
    PowerMove('💎', 'Scarcity Signal', 'You valued time; desire rose.'),
    PowerMove('🎯', 'Reality Reframe', 'You renamed the moment—and won.'),
    PowerMove('🛡️', 'Boundary', 'You drew a line without apology.'),
  ];

  final List<PowerMove> powerMovesThem = [
    PowerMove('😈', 'Gaslight Attempt', 'They twisted facts to shift blame.'),
    PowerMove('🧵', 'Guilt Thread', 'They tried weaving debt you never owed.'),
    PowerMove('🕴️', 'Triangulation', '\'Everyone thinks…\' to box you in.'),
    PowerMove('🎭', 'Projection', 'Accused you of what they did.'),
    PowerMove('🔮', 'Future-Faking', 'Promises as bait, not plan.'),
  ];

  final List<String> tags = [
    'Gaslighting', 'Triangulation', 'Guilt Trip', 'Projection', 'Future Faking', 'Stonewalling'
  ];

  final List<String> quotes = [
    'Power respects power. You proved yours.',
    'They played checkers. You played 4D chess.',
    'Composure is a weapon; you used it well.',
    'Presence prices access. You set the tariff.',
  ];

  Future<void> _runScan() async {
    if (_inputController.text.trim().isEmpty || isScanning) return;

    // Check daily usage limit before proceeding
    if (!await checkUsageLimit(context)) return;

    print("🔥 Calling Scan endpoint...");
    
    if (mounted) {
      setState(() {
        isScanning = true;
        errorMessage = null;
        verdicts = [];
        result = null;
      });
    }

    try {
      // Call the real Beguile API
      final response = await BeguileApi.scan(
        text: _inputController.text.trim(),
        perspective: perspective == 'you' ? 'you' : 'them',
        mentorId: selectedMentor.id,
      );

      print("✅ Response: $response");

      // Validate mentor data
      final mentorData = response['mentor'] as Map<String, dynamic>?;
      if (mentorData == null || mentorData['id'] == null || mentorData['name'] == null) {
        print("❌ ERROR: Backend did not return valid mentor data");
        print("Mentor data received: $mentorData");
        throw Exception('Invalid mentor data from backend');
      }
      
      print("🧠 Mentor from backend: ${mentorData['id']} (${mentorData['name']})");

      // Validate and extract score
      final score = response['score'] as num?;
      if (score == null) {
        print("❌ ERROR: Backend did not return score");
        throw Exception('Invalid score from backend');
      }
      print("📊 Score from backend: $score");

      // Convert API response to UI model
      final moves = (response['points'] as List?)
          ?.map((p) => PowerMove(
                p['emoji'] ?? '⚡',
                p['title'] ?? 'Power Move',
                p['text'] ?? 'Strategic insight',
              ))
          .toList() ?? [];

      final selectedTags = (response['tags'] as List?)
          ?.map((t) => t.toString())
          .toList() ?? [];

      final verdictsData = response['points'] as List? ?? [];
      
      // Get mentor name and generate varied verdicts
      final mentorName = mentorData['name'] as String;
      
      // Create varied verdicts based on score and perspective
      final verdict = _generateDynamicVerdict(score.toInt(), perspective, mentorName);

      if (mounted) {
        setState(() {
          isScanning = false;
          verdicts = verdictsData;
          result = ScanResult(
            score: score.toInt(),
            verdict: verdict,
            mentorName: mentorName,
            moves: moves.take(3).toList(),
            tags: selectedTags.take(6).toList(),
            quote: response['quote']?.toString() ?? 'Power respects power.',
          );
        });
      }

      // Record successful usage
      await recordUsage();

      if (verdictsData.isEmpty) {
        print("⚠️ No results returned");
      } else {
        print("⚡ Rendering ${verdictsData.length} verdicts");
      }
    } catch (e) {
      print("❌ Scan API error: $e");
      if (mounted) {
        setState(() {
          isScanning = false;
          errorMessage = e.toString();
        });
      }
    }
  }


  String _generateDynamicVerdict(int score, String perspective, String mentorName) {
    // Create varied verdicts based on score ranges
    if (perspective == 'you') {
      if (score >= 85) {
        final verdicts = [
          'Mastery detected. Frame held perfectly.',
          'Elite composure. Zero emotional leakage.',
          'You commanded the exchange. Textbook control.',
          'Dominance established. They chase now.',
        ];
        return verdicts[score % verdicts.length];
      } else if (score >= 70) {
        final verdicts = [
          'Solid frame. Minor adjustments needed.',
          'You held ground. Respect earned.',
          'Good boundaries. Room to sharpen.',
          'Strategic positioning maintained.',
        ];
        return verdicts[score % verdicts.length];
      } else if (score >= 50) {
        final verdicts = [
          'Mixed signals detected. Tighten control.',
          'Frame wavered. Regroup and recalibrate.',
          'Reactive moments visible. Refine approach.',
          'Power shared. Consider withdrawal tactics.',
        ];
        return verdicts[score % verdicts.length];
      } else {
        final verdicts = [
          'Frame lost. Rebuild from scratch.',
          'Over-invested. Pull back immediately.',
          'Emotional exposure high. Reset needed.',
          'Control inverted. Study and adapt.',
        ];
        return verdicts[score % verdicts.length];
      }
    } else {
      // perspective == 'them'
      if (score >= 85) {
        final verdicts = [
          'Expert manipulation detected. Pattern clear.',
          'Calculated control tactics. Stay vigilant.',
          'Psychological warfare identified. Exit advised.',
          'High-level gaslighting. Document everything.',
        ];
        return verdicts[score % verdicts.length];
      } else if (score >= 70) {
        final verdicts = [
          'Manipulation present. Set firm boundaries.',
          'Control tactics emerging. Monitor closely.',
          'Emotional leverage attempted. Guard up.',
          'Subtle influence detected. Stay grounded.',
        ];
        return verdicts[score % verdicts.length];
      } else if (score >= 50) {
        final verdicts = [
          'Mixed intentions. Trust but verify.',
          'Some red flags. Proceed with caution.',
          'Minor manipulation. Address directly.',
          'Unclear motives. Demand transparency.',
        ];
        return verdicts[score % verdicts.length];
      } else {
        final verdicts = [
          'No major red flags. Communication fair.',
          'Genuine exchange detected. Low threat.',
          'Healthy interaction patterns observed.',
          'Minimal manipulation. Continue dialogue.',
        ];
        return verdicts[score % verdicts.length];
      }
    }
  }

  void _insertSample() {
    _inputController.text = 
        "I'm not mad, just disappointed. Everyone thinks you're being difficult. "
        "After everything I've done for you… Let's be rational; you're overreacting.";
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TabHeader(
                  title: 'Beguile AI',
                  subtitle: 'SCAN',
                ),
                const SizedBox(height: 24),
                _buildMentorSelector(),
                const SizedBox(height: 20),
                _buildPerspectiveToggle(),
                const SizedBox(height: 20),
                _buildInputSection(),
                const SizedBox(height: 20),
                if (isScanning) 
                  const LoadingStateWidget(message: "🧠 Analyzing message...")
                else if (errorMessage != null) 
                  ErrorStateWidget(error: errorMessage!)
                else if (result == null && verdicts.isEmpty) 
                  const EmptyStateWidget(text: "No verdicts yet")
                else if (result != null) ...[
                  _buildVerdictCard(),
                  const SizedBox(height: 20),
                  _buildShareCard(),
                ],
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
                // Removed Mars edition tag per branding update
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: WFColors.glassMedium,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WFColors.glassBorder),
            ),
            child: const Text(
              '🪐 Live',
              style: TextStyle(fontSize: 12, color: WFColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorSelector() {
  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Choose Mentor',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        // Mentor grid with portrait images (2 per row)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 mentors per row
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85, // Slightly taller to fit name below
          ),
          itemCount: _scanMentors.length,
          itemBuilder: (context, index) {
            final mentor = _scanMentors[index];
            final isSelected = selectedMentor.id == mentor.id;
            final themeColor = _getMentorThemeColor(mentor.id);

            return GestureDetector(
              onTap: () => setState(() => selectedMentor = mentor),
              child: Column(
                children: [
                  // Image container (square with rounded corners)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? themeColor : Colors.white.withOpacity(0.2),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: themeColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Mentor portrait image with emoji fallback
                            Image.asset(
                              _getMentorAsset(mentor.id),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              alignment: mentor.id == 'monroe'
                                  ? Alignment.topCenter
                                  : Alignment.center,
                              errorBuilder: (context, error, stackTrace) {
                                // Show emoji avatar as fallback if image fails
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        themeColor.withOpacity(0.3),
                                        themeColor.withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      mentor.avatar,
                                      style: const TextStyle(fontSize: 64),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Selection tint overlay
                            if (isSelected)
                              Container(
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.25),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name below image
                  Text(
                    mentor.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? themeColor : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
  }

  Widget _buildPerspectiveToggle() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyze Perspective',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToggleChip('🧍 You', perspective == 'you', () => setState(() => perspective = 'you')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleChip('🕴️ Them', perspective == 'them', () => setState(() => perspective = 'them')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? WFColors.glassMedium : WFColors.glassLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? WFColors.glassBorder.withOpacity(0.4) : WFColors.glassBorder,
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

  Widget _buildInputSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Psy‑Ops Scan',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
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
                hintText: 'Paste messages here…',
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
                    gradient: const LinearGradient(colors: WFColors.buttonGradient),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: WFColors.buttonGradient[0].withOpacity(0.6),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: (_hasText && !isScanning) ? _runScan : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '⚡ Run Deep Scan',
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

  Widget _buildVerdictCard() {
    if (result == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WFColors.glassLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WFColors.glassBorder, width: 2),
      ),
      child: Stack(
        children: [
          // Mentor glow
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(int.parse('0xFF${selectedMentor.color[0].substring(1)}')).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PSY-OPS header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: WFColors.glassLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WFColors.glassBorder),
                ),
                child: Text(
                  'PSY‑OPS REPORT • CASE‑${1000 + Random().nextInt(8999)}',
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.2,
                    color: WFColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Mentor info and verdict
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedMentor.avatar} ${selectedMentor.name} • ${selectedMentor.subtitle}',
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.2,
                            color: WFColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD1A6), Color(0xFFFFB3A1), Color(0xFFF6A3FF)],
                          ).createShader(bounds),
                          child: Text(
                            result!.verdict,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    selectedMentor.avatar,
                    style: TextStyle(
                      fontSize: 48,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Score block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WFColors.glassBorder),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PSYCHOLOGICAL DOMINANCE',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        color: WFColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD1A6), Color(0xFFFFB3A1), Color(0xFFF6A3FF)],
                          ).createShader(bounds),
                          child: Text(
                            '${result!.score}',
                            style: const TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 30,
                            color: WFColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(int.parse('0xFF${selectedMentor.color[0].substring(1)}')).withOpacity(0.6),
                        ),
                      ),
                      child: Text(
                        'ELITE TIER',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(int.parse('0xFF${selectedMentor.color[0].substring(1)}')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Mini metrics
              Row(
                children: [
                  Expanded(child: _buildMetric('🧠 Control Ratio', '82 %')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetric('💎 Emotional Balance', '76 %')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetric('⚡ Tempo', 'Stable')),
                ],
              ),
              
              const SizedBox(height: 16),
              _buildGradientDivider(),
              const SizedBox(height: 16),
              
              // Power moves
              const Text(
                '⚡ POWER MOVES',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2.0,
                  color: WFColors.textTertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...result!.moves.map((move) => _buildPowerMoveCard(move)),
              
              const SizedBox(height: 16),
              _buildGradientDivider(),
              const SizedBox(height: 16),
              
              // Tactics
              const Text(
                '🚨 TACTICS DETECTED',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2.0,
                  color: WFColors.textTertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result!.tags.map((tag) => _buildTacticTag(tag)).toList(),
              ),
              
              const SizedBox(height: 16),
              _buildGradientDivider(),
              const SizedBox(height: 16),
              
              // Quote
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(int.parse('0xFF${selectedMentor.color[0].substring(1)}')),
                    width: 4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedMentor.name} says',
                      style: const TextStyle(
                        fontSize: 12,
                        color: WFColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${result!.quote}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: WFColors.textSecondary,
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
              color: Color(int.parse('0xFF${selectedMentor.color[0].substring(1)}')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerMoveCard(PowerMove move) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WFColors.glassBorder),
      ),
      child: Row(
        children: [
          Text(move.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  move.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: WFColors.textPrimary,
                  ),
                ),
                Text(
                  move.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: WFColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${selectedMentor.color[0].substring(1)}')).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(int.parse('0xFF${selectedMentor.color[0].substring(1)}')).withOpacity(0.5),
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          color: WFColors.textPrimary,
        ),
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
            Color(int.parse('0xFF${selectedMentor.color[0].substring(1)}')).withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    if (result == null) return const SizedBox();

    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Color(int.parse('0xFF${selectedMentor.color[0].substring(1)}')).withOpacity(0.6),
              width: 2,
            ),
            gradient: const LinearGradient(
              colors: [Color(0xE6141416), Color(0xEB120E12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Text(
                '${selectedMentor.avatar} ${selectedMentor.name} • ${perspective.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 2.2,
                  color: WFColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result!.verdict,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(int.parse('0xFF${selectedMentor.color[0].substring(1)}')),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD1A6), Color(0xFFFFB3A1), Color(0xFFF6A3FF)],
                    ).createShader(bounds),
                    child: Text(
                      '${result!.score}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 20,
                      color: WFColors.textMuted,
                    ),
                  ),
                ],
              ),
              const Text(
                'ELITE TIER • FRAME MASTERY',
                style: TextStyle(
                  fontSize: 11,
                  color: WFColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...result!.moves.map((move) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(move.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: WFColors.textPrimary),
                          children: [
                            TextSpan(
                              text: move.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const TextSpan(text: ' — '),
                            TextSpan(
                              text: move.description,
                              style: const TextStyle(color: WFColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              const Text(
                'Beguile AI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: WFColors.purple400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton('💾 Save to Vault', () => _saveToVault()),
            const SizedBox(width: 8),
            _buildActionButton('📋 Copy', () => _copyText()),
            const SizedBox(width: 8),
            _buildActionButton('📸 Share', () => _saveCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? WFColors.buttonGradient[0].withOpacity(0.8) : WFColors.glassMedium,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: WFColors.textPrimary),
        ),
      ),
    );
  }

  void _copyText() {
    if (result == null) return;
    final lines = result!.moves.map((m) => '${m.emoji} ${m.title} — ${m.description}').join('\n');
    final text = '${selectedMentor.avatar} ${selectedMentor.name} — ${perspective == 'you' ? 'Your' : 'Their'} Verdict\n'
        '"${result!.verdict}"\n\n'
        '🧠 ${result!.score}/100 • ELITE TIER\n\n'
        '$lines\n\n'
        '💬 "${result!.quote}"\n\n'
        'Beguile AI';
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        backgroundColor: WFColors.purple400,
      ),
    );
  }

  void _saveCard() {
    if (result == null) return;
    final lines = result!.moves.map((m) => '${m.emoji} ${m.title} — ${m.description}').join('\n');
    final text = '${selectedMentor.avatar} ${selectedMentor.name} — ${perspective == 'you' ? 'Your' : 'Their'} Verdict\n'
        '"${result!.verdict}"\n\n'
        '🧠 ${result!.score}/100 • ELITE TIER\n\n'
        '$lines\n\n'
        '💬 "${result!.quote}"\n\n'
        'Beguile AI';
    
    Share.share(text);
  }

  void _saveToVault() async {
    if (result == null) return;
    
    try {
      final entry = VaultEntry.fromScan(
        title: '${result!.mentorName} - ${perspective.toUpperCase()}',
        verdict: result!.verdict,
        score: result!.score,
        mentorName: result!.mentorName,
        moves: result!.moves.map((m) => '${m.emoji} ${m.title}: ${m.description}').toList(),
        quote: result!.quote,
      );
      
      await VaultService.addEntry(entry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💾 Saved to Vault!'),
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
class ScanResult {
  final int score;
  final String verdict;
  final String mentorName;
  final List<PowerMove> moves;
  final List<String> tags;
  final String quote;

  ScanResult({
    required this.score,
    required this.verdict,
    required this.mentorName,
    required this.moves,
    required this.tags,
    required this.quote,
  });
}

class PowerMove {
  final String emoji;
  final String title;
  final String description;

  PowerMove(this.emoji, this.title, this.description);
}
