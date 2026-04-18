import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../chat_experience_config.dart';
import 'attachment_menu.dart';
import 'attachment_picker.dart';
import 'mode_picker_sheet.dart';
import 'model_selector_sheet.dart';

/// A composer widget with model selection, attachment menu, and voice input.
///
/// Use [FlaiComposerV2] at the bottom of the chat screen to let users type
/// messages, attach files, switch models, and start voice conversations.
///
/// Voice follows the CMMD Sidekick pattern: tap mic → inline waveform with
/// timer appears in the action row → tap stop → transcript populates the
/// text field for review → user sends manually.
class FlaiComposerV2 extends StatefulWidget {
  /// The chat experience configuration.
  final ChatExperienceConfig config;

  /// Called when the user submits a message.
  final ValueChanged<String> onSend;

  /// The currently selected model id.
  final String? currentModelId;

  /// Called when the user picks a new model.
  final ValueChanged<ModelOption>? onModelChanged;

  /// The currently selected chat-mode id (e.g. `autopilot`). When the
  /// composer's [ChatExperienceConfig.availableModes] is non-empty, the
  /// composer renders a "mode pill" instead of the model chip and reports
  /// changes via [onModeChanged].
  final String? currentModeId;

  /// Called when the user picks a new chat mode.
  final ValueChanged<ChatMode>? onModeChanged;

  /// The currently selected search-mode id (e.g. `smart`). Persisted by
  /// the host (per-chat) and surfaced inside the "+" sheet's `Search
  /// Mode` segmented control.
  final String? currentSearchModeId;

  /// Called when the user picks a new search mode in the "+" sheet.
  final ValueChanged<SearchModeOption>? onSearchModeChanged;

  /// Called when the user taps the mic to start voice recording.
  final VoidCallback? onVoiceStart;

  /// Called when the user taps stop to end voice recording.
  final VoidCallback? onVoiceStop;

  /// Whether the microphone is actively listening.
  final bool isRecording;

  /// Whether recorded audio is being transcribed to text.
  final bool isTranscribing;

  /// Transcribed text from voice input.
  ///
  /// When this changes to a non-null, non-empty value, the text is
  /// populated into the text field for the user to review before sending.
  final String? voiceTranscript;

  /// Creates a [FlaiComposerV2].
  const FlaiComposerV2({
    super.key,
    required this.config,
    required this.onSend,
    this.currentModelId,
    this.onModelChanged,
    this.currentModeId,
    this.onModeChanged,
    this.currentSearchModeId,
    this.onSearchModeChanged,
    this.onVoiceStart,
    this.onVoiceStop,
    this.isRecording = false,
    this.isTranscribing = false,
    this.voiceTranscript,
  });

  @override
  State<FlaiComposerV2> createState() => _FlaiComposerV2State();
}

class _FlaiComposerV2State extends State<FlaiComposerV2> {
  final TextEditingController _textController = TextEditingController();
  final List<PickedAttachment> _pendingAttachments = [];
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
  }

  @override
  void didUpdateWidget(FlaiComposerV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When voice transcript arrives, populate the text field.
    if (widget.voiceTranscript != null &&
        widget.voiceTranscript != oldWidget.voiceTranscript &&
        widget.voiceTranscript!.isNotEmpty) {
      _textController.text = widget.voiceTranscript!;
      setState(() => _hasText = true);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;
    _textController.clear();
    setState(() => _pendingAttachments.clear());
    widget.onSend(text.isEmpty ? '[attachment]' : text);
  }

  Future<void> _openAttachmentMenu() async {
    await showAttachmentMenu(
      context: context,
      config: widget.config.composerConfig,
      searchModes: widget.config.availableSearchModes,
      currentSearchModeId: widget.currentSearchModeId,
      onSearchModeChanged: widget.onSearchModeChanged,
      onAttachmentPicked: (picked) {
        setState(() => _pendingAttachments.add(picked));
      },
    );
  }

  Future<void> _openModelSelector() async {
    final model = await showModelSelector(
      context: context,
      models: widget.config.availableModels,
      currentModelId: widget.currentModelId,
    );
    if (model != null) {
      widget.onModelChanged?.call(model);
    }
  }

  Future<void> _openModePicker() async {
    final mode = await showModePicker(
      context: context,
      modes: widget.config.availableModes,
      currentModeId: widget.currentModeId,
    );
    if (mode != null) {
      widget.onModeChanged?.call(mode);
    }
  }

  String? get _currentModelName {
    if (widget.currentModelId == null) return null;
    try {
      return widget.config.availableModels
          .firstWhere((m) => m.id == widget.currentModelId)
          .name;
    } catch (_) {
      return null;
    }
  }

  ChatMode? get _currentMode {
    final modes = widget.config.availableModes;
    if (modes.isEmpty) return null;
    try {
      return modes.firstWhere((m) => m.id == widget.currentModeId);
    } catch (_) {
      return modes.first;
    }
  }

  void _handleMicTap() {
    if (widget.isRecording) {
      widget.onVoiceStop?.call();
    } else {
      widget.onVoiceStart?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.muted,
        borderRadius: BorderRadius.circular(theme.radius.xl),
        border: Border.all(color: theme.colors.border, width: 0.5),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: theme.spacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment previews
          if (_pendingAttachments.isNotEmpty)
            _AttachmentPreviewRow(
              attachments: _pendingAttachments,
              onRemove: (index) {
                setState(() => _pendingAttachments.removeAt(index));
              },
            ),
          // Text field (always visible)
          TextField(
            controller: _textController,
            maxLines: 5,
            minLines: 1,
            onSubmitted: (_) => _handleSend(),
            textInputAction: TextInputAction.send,
            style: theme.typography.base.copyWith(
              color: theme.colors.foreground,
            ),
            decoration: InputDecoration(
              hintText: widget.isRecording
                  ? 'Listening\u2026'
                  : widget.config.resolvedPlaceholder,
              hintStyle: theme.typography.base.copyWith(
                color: theme.colors.mutedForeground,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: theme.spacing.xs,
                vertical: theme.spacing.xs,
              ),
            ),
          ),
          // Bottom action row — changes layout when recording
          if (widget.isRecording || widget.isTranscribing)
            _buildRecordingRow(theme)
          else
            _buildIdleRow(theme),
        ],
      ),
    );
  }

  /// Action row when idle: [+] [mode pill OR model chip] [spacer] [mic or send]
  Widget _buildIdleRow(FlaiThemeData theme) {
    final mode = _currentMode;
    return Row(
      children: [
        _ComposerIconButton(
          icon: Icons.add,
          filled: false,
          onTap: _openAttachmentMenu,
        ),
        if (mode != null) ...[
          SizedBox(width: theme.spacing.xs),
          _ModePill(mode: mode, onTap: _openModePicker),
        ] else if (widget.config.availableModels.isNotEmpty) ...[
          SizedBox(width: theme.spacing.xs),
          _ModelChip(
            name: _currentModelName ?? widget.config.availableModels.first.name,
            onTap: _openModelSelector,
          ),
        ],
        const Spacer(),
        _AnimatedSendButton(
          showMic: widget.config.enableVoice && !_hasText,
          hasText: _hasText,
          onMicTap: _handleMicTap,
          onSendTap: _handleSend,
        ),
      ],
    );
  }

  /// Action row when recording/transcribing:
  /// [---waveform--- 00:02] [stop] [send]
  /// The [+] and model chip are hidden to give the waveform full width.
  Widget _buildRecordingRow(FlaiThemeData theme) {
    return Row(
      children: [
        // Waveform + timer fill all available space on the left
        Expanded(
          child: widget.isTranscribing
              ? _TranscribingIndicator()
              : _InlineWaveform(),
        ),
        SizedBox(width: theme.spacing.xs),
        // Stop button with red ring
        _StopButton(onTap: () => widget.onVoiceStop?.call()),
        // Send button (always available when recording — transcript may be in field)
        _ComposerIconButton(
          icon: Icons.arrow_upward,
          filled: _hasText,
          onTap: _hasText ? _handleSend : null,
        ),
      ],
    );
  }
}

// ── Mode Pill ───────────────────────────────────────────────────────────────

/// CMMD-style mode pill: an accent-tinted icon, the mode name, and a chevron.
///
/// Renders as `[✦] Autopilot ▾` and matches the web composer's mode picker.
class _ModePill extends StatelessWidget {
  final ChatMode mode;
  final VoidCallback? onTap;

  const _ModePill({required this.mode, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final accent = mode.accent ?? theme.colors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(theme.radius.full),
          border: Border.all(color: theme.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 14, color: accent),
            SizedBox(width: theme.spacing.xs),
            Text(
              mode.name,
              style: theme.typography.sm.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: theme.colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Model Chip ──────────────────────────────────────────────────────────────

class _ModelChip extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const _ModelChip({required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(theme.radius.full),
          border: Border.all(color: theme.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: theme.typography.sm.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: theme.spacing.xs),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: theme.colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inline Waveform ─────────────────────────────────────────────────────────

/// Animated waveform visualization with recording timer, shown inline
/// in the action row while recording. Matches the CMMD Sidekick pattern:
/// dotted line → audio bars → "00:02" timer.
class _InlineWaveform extends StatefulWidget {
  @override
  State<_InlineWaveform> createState() => _InlineWaveformState();
}

class _InlineWaveformState extends State<_InlineWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Timer _timerTick;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat();
    _timerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _timerTick.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Row(
      children: [
        // Waveform bars
        Expanded(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(double.infinity, 24),
                painter: _WaveformPainter(
                  color: theme.colors.foreground,
                  dotColor: theme.colors.mutedForeground.withValues(alpha: 0.4),
                  phase: _animController.value,
                  seed: _elapsedSeconds,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        // Timer
        Text(
          _formattedTime,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Custom painter that draws a waveform with dotted leader line and
/// animated audio bars, matching the CMMD Sidekick visual.
class _WaveformPainter extends CustomPainter {
  final Color color;
  final Color dotColor;
  final double phase;
  final int seed;

  _WaveformPainter({
    required this.color,
    required this.dotColor,
    required this.phase,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final midY = size.height / 2;

    // Number of bars in the waveform section (right side).
    const barCount = 24;
    const barWidth = 2.0;
    const barGap = 2.0;
    final waveformWidth = barCount * (barWidth + barGap);
    final waveformStart = size.width - waveformWidth;

    // Draw dotted leader line from left edge to waveform start.
    final dotPaint = Paint()
      ..color = dotColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dotSpacing = 6.0;
    for (var x = 0.0; x < waveformStart - 8; x += dotSpacing) {
      canvas.drawCircle(Offset(x, midY), 1, dotPaint);
    }

    // Draw animated waveform bars.
    final barPaint = Paint()
      ..color = color
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < barCount; i++) {
      final x = waveformStart + i * (barWidth + barGap) + barWidth / 2;
      // Create varied heights with animation.
      final baseHeight = 0.2 + random.nextDouble() * 0.8;
      final animOffset = sin((phase * 2 * pi) + (i * 0.3)) * 0.3;
      final height =
          (baseHeight + animOffset).clamp(0.1, 1.0) * (size.height * 0.8);
      final halfH = height / 2;

      canvas.drawLine(
        Offset(x, midY - halfH),
        Offset(x, midY + halfH),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}

// ── Transcribing Indicator ──────────────────────────────────────────────────

/// Inline transcribing spinner shown in the action row after recording stops.
class _TranscribingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: theme.colors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Transcribing\u2026',
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

// ── Stop Button ─────────────────────────────────────────────────────────────

/// Stop button with red ring border, matching CMMD Sidekick.
/// Shows a white stop square icon inside a circle with red ring.
class _StopButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StopButton({required this.onTap});

  static const _activeColor = Color(0xFFFF3B30);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _activeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: _activeColor.withValues(alpha: 0.4),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.stop_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Attachment Preview Row ──────────────────────────────────────────────────

/// Horizontal row of attachment thumbnails shown above the text field.
class _AttachmentPreviewRow extends StatelessWidget {
  final List<PickedAttachment> attachments;
  final void Function(int index) onRemove;

  const _AttachmentPreviewRow({
    required this.attachments,
    required this.onRemove,
  });

  bool _isImage(PickedAttachment a) {
    final mime = a.mimeType ?? '';
    return mime.startsWith('image/') ||
        a.name.endsWith('.jpg') ||
        a.name.endsWith('.jpeg') ||
        a.name.endsWith('.png') ||
        a.name.endsWith('.heic');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.xs,
          vertical: theme.spacing.xs,
        ),
        itemCount: attachments.length,
        itemBuilder: (_, index) {
          final a = attachments[index];
          return Padding(
            padding: EdgeInsets.only(right: theme.spacing.xs),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(theme.radius.md),
                    border: Border.all(color: theme.colors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isImage(a)
                      ? Image.file(
                          File(a.path),
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insert_drive_file,
                              size: 20,
                              color: theme.colors.mutedForeground,
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                a.name,
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
                // Remove button
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: () => onRemove(index),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: theme.colors.foreground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: theme.colors.background,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Animated Send Button ────────────────────────────────────────────────────

/// Smoothly morphs between mic and send-arrow icons.
///
/// Uses [AnimatedSwitcher] with a scale+fade transition for a polished
/// mic → arrow morph as the user types. The filled background also
/// animates via [AnimatedContainer].
class _AnimatedSendButton extends StatelessWidget {
  final bool showMic;
  final bool hasText;
  final VoidCallback onMicTap;
  final VoidCallback onSendTap;

  const _AnimatedSendButton({
    required this.showMic,
    required this.hasText,
    required this.onMicTap,
    required this.onSendTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final filled = hasText;
    final bgColor = filled ? theme.colors.primary : theme.colors.background;
    final fgColor = filled
        ? theme.colors.primaryForeground
        : theme.colors.foreground;

    return GestureDetector(
      onTap: showMic ? onMicTap : (hasText ? onSendTap : null),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: filled ? null : Border.all(color: theme.colors.border),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                showMic ? Icons.mic : Icons.arrow_upward,
                key: ValueKey(showMic ? 'mic' : 'arrow'),
                size: 18,
                color: fgColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Composer Icon Button ────────────────────────────────────────────────────

/// A circular icon button used inside the composer.
///
/// Meets Apple HIG minimum touch target of 44x44pt.
class _ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  const _ComposerIconButton({
    required this.icon,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    final bgColor = filled ? theme.colors.primary : theme.colors.background;
    final fgColor = filled
        ? theme.colors.primaryForeground
        : theme.colors.foreground;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: filled ? null : Border.all(color: theme.colors.border),
            ),
            child: Icon(icon, size: 18, color: fgColor),
          ),
        ),
      ),
    );
  }
}
