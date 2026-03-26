import 'dart:async';
import 'package:flutter/material.dart';

/// Renders text letter-by-letter with a typing animation.
///
/// Used in the reveal screen to animate the assistant name.
class TypingText extends StatefulWidget {
  const TypingText({
    super.key,
    required this.text,
    required this.style,
    this.typingSpeed = const Duration(milliseconds: 80),
    this.onComplete,
  });

  /// The full text to type out.
  final String text;

  /// Text style applied to the rendered text.
  final TextStyle style;

  /// Delay between each character.
  final Duration typingSpeed;

  /// Called when the full text has been typed out.
  final VoidCallback? onComplete;

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  int _charCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant TypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _charCount = 0;
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (_charCount >= widget.text.length) {
        timer.cancel();
        widget.onComplete?.call();
        return;
      }
      setState(() => _charCount++);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.substring(0, _charCount),
      style: widget.style,
      textAlign: TextAlign.center,
    );
  }
}
