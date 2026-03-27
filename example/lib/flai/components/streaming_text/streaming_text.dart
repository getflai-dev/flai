import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';

/// A widget that renders text being streamed token-by-token from an AI
/// provider, with an animated blinking cursor.
///
/// Supports two modes of operation:
///
/// **Mode A — Stream-driven:** Accepts a [Stream<String>] of text deltas and
/// builds the full text progressively.
/// ```dart
/// FlaiStreamingText.fromStream(
///   stream: aiProvider.streamChat(request)
///       .whereType<TextDelta>()
///       .map((e) => e.text),
///   style: theme.typography.bodyBase(color: theme.colors.foreground),
/// )
/// ```
///
/// **Mode B — Text-driven:** Accepts a [String] that changes over time (e.g.,
/// from a controller). Renders whatever text is provided.
/// ```dart
/// FlaiStreamingText(
///   text: controller.currentText,
///   isStreaming: controller.isStreaming,
///   style: theme.typography.bodyBase(color: theme.colors.foreground),
/// )
/// ```
class FlaiStreamingText extends StatefulWidget {
  /// Current text to display (Mode B).
  final String? text;

  /// Stream of text deltas to accumulate (Mode A).
  final Stream<String>? stream;

  /// Whether streaming is currently active (Mode B). Ignored in stream mode
  /// where streaming state is derived from the stream lifecycle.
  final bool isStreaming;

  /// Text style for the rendered text.
  final TextStyle? style;

  /// Whether to show the blinking cursor while streaming.
  final bool showCursor;

  /// Override color for the cursor. Defaults to [FlaiColors.primary].
  final Color? cursorColor;

  /// Width of the cursor bar in logical pixels.
  final double cursorWidth;

  /// Whether to animate newly-arrived text with a brief fade-in.
  /// Disabled by default for performance.
  final bool animateText;

  /// Called when the stream completes (Mode A only).
  final VoidCallback? onStreamDone;

  /// Called with the current accumulated text on each update.
  final ValueChanged<String>? onTextChanged;

  /// Creates a text-driven streaming text widget (Mode B).
  const FlaiStreamingText({
    super.key,
    required String this.text,
    this.isStreaming = false,
    this.style,
    this.showCursor = true,
    this.cursorColor,
    this.cursorWidth = 2.0,
    this.animateText = false,
    this.onStreamDone,
    this.onTextChanged,
  }) : stream = null;

  /// Creates a stream-driven streaming text widget (Mode A).
  const FlaiStreamingText.fromStream({
    super.key,
    required Stream<String> this.stream,
    this.style,
    this.showCursor = true,
    this.cursorColor,
    this.cursorWidth = 2.0,
    this.animateText = false,
    this.onStreamDone,
    this.onTextChanged,
  }) : text = null,
       isStreaming = false;

  @override
  State<FlaiStreamingText> createState() => _FlaiStreamingTextState();
}

class _FlaiStreamingTextState extends State<FlaiStreamingText> {
  /// Accumulated text buffer for stream mode.
  final StringBuffer _buffer = StringBuffer();

  /// The text currently being displayed.
  String _displayText = '';

  /// Whether we are actively receiving stream data.
  bool _isStreaming = false;

  /// Previous text length, used for the fade-in animation.
  int _previousTextLength = 0;

  StreamSubscription<String>? _subscription;

  bool get _isStreamMode => widget.stream != null;

  @override
  void initState() {
    super.initState();
    if (_isStreamMode) {
      _subscribeToStream();
    } else {
      _displayText = widget.text ?? '';
      _isStreaming = widget.isStreaming;
    }
  }

  @override
  void didUpdateWidget(covariant FlaiStreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isStreamMode) {
      // Re-subscribe if the stream instance changed.
      if (widget.stream != oldWidget.stream) {
        _subscription?.cancel();
        _buffer.clear();
        _displayText = '';
        _previousTextLength = 0;
        _subscribeToStream();
      }
    } else {
      // Text-driven mode: update from new props.
      final newText = widget.text ?? '';
      if (newText != _displayText) {
        _previousTextLength = _displayText.length;
        _displayText = newText;
      }
      _isStreaming = widget.isStreaming;
    }
  }

  void _subscribeToStream() {
    _isStreaming = true;
    _subscription = widget.stream!.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
    );
  }

  void _onData(String delta) {
    if (!mounted) return;
    setState(() {
      _previousTextLength = _displayText.length;
      _buffer.write(delta);
      _displayText = _buffer.toString();
    });
    widget.onTextChanged?.call(_displayText);
  }

  void _onError(Object error, StackTrace stackTrace) {
    // Gracefully stop streaming on error. The caller is expected to handle
    // errors on their end via the stream or a separate error callback.
    if (!mounted) return;
    setState(() {
      _isStreaming = false;
    });
  }

  void _onDone() {
    if (!mounted) return;
    setState(() {
      _isStreaming = false;
    });
    widget.onStreamDone?.call();
    widget.onTextChanged?.call(_displayText);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final effectiveStyle =
        widget.style ??
        theme.typography.bodyBase(color: theme.colors.foreground);
    final effectiveCursorColor = widget.cursorColor ?? theme.colors.primary;
    final shouldShowCursor = widget.showCursor && _isStreaming;

    return RepaintBoundary(
      child: _StreamingTextContent(
        text: _displayText,
        previousTextLength: widget.animateText
            ? _previousTextLength
            : _displayText.length,
        style: effectiveStyle,
        showCursor: shouldShowCursor,
        cursorColor: effectiveCursorColor,
        cursorWidth: widget.cursorWidth,
        animateText: widget.animateText,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streaming text content — renders text + optional animated cursor
// ---------------------------------------------------------------------------

class _StreamingTextContent extends StatelessWidget {
  final String text;
  final int previousTextLength;
  final TextStyle style;
  final bool showCursor;
  final Color cursorColor;
  final double cursorWidth;
  final bool animateText;

  const _StreamingTextContent({
    required this.text,
    required this.previousTextLength,
    required this.style,
    required this.showCursor,
    required this.cursorColor,
    required this.cursorWidth,
    required this.animateText,
  });

  @override
  Widget build(BuildContext context) {
    if (!showCursor && !animateText) {
      return Text(text, style: style);
    }

    if (!showCursor && animateText) {
      return _AnimatedTextBlock(
        text: text,
        previousTextLength: previousTextLength,
        style: style,
      );
    }

    // With cursor (and optionally animated text).
    return _TextWithCursor(
      text: text,
      previousTextLength: previousTextLength,
      style: style,
      cursorColor: cursorColor,
      cursorWidth: cursorWidth,
      animateText: animateText,
    );
  }
}

// ---------------------------------------------------------------------------
// Text with inline blinking cursor
// ---------------------------------------------------------------------------

class _TextWithCursor extends StatelessWidget {
  final String text;
  final int previousTextLength;
  final TextStyle style;
  final Color cursorColor;
  final double cursorWidth;
  final bool animateText;

  const _TextWithCursor({
    required this.text,
    required this.previousTextLength,
    required this.style,
    required this.cursorColor,
    required this.cursorWidth,
    required this.animateText,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = animateText
        ? _AnimatedTextBlock(
            text: text,
            previousTextLength: previousTextLength,
            style: style,
          )
        : Text(text, style: style);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(child: textWidget),
        const SizedBox(width: 2),
        _BlinkingCursor(
          color: cursorColor,
          width: cursorWidth,
          height: (style.fontSize ?? 14.0) * 1.15,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Animated text block — fades in newly-arrived characters
// ---------------------------------------------------------------------------

class _AnimatedTextBlock extends StatefulWidget {
  final String text;
  final int previousTextLength;
  final TextStyle style;

  const _AnimatedTextBlock({
    required this.text,
    required this.previousTextLength,
    required this.style,
  });

  @override
  State<_AnimatedTextBlock> createState() => _AnimatedTextBlockState();
}

class _AnimatedTextBlockState extends State<_AnimatedTextBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    // Start fully visible if there's no new text to animate.
    if (widget.previousTextLength >= widget.text.length) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text &&
        widget.previousTextLength < widget.text.length) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previousLength = widget.previousTextLength.clamp(
      0,
      widget.text.length,
    );
    final stableText = widget.text.substring(0, previousLength);
    final newText = widget.text.substring(previousLength);

    if (newText.isEmpty) {
      return Text(stableText, style: widget.style);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: stableText, style: widget.style),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: FadeTransition(
              opacity: _opacity,
              child: Text(newText, style: widget.style),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Blinking cursor
// ---------------------------------------------------------------------------

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  final double width;
  final double height;

  const _BlinkingCursor({
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.width / 2),
        ),
      ),
    );
  }
}
