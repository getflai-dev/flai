import 'package:flutter/widgets.dart';

/// A single option for the multi-select pills screen.
class PillOption {
  const PillOption({required this.label, this.icon});

  /// Display text for the pill.
  final String label;

  /// Optional icon shown before the label.
  final IconData? icon;
}

/// A step in the onboarding pipeline.
///
/// Use the named constructors to create steps:
/// - [OnboardingStep.naming] — name-your-assistant screen
/// - [OnboardingStep.multiSelect] — multi-select pills screen
/// - [OnboardingStep.custom] — arbitrary developer widget
/// - [OnboardingStep.reveal] — celebratory reveal animation
sealed class OnboardingStep {
  const OnboardingStep();

  const factory OnboardingStep.naming({
    required String title,
    String? subtitle,
    List<String> suggestions,
    String defaultName,
  }) = NamingStep;

  const factory OnboardingStep.multiSelect({
    required String title,
    String? subtitle,
    required List<PillOption> options,
    int minSelections,
    int? maxSelections,
  }) = MultiSelectStep;

  const factory OnboardingStep.custom({
    required Widget Function(BuildContext context, VoidCallback onNext) builder,
  }) = CustomStep;

  const factory OnboardingStep.reveal({
    String? title,
    String? subtitle,
    Duration holdDuration,
  }) = RevealStep;
}

/// Name-your-assistant step configuration.
class NamingStep extends OnboardingStep {
  const NamingStep({
    required this.title,
    this.subtitle,
    this.suggestions = const ['Atlas', 'Nova', 'Sage', 'Aria', 'Kai'],
    this.defaultName = 'Assistant',
  });

  final String title;
  final String? subtitle;
  final List<String> suggestions;
  final String defaultName;
}

/// Multi-select pills step configuration.
class MultiSelectStep extends OnboardingStep {
  const MultiSelectStep({
    required this.title,
    this.subtitle,
    required this.options,
    this.minSelections = 0,
    this.maxSelections,
  });

  final String title;
  final String? subtitle;
  final List<PillOption> options;
  final int minSelections;
  final int? maxSelections;
}

/// Custom developer-provided step.
class CustomStep extends OnboardingStep {
  const CustomStep({required this.builder});

  final Widget Function(BuildContext context, VoidCallback onNext) builder;
}

/// Reveal animation step configuration.
class RevealStep extends OnboardingStep {
  const RevealStep({
    this.title,
    this.subtitle,
    this.holdDuration = const Duration(milliseconds: 1500),
  });

  /// Title template. Use `{name}` for assistant name interpolation.
  /// Defaults to `'Meet {name}'`.
  final String? title;

  /// Subtitle shown below the title.
  /// Defaults to `'Your AI assistant is ready'`.
  final String? subtitle;

  /// How long to hold the reveal before auto-transitioning.
  final Duration holdDuration;
}

/// Collected results from the onboarding flow.
class OnboardingResult {
  const OnboardingResult({
    required this.assistantName,
    this.selectedOptions = const [],
  });

  /// The name chosen for the assistant (from NamingStep or default).
  final String assistantName;

  /// Labels selected in the multi-select step.
  final List<String> selectedOptions;
}

/// Configuration for the onboarding flow.
class OnboardingConfig {
  const OnboardingConfig({
    this.splashLogo,
    required this.steps,
    this.revealLogo,
    this.revealGradient = const [Color(0xFF818CF8), Color(0xFF34D399)],
    required this.onComplete,
  });

  /// Logo widget displayed on the splash screen.
  final Widget? splashLogo;

  /// Ordered list of onboarding steps. Remove or reorder as needed.
  final List<OnboardingStep> steps;

  /// Logo widget displayed during the reveal animation.
  /// Falls back to [splashLogo] if not provided.
  final Widget? revealLogo;

  /// Gradient colors for the reveal glow effect.
  final List<Color> revealGradient;

  /// Called when the onboarding flow completes with collected results.
  final void Function(OnboardingResult result) onComplete;
}
