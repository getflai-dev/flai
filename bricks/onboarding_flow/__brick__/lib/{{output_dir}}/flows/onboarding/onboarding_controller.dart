import 'package:flutter/foundation.dart';
import 'onboarding_config.dart';

/// Manages onboarding step navigation and result collection.
///
/// Uses [ChangeNotifier] so screens can rebuild via [ListenableBuilder].
class OnboardingController extends ChangeNotifier {
  OnboardingController({
    required OnboardingConfig config,
  }) : _config = config;

  final OnboardingConfig _config;

  /// Current step index in the pipeline.
  int _currentIndex = 0;

  /// Collected assistant name (set by naming step, or default).
  String _assistantName = '';

  /// Collected selected options (set by multi-select step).
  List<String> _selectedOptions = [];

  /// Whether the flow has completed.
  bool _isComplete = false;

  // ── Getters ──────────────────────────────────────────────────────

  OnboardingConfig get config => _config;
  int get currentIndex => _currentIndex;
  int get totalSteps => _config.steps.length;
  bool get isComplete => _isComplete;
  String get assistantName =>
      _assistantName.isEmpty ? _defaultName : _assistantName;

  /// The current step, or `null` if the flow is complete.
  OnboardingStep? get currentStep =>
      _currentIndex < _config.steps.length ? _config.steps[_currentIndex] : null;

  /// Whether there is a previous step to go back to.
  bool get canGoBack => _currentIndex > 0;

  /// Collected selected options from the multi-select step.
  List<String> get selectedOptions => _selectedOptions;

  // ── Navigation ───────────────────────────────────────────────────

  /// Advance to the next step. If this is the last step, complete the flow.
  void next() {
    if (_currentIndex < _config.steps.length - 1) {
      _currentIndex++;
      notifyListeners();
    } else {
      _complete();
    }
  }

  /// Go back to the previous step.
  void back() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  /// Skip the current step and advance.
  void skip() => next();

  // ── Step Results ─────────────────────────────────────────────────

  /// Set the assistant name from the naming step.
  void setAssistantName(String name) {
    _assistantName = name.trim();
    notifyListeners();
  }

  /// Set the selected options from the multi-select step.
  void setSelectedOptions(List<String> options) {
    _selectedOptions = options;
    notifyListeners();
  }

  // ── Private ──────────────────────────────────────────────────────

  String get _defaultName {
    for (final step in _config.steps) {
      if (step is NamingStep) return step.defaultName;
    }
    return 'Assistant';
  }

  void _complete() {
    _isComplete = true;
    notifyListeners();
    _config.onComplete(OnboardingResult(
      assistantName: assistantName,
      selectedOptions: _selectedOptions,
    ));
  }
}
