import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mira/core/theme.dart';
import 'package:mira/models/conversation_turn.dart';

/// Renders the real-time conversation transcript between the user and Mira.
class TranscriptView extends StatefulWidget {
  final List<ConversationTurn> turns;
  final VoidCallback? onClear;

  const TranscriptView({
    super.key,
    required this.turns,
    this.onClear,
  });

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant TranscriptView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.turns.length != oldWidget.turns.length ||
        (widget.turns.isNotEmpty &&
            widget.turns.last.text != oldWidget.turns.lastOrNull?.text)) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.turns.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MiraTheme.surfaceElevated,
                  border: Border.all(color: MiraTheme.border),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: MiraTheme.cyanAccent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ready to Talk',
                style: TextStyle(
                  color: MiraTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap the microphone below to start talking with Mira in real time.',
                style: TextStyle(
                  color: MiraTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: widget.turns.length,
      itemBuilder: (context, index) {
        final turn = widget.turns[index];
        return _buildTurnBubble(turn);
      },
    );
  }

  Widget _buildTurnBubble(ConversationTurn turn) {
    final bool isUser = turn.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [MiraTheme.cyanAccent, MiraTheme.indigoAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: MiraTheme.cyanAccent.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'M',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: turn.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied transcript to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? MiraTheme.surfaceElevated
                      : MiraTheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: Border.all(
                    color: isUser
                        ? MiraTheme.indigoAccent.withValues(alpha: 0.4)
                        : MiraTheme.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isUser ? 'You' : 'Mira',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isUser
                                ? MiraTheme.indigoAccent
                                : MiraTheme.cyanAccent,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (turn.isInterim) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: MiraTheme.emeraldAccent,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      turn.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: turn.isInterim
                            ? MiraTheme.textSecondary
                            : MiraTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MiraTheme.surfaceElevated,
                border: Border.all(color: MiraTheme.border),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: MiraTheme.textSecondary,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
