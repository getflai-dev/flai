import 'package:flutter/material.dart';
import '../../../core/theme/flai_theme.dart';
import '../onboarding_config.dart';
import '../onboarding_controller.dart';

/// Screen that prompts the user to name their AI assistant.
///
/// Displays a text field with a default hint, optional suggestion pills that
/// populate the field on tap, and Skip / Continue action buttons.
class FlaiNamingScreen extends StatefulWidget {
  const FlaiNamingScreen({
    super.key,
    required this.controller,
    required this.step,
  });

  final OnboardingController controller;
  final NamingStep step;

  @override
  State<FlaiNamingScreen> createState() => _FlaiNamingScreenState();
}

class _FlaiNamingScreenState extends State<FlaiNamingScreen> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _textController.text.trim();
    if (name.isNotEmpty) {
      widget.controller.setAssistantName(name);
    }
    widget.controller.next();
  }

  void _fillSuggestion(String name) {
    _textController
      ..text = name
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: name.length),
      );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

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

                  // ── Text input ───────────────────────────────────────
                  TextField(
                    controller: _textController,
                    style: theme.typography.base.copyWith(
                      color: theme.colors.foreground,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.step.defaultName,
                      hintStyle: theme.typography.base.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: theme.colors.border),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) => setState(() {}),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // ── Suggestion pills ─────────────────────────────────
                  if (widget.step.suggestions.isNotEmpty)
                    Wrap(
                      spacing: theme.spacing.sm,
                      runSpacing: theme.spacing.sm,
                      children: widget.step.suggestions.map((name) {
                        return GestureDetector(
                          onTap: () => _fillSuggestion(name),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: theme.spacing.md,
                              vertical: theme.spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                theme.radius.full,
                              ),
                              border: Border.all(color: theme.colors.border),
                            ),
                            child: Text(
                              name,
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.foreground,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const Spacer(),

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
                          child: Text('Skip', style: theme.typography.sm),
                        ),

                        const Spacer(),

                        // Continue
                        SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: _submit,
                            style: TextButton.styleFrom(
                              backgroundColor: theme.colors.foreground,
                              foregroundColor: theme.colors.background,
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
                                color: theme.colors.background,
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
