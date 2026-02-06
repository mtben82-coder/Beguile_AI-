import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mentor_models.dart';
import '../../../core/theme/theme.dart';
import 'mentor_detail_page.dart'; // Import existing providers
import '../../widgets/usage_limit_gate.dart';

/// Third screen - individual mentor chat
class MentorChatScreen extends ConsumerStatefulWidget {
  final Mentor mentor;

  const MentorChatScreen({super.key, required this.mentor});

  @override
  ConsumerState<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends ConsumerState<MentorChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load mentor and show greeting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedMentorProvider.notifier).state = widget.mentor;
      ref
          .read(mentorMessagesProvider(widget.mentor.id).notifier)
          .addGreeting(widget.mentor.greeting);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Check daily usage limit before proceeding
    if (!await checkUsageLimit(context)) return;

    _messageController.clear();

    final streaming = ref.read(streamingEnabledProvider);
    final preset = ref.read(selectedPresetProvider);

    await ref.read(mentorMessagesProvider(widget.mentor.id).notifier).sendMessage(
          userText: text,
          preset: preset,
          streaming: streaming,
          safeMode: false,
          ref: ref,
        );

    // Record successful usage
    await recordUsage();

    _scrollToBottom();
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(mentorMessagesProvider(widget.mentor.id));
    final isTyping = ref.watch(isTypingProvider(widget.mentor.id));
    final selectedPreset = ref.watch(selectedPresetProvider);

    return Scaffold(
      backgroundColor: WFColors.base,
      appBar: AppBar(
        backgroundColor: WFColors.cardDark,
        elevation: 0,
        title: Row(
          children: [
            // Mentor avatar (square)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    _parseColor(widget.mentor.color[0]),
                    _parseColor(widget.mentor.color[1]),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  widget.mentor.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        widget.mentor.avatar,
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Mentor name and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mentor.name,
                    style: const TextStyle(
                      color: WFColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.mentor.subtitle,
                    style: TextStyle(
                      color: WFColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Preset selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: WFColors.cardDark,
              border: Border(
                bottom: BorderSide(
                  color: WFColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.mentor.presets.map((preset) {
                  final isSelected = preset == selectedPreset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(selectedPresetProvider.notifier).state = preset;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _parseColor(widget.mentor.color[0])
                              : WFColors.base,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? _parseColor(widget.mentor.color[0])
                                : WFColors.border.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          preset.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : WFColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  // Typing indicator
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: WFColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TypingDot(delay: 0),
                          const SizedBox(width: 4),
                          _TypingDot(delay: 150),
                          const SizedBox(width: 4),
                          _TypingDot(delay: 300),
                        ],
                      ),
                    ),
                  );
                }

                final message = messages[index];
                final isUser = message.sender == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () {
                      // Copy message on long press
                      Clipboard.setData(ClipboardData(text: message.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Message copied to clipboard'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: _parseColor(widget.mentor.color[0]),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? _parseColor(widget.mentor.color[0])
                            : WFColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selectable text so user can highlight and copy
                          SelectableText(
                            message.text,
                            style: TextStyle(
                              color: isUser ? Colors.white : WFColors.textPrimary,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          // Copy icon for mentor messages
                          if (!isUser) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: message.text));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Message copied to clipboard'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: _parseColor(widget.mentor.color[0]),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: WFColors.base.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.copy,
                                          size: 14,
                                          color: WFColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Copy',
                                          style: TextStyle(
                                            color: WFColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WFColors.cardDark,
              border: Border(
                top: BorderSide(
                  color: WFColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: WFColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.mentor.name}...',
                        hintStyle: TextStyle(color: WFColors.textSecondary),
                        filled: true,
                        fillColor: WFColors.base,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _parseColor(widget.mentor.color[0]),
                            _parseColor(widget.mentor.color[1]),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated typing indicator dot
class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: WFColors.textSecondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

