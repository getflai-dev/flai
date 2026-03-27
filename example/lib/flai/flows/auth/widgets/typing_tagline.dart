import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';

/// Animated typing text that cycles through a list of taglines.
///
/// Types each tagline letter-by-letter, pauses, then fades out
/// and cycles to the next tagline.
class TypingTagline extends StatefulWidget {
  const TypingTagline({
    super.key,
    required this.taglines,
    this.typingSpeed = const Duration(milliseconds: 60),
    this.pauseDuration = const Duration(seconds: 2),
    this.fadeDuration = const Duration(milliseconds: 400),
  });

  final List<String> taglines;
  final Duration typingSpeed;
  final Duration pauseDuration;
  final Duration fadeDuration;

  @override
  State<TypingTagline> createState() => _TypingTaglineState();
}

class _TypingTaglineState extends State<TypingTagline>
    with SingleTickerProviderStateMixin {
  int _taglineIndex = 0;
  String _displayedText = '';
  double _opacity = 1.0;
  Timer? _typingTimer;
  Timer? _cycleTimer;

  @override
  void initState() {
    super.initState();
    if (widget.taglines.isNotEmpty) {
      _startTyping();
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cycleTimer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    final tagline = widget.taglines[_taglineIndex];
    int charIndex = 0;

    _typingTimer = Timer.periodic(widget.typingSpeed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex < tagline.length) {
        setState(() {
          _displayedText = tagline.substring(0, charIndex + 1);
        });
        charIndex++;
      } else {
        timer.cancel();
        _cycleTimer = Timer(widget.pauseDuration, _fadeAndCycle);
      }
    });
  }

  void _fadeAndCycle() {
    if (!mounted) return;
    setState(() => _opacity = 0.0);
    Future.delayed(widget.fadeDuration, () {
      if (!mounted) return;
      setState(() {
        _taglineIndex = (_taglineIndex + 1) % widget.taglines.length;
        _displayedText = '';
        _opacity = 1.0;
      });
      _startTyping();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.fadeDuration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _displayedText,
            style: theme.typography.xl.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          _BlinkingCursor(color: theme.colors.foreground),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});
  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
