import 'package:flutter/widgets.dart';

import 'providers/auth_provider.dart';
import 'providers/storage_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/voice_provider.dart';

/// InheritedWidget that exposes all four provider interfaces to the widget tree.
///
/// Wrap the app (or a subtree) with [FlaiProviders] so that any descendant can
/// retrieve provider instances via [FlaiProviders.of(context)].
///
/// [storageProvider] defaults to [InMemoryStorageProvider] when the consumer
/// passes a null value through [AppScaffoldConfig].
///
/// ```dart
/// FlaiProviders(
///   authProvider: myAuthProvider,
///   storageProvider: myStorageProvider,
///   aiProvider: myAiProvider,
///   child: MaterialApp(...),
/// )
/// ```
class FlaiProviders extends InheritedWidget {
  /// The authentication provider for sign-in, sign-up, and session management.
  final AuthProvider authProvider;

  /// The persistence layer for conversations and messages.
  final StorageProvider storageProvider;

  /// The AI chat provider for streaming completions and tool use.
  ///
  /// May be null if no AI backend has been configured yet.
  final AiProvider? aiProvider;

  /// The voice provider for speech-to-text and text-to-speech.
  ///
  /// May be null if voice features are not enabled.
  final VoiceProvider? voiceProvider;

  /// Creates a [FlaiProviders] widget.
  const FlaiProviders({
    super.key,
    required this.authProvider,
    required this.storageProvider,
    this.aiProvider,
    this.voiceProvider,
    required super.child,
  });

  /// Retrieves the nearest [FlaiProviders] from the widget tree.
  ///
  /// Throws an assertion error in debug mode if no [FlaiProviders] ancestor
  /// is found.
  static FlaiProviders of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<FlaiProviders>();
    assert(result != null, 'No FlaiProviders found in widget tree');
    return result!;
  }

  @override
  bool updateShouldNotify(FlaiProviders oldWidget) =>
      authProvider != oldWidget.authProvider ||
      storageProvider != oldWidget.storageProvider ||
      aiProvider != oldWidget.aiProvider ||
      voiceProvider != oldWidget.voiceProvider;
}
