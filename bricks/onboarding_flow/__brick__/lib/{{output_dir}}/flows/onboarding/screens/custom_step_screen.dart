import 'package:flutter/material.dart';
import '../onboarding_config.dart';
import '../onboarding_controller.dart';

/// Thin wrapper that renders a developer-provided custom onboarding step.
///
/// The [CustomStep.builder] receives the build context and an `onNext`
/// callback that the developer calls to advance to the next step.
class FlaiCustomStepScreen extends StatelessWidget {
  const FlaiCustomStepScreen({
    super.key,
    required this.controller,
    required this.step,
  });

  final OnboardingController controller;
  final CustomStep step;

  @override
  Widget build(BuildContext context) {
    return step.builder(context, controller.next);
  }
}
