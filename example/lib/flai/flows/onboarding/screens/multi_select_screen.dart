import 'package:flutter/material.dart';
import '../../../core/theme/flai_theme.dart';
import '../onboarding_config.dart';
import '../onboarding_controller.dart';
import '../widgets/pill_chip.dart';

/// Screen that displays a multi-select grid of pill chips with staggered
/// fade-in + slide-up entry animations.
///
/// Respects [MultiSelectStep.minSelections] and [MultiSelectStep.maxSelections].
/// The Continue button is disabled until the minimum selection count is met.
class FlaiMultiSelectScreen extends StatefulWidget {
  const FlaiMultiSelectScreen({
    super.key,
    required this.controller,
    required this.step,
  });

  final OnboardingController controller;
  final MultiSelectStep step;

  @override
  State<FlaiMultiSelectScreen> createState() => _FlaiMultiSelectScreenState();
}

class _FlaiMultiSelectScreenState extends State<FlaiMultiSelectScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    final optionCount = widget.step.options.length;
    _staggerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (optionCount * 80)),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  bool get _meetsMinimum => _selected.length >= widget.step.minSelections;

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        final max = widget.step.maxSelections;
        if (max == null || _selected.length < max) {
          _selected.add(label);
        }
      }
    });
  }

  void _submit() {
    widget.controller.setSelectedOptions(_selected.toList());
    widget.controller.next();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final options = widget.step.options;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: theme.colors.background,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: theme.spacing.md),

                  // ── Back button ──────────────────────────────────────
                  if (widget.controller.canGoBack)
                    IconButton(
                      onPressed: widget.controller.back,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: theme.colors.foreground,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                  SizedBox(height: theme.spacing.xxl),

                  // ── Title ────────────────────────────────────────────
                  Text(
                    widget.step.title,
                    style: theme.typography.xl.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colors.foreground,
                    ),
                  ),

                  if (widget.step.subtitle != null) ...[
                    SizedBox(height: theme.spacing.sm),
                    Text(
                      widget.step.subtitle!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],

                  SizedBox(height: theme.spacing.xl),

                  // ── Staggered pill grid ──────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      child: AnimatedBuilder(
                        animation: _staggerController,
                        builder: (context, _) {
                          return Wrap(
                            spacing: theme.spacing.sm,
                            runSpacing: theme.spacing.sm,
                            children: List.generate(options.length, (i) {
                              final option = options[i];
                              final staggerEnd = 1.0;
                              final staggerStart =
                                  (i / options.length).clamp(0.0, 0.85);
                              final interval = Interval(
                                staggerStart,
                                staggerEnd,
                                curve: Curves.easeOut,
                              );
                              final progress = interval
                                  .transform(_staggerController.value);

                              return Opacity(
                                opacity: progress,
                                child: Transform.translate(
                                  offset: Offset(0, 16 * (1.0 - progress)),
                                  child: PillChip(
                                    label: option.label,
                                    icon: option.icon,
                                    isSelected:
                                        _selected.contains(option.label),
                                    onTap: () => _toggle(option.label),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),

                  // ── Bottom actions ───────────────────────────────────
                  Padding(
                    padding: EdgeInsets.only(bottom: theme.spacing.xl),
                    child: Row(
                      children: [
                        // Skip
                        TextButton(
                          onPressed: widget.controller.skip,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            foregroundColor: theme.colors.mutedForeground,
                          ),
                          child: Text(
                            'Skip',
                            style: theme.typography.sm,
                          ),
                        ),

                        const Spacer(),

                        // Continue — disabled when below minSelections
                        SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: _meetsMinimum ? _submit : null,
                            style: TextButton.styleFrom(
                              backgroundColor: _meetsMinimum
                                  ? theme.colors.foreground
                                  : theme.colors.muted,
                              foregroundColor: _meetsMinimum
                                  ? theme.colors.background
                                  : theme.colors.mutedForeground,
                              padding: EdgeInsets.symmetric(
                                horizontal: theme.spacing.xl,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  theme.radius.md,
                                ),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: theme.typography.sm.copyWith(
                                color: _meetsMinimum
                                    ? theme.colors.background
                                    : theme.colors.mutedForeground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
