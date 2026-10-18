// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Chat screen — message list and bubbles. Part of alice_chat.dart.

part of 'alice_chat.dart';

/// Scrolling message list. AI messages get avatar + name header + styled
/// action/dialogue text; user messages are blue bubbles on the right.
/// Auto-scrolls to the newest message.
class _MessageList extends StatefulWidget {
  final ChatService chat;
  final bool shrinkWrap;

  const _MessageList({required this.chat, this.shrinkWrap = false});

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final ScrollController _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.chat.messages.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    if (!_scroll.hasClients) return;
    if (widget.shrinkWrap) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.chat.messages;
    if (messages.length != _lastCount) {
      _lastCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
    }
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet — say hello.',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[messages.length - 1 - i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: _MessageRow(message: msg),
        );
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  final ChatMessage message;

  const _MessageRow({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isStatusBanner) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            message.displayText,
            style: TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return message.isUser
        ? _UserBubble(message: message)
        : _AiBubble(message: message);
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage message;

  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.userBubble,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.displayText,
          style: const TextStyle(color: AppColors.userText, fontSize: 14),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final ChatMessage message;

  const _AiBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final sender = message.sender.isNotEmpty ? message.sender : 'AI';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AliceAvatar(name: sender, size: 32),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.aiBubble,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                _StyledStoryText(text: message.displayText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders *actions* in italic and "dialogue" in the dialogue color,
/// everything else in the AI text color.
class _StyledStoryText extends StatelessWidget {
  final String text;

  const _StyledStoryText({required this.text});

  static final RegExp _seg = RegExp(r'(\*[^*\n]+\*|"[^"\n]+")');

  @override
  Widget build(BuildContext context) {
    final base = const TextStyle(
      color: AppColors.aiText,
      fontSize: 14,
      height: 1.45,
    );
    final spans = <TextSpan>[];
    var pos = 0;
    for (final m in _seg.allMatches(text)) {
      if (m.start > pos) {
        spans.add(TextSpan(text: text.substring(pos, m.start), style: base));
      }
      final chunk = m.group(0)!;
      if (chunk.startsWith('*')) {
        spans.add(
          TextSpan(
            text: chunk,
            style: base.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.action,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: chunk,
            style: base.copyWith(color: AppColors.dialogue),
          ),
        );
      }
      pos = m.end;
    }
    if (pos < text.length) {
      spans.add(TextSpan(text: text.substring(pos), style: base));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));
    return SelectableText.rich(TextSpan(children: spans));
  }
}
