import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/text_sanitizer.dart';
import '../../../core/encoding_sanitize.dart';
import '../../../data/models/mentor_models.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cache_service.dart';
import '../../../data/services/constants.dart';
import '../../../data/services/analytics_service.dart';
import '../../atoms/atoms.dart';

// ===== PROVIDERS =====
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final selectedMentorProvider = StateProvider<Mentor?>((ref) => null);

final mentorMessagesProvider = StateNotifierProvider.family<
    MentorMessagesNotifier, List<MentorMessage>, String>(
  (ref, mentorId) =>
      MentorMessagesNotifier(mentorId, ref.read(apiServiceProvider)),
);

final isTypingProvider =
    StateProvider.family<bool, String>((ref, mentorId) => false);

final streamingEnabledProvider = StateProvider<bool>((ref) {
  final settings = CacheService.getSettings();
  return settings.streaming;
});

// FIXED: Preset selection provider - properly initialized with cache service
final selectedPresetProvider = StateProvider<String>((ref) {
  // Initialize with default 'chat' preset
  return 'chat';
});

// ===== DATA MODELS =====
class MentorMessage {
  final String id;
  final String text;
  final String sender; // 'user' | 'mentor'
  final DateTime timestamp;
  final String? preset;

  MentorMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.preset,
  });
}

// ===== STATE NOTIFIER =====
class MentorMessagesNotifier extends StateNotifier<List<MentorMessage>> {
  final String mentorId;
  final ApiService apiService;

  MentorMessagesNotifier(this.mentorId, this.apiService) : super([]);

  void addMessage(MentorMessage message) {
    state = [...state, message];
  }

  void addGreeting(String greeting) {
    final greetingMessage = MentorMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: greeting,
      sender: 'mentor',
      timestamp: DateTime.now(),
    );
    state = [greetingMessage];
  }

  Future<void> sendMessage({
    required String userText,
    required String preset,
    required bool streaming,
    required bool safeMode,
    required WidgetRef ref,
  }) async {
    // Add user message
    final userMessage = MentorMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userText,
      sender: 'user',
      timestamp: DateTime.now(),
      preset: preset,
    );
    addMessage(userMessage);

    // Set typing indicator
    ref.read(isTypingProvider(mentorId).notifier).state = true;

    try {
      final request = MentorRequest(
        mentor: mentorId,
        preset: preset,
        userText: userText,
        options: MentorOptions(
          stream: streaming,
          safeMode: safeMode,
        ),
      );

      if (streaming) {
        // Handle streaming response
        String accumulatedText = '';
        final mentorMessage = MentorMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '',
          sender: 'mentor',
          timestamp: DateTime.now(),
        );

        addMessage(mentorMessage);

        try {
          await for (final chunk in apiService.postMentorStream(request)) {
            accumulatedText += chunk;
            // Update the last message with accumulated text
            final updatedMessages = [...state];
            updatedMessages[updatedMessages.length - 1] = MentorMessage(
              id: mentorMessage.id,
              text: accumulatedText.trim(),
              sender: 'mentor',
              timestamp: mentorMessage.timestamp,
            );
            state = updatedMessages;
          }
        } catch (e) {
          // Keep the placeholder message empty; do not inject generic fallback
          // Optionally, you can append an empty/error marker if needed.
          // We avoid client-side fallback text here.
        }
      } else {
        // Handle regular response
        try {
          final response = await apiService.postMentor(request);

          final mentorMessage = MentorMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: response.reply,
            sender: 'mentor',
            timestamp: DateTime.now(),
          );
          addMessage(mentorMessage);
        } catch (e) {
          // Do not inject generic fallback text; show nothing new
        }
      }

      // Save to history if enabled
      final settings = CacheService.getSettings();
      if (settings.saveHistory) {
        await CacheService.saveMentorHistory(
          DateTime.now().millisecondsSinceEpoch.toString(),
          {
            'mentor': mentorId,
            'preset': preset,
            'user_text': userText,
            'streaming': streaming,
            'safe_mode': safeMode,
          },
        );
      }
    } catch (e) {
      // Add error message
      final errorMessage = MentorMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'I apologize, but I encountered an error. Please try again.',
        sender: 'mentor',
        timestamp: DateTime.now(),
      );
      addMessage(errorMessage);
    } finally {
      // Clear typing indicator
      ref.read(isTypingProvider(mentorId).notifier).state = false;
    }
  }

  void clearMessages() {
    state = [];
  }

  // Removed client-side fallback response creator. We only display backend results.
}

class MentorDetailPage extends ConsumerStatefulWidget {
  final Mentor mentor;

  const MentorDetailPage({super.key, required this.mentor});

  @override
  ConsumerState<MentorDetailPage> createState() => _MentorDetailPageState();
}

class _MentorDetailPageState extends ConsumerState<MentorDetailPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('mentor_detail');
    AnalyticsService.logMentorSelected(widget.mentor.id, widget.mentor.name);

    // FIXED: Properly initialize preset provider to ensure generate button works immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure the preset provider is set to 'chat' by default
      ref.read(selectedPresetProvider.notifier).state = 'chat';
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPreset = ref.watch(selectedPresetProvider);
    final isTyping = ref.watch(isTypingProvider(widget.mentor.id));
    final messages = ref.watch(mentorMessagesProvider(widget.mentor.id));
    final streaming = ref.watch(streamingEnabledProvider);
    final settings = CacheService.getSettings();

    // Auto-scroll when new messages arrive
    ref.listen(mentorMessagesProvider(widget.mentor.id), (previous, next) {
      if (next.length > (previous?.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });

    final gradient = LinearGradient(
      colors: widget.mentor.color
          .map((c) => Color(int.parse(c.replaceFirst('#', '0xFF'))))
          .toList(),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: WFColors.base,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: WFColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: WFShadows.glass,
              ),
              child: Center(
                child: Text(widget.mentor.avatar,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: WFDims.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.mentor.name,
                      style:
                          WFTextStyles.h4.copyWith(color: WFColors.purple400)),
                  Text(widget.mentor.subtitle,
                      style: WFTextStyles.bodySmall
                          .copyWith(color: WFColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Icon(Icons.stream,
                  size: 16,
                  color: streaming ? WFColors.purple400 : WFColors.gray500),
              const SizedBox(width: 4),
              Switch(
                value: streaming,
                onChanged: (value) {
                  ref.read(streamingEnabledProvider.notifier).state = value;
                  // Update settings
                  final newSettings = settings.copyWith(streaming: value);
                  CacheService.saveSettings(newSettings);
                },
                activeColor: WFColors.purple400,
                inactiveThumbColor: WFColors.gray500,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(width: WFDims.paddingS),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: WFDims.paddingL),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return _TypingIndicator(
                      mentor: widget.mentor, gradient: gradient);
                }

                final message = messages[index];
                return _MessageBubble(
                  message: message,
                  mentor: widget.mentor,
                  gradient: gradient,
                );
              },
            ),
          ),

          // Preset buttons
          Container(
            padding: const EdgeInsets.all(WFDims.paddingL),
            child: Column(
              children: [
                // Compact preset info line above presets
                _PresetInfoInline(
                  mentor: widget.mentor,
                  selectedPreset: selectedPreset,
                  onUseExample: () {
                    final meta = MentorPresetMeta.byKey[selectedPreset];
                    final example = meta != null ? meta['example'] ?? '' : '';
                    if (example.isEmpty) return;
                    final current = _textController.text.trim();
                    _textController.text = current.isEmpty
                        ? example
                        : current + '\n' + example;
                    _textController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _textController.text.length),
                    );
                  },
                ),
                const SizedBox(height: WFDims.spacingS),
                // Preset selection buttons
                Row(
                  children: [
                    _PresetButton(
                      preset: 'drill',
                      label: 'Drill',
                      isSelected: selectedPreset == 'drill',
                      onTap: () => ref
                          .read(selectedPresetProvider.notifier)
                          .state = 'drill',
                    ),
                    const SizedBox(width: WFDims.spacingS),
                    _PresetButton(
                      preset: 'advise',
                      label: 'Advise',
                      isSelected: selectedPreset == 'advise',
                      onTap: () => ref
                          .read(selectedPresetProvider.notifier)
                          .state = 'advise',
                    ),
                    const SizedBox(width: WFDims.spacingS),
                    _PresetButton(
                      preset: 'roleplay',
                      label: 'Roleplay',
                      isSelected: selectedPreset == 'roleplay',
                      onTap: () => ref
                          .read(selectedPresetProvider.notifier)
                          .state = 'roleplay',
                    ),
                    const SizedBox(width: WFDims.spacingS),
                    _PresetButton(
                      preset: 'chat',
                      label: 'Chat',
                      isSelected: selectedPreset == 'chat',
                      onTap: () => ref
                          .read(selectedPresetProvider.notifier)
                          .state = 'chat',
                    ),
                  ],
                ),

                const SizedBox(height: WFDims.spacingM),

                // Input composer
                Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 120, // Limit maximum height
                        ),
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          style: WFTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText:
                                'Ask ${widget.mentor.name} about defense tactics...',
                            hintStyle: WFTextStyles.bodyMedium
                                .copyWith(color: WFColors.textMuted),
                            filled: true,
                            fillColor: WFColors.gray800.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(WFDims.radiusMedium),
                              borderSide:
                                  BorderSide(color: WFColors.glassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(WFDims.radiusMedium),
                              borderSide:
                                  BorderSide(color: WFColors.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(WFDims.radiusMedium),
                              borderSide: BorderSide(
                                  color: WFColors.purple400, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: WFDims.paddingL,
                              vertical: WFDims.paddingM,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: WFDims.spacingM),
                    WFIconButton(
                      icon: Icons.send,
                      onPressed: _sendMessage,
                      color: WFColors.purple400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    final settings = CacheService.getSettings();
    final selectedPreset = ref.read(selectedPresetProvider);

    ref.read(mentorMessagesProvider(widget.mentor.id).notifier).sendMessage(
          userText: text,
          preset: selectedPreset,
          streaming: ref.read(streamingEnabledProvider),
          safeMode: settings.safeMode,
          ref: ref,
        );
  }
}

class _PresetButton extends StatelessWidget {
  final String preset;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.preset,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: WFDims.paddingS),
          decoration: BoxDecoration(
            color: isSelected
                ? WFColors.purple500.withOpacity(0.2)
                : WFColors.gray800.withOpacity(0.3),
            borderRadius: BorderRadius.circular(WFDims.radiusSmall),
            border: Border.all(
              color: isSelected ? WFColors.purple400 : WFColors.gray600,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: WFTextStyles.labelMedium.copyWith(
              color: isSelected ? WFColors.purple300 : WFColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MentorMessage message;
  final Mentor mentor;
  final Gradient gradient;

  const _MessageBubble({
    required this.message,
    required this.mentor,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: WFDims.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child:
                    Text(mentor.avatar, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: WFDims.spacingS),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(WFDims.paddingM),
                  decoration: BoxDecoration(
                    color: isUser
                        ? WFColors.purple600
                        : WFColors.gray800.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(WFDims.radiusMedium),
                    border: isUser
                        ? null
                        : Border.all(
                            color: WFColors.glassBorder.withOpacity(0.3)),
                  ),
                  child: Text(
                    cleanMentorText(message.text),
                    style: WFTextStyles.mentorResponse.copyWith(
                      color: WFColors.textPrimary,
                    ),
                  ),
                ),

                // ADDED: Copy button for mentor messages only
                if (!isUser) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Message copied to clipboard',
                                style: WFTextStyles.bodySmall
                                    .copyWith(color: WFColors.textPrimary),
                              ),
                              backgroundColor:
                                  WFColors.purple400.withOpacity(0.9),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WFDims.paddingS,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: WFColors.purple400.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(WFDims.radiusSmall),
                            border: Border.all(
                              color: WFColors.purple400.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy,
                                size: 14,
                                color: WFColors.purple300,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: WFTextStyles.labelSmall.copyWith(
                                  color: WFColors.purple300,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: WFTextStyles.bodySmall.copyWith(
                    color: WFColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: WFDims.spacingS),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: WFColors.purple600,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.person, size: 16, color: WFColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _TypingIndicator extends StatefulWidget {
  final Mentor mentor;
  final Gradient gradient;

  const _TypingIndicator({required this.mentor, required this.gradient});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WFDims.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(widget.mentor.avatar,
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: WFDims.spacingS),
          Container(
            padding: const EdgeInsets.all(WFDims.paddingM),
            decoration: BoxDecoration(
              color: WFColors.gray800.withOpacity(0.6),
              borderRadius: BorderRadius.circular(WFDims.radiusMedium),
              border: Border.all(color: WFColors.glassBorder.withOpacity(0.3)),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final animValue = (_controller.value + delay) % 1.0;
                    final opacity =
                        animValue < 0.5 ? animValue * 2 : (1 - animValue) * 2;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: WFColors.purple400
                              .withOpacity(opacity.clamp(0.3, 1.0)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetInfoInline extends StatelessWidget {
  final Mentor mentor;
  final String selectedPreset;
  final VoidCallback onUseExample;

  const _PresetInfoInline({
    required this.mentor,
    required this.selectedPreset,
    required this.onUseExample,
  });

  @override
  Widget build(BuildContext context) {
    final meta = MentorPresetMeta.byKey[selectedPreset] ?? const {};
    final title = meta['title'] ?? selectedPreset;
    final description = meta['description'] ?? '';
    final example = meta['example'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: mentor.color
                  .map((c) => Color(int.parse(c.replaceFirst('#', '0xFF'))))
                  .toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(child: Text(mentor.avatar, style: const TextStyle(fontSize: 12))),
        ),
        const SizedBox(width: WFDims.spacingS),
        Expanded(
          child: Text(
            description.isNotEmpty ? '$title · $description' : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WFTextStyles.bodySmall.copyWith(color: WFColors.textSecondary),
          ),
        ),
        const SizedBox(width: WFDims.spacingS),
        WFPrimaryButton(
          text: 'Use',
          onPressed: onUseExample,
          height: 28,
          padding: const EdgeInsets.symmetric(
            horizontal: WFDims.paddingM,
            vertical: 4,
          ),
        ),
      ],
    );
  }
}
