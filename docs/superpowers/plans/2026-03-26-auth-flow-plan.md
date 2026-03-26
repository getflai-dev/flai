# Auth Flow + Provider Interfaces — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add AuthProvider, StorageProvider, and VoiceProvider interfaces to core, then build the complete auth_flow brick with 6 screens and an AuthController state machine.

**Architecture:** New provider interfaces go into the `flai_init` brick alongside `AiProvider`. The `auth_flow` brick generates screens into `lib/{{output_dir}}/flows/auth/`. It depends on `flai_init` and follows the same Mason template pattern as existing bricks. An `AuthController` (ChangeNotifier) manages the auth state machine. A `MockAuthProvider` ships as the default for development.

**Tech Stack:** Dart 3.4+, Flutter, Mason bricks, sealed classes, ChangeNotifier

**Spec:** `docs/superpowers/specs/2026-03-26-mobile-chat-app-blueprint-design.md` — Sections 1.2, 2, 6

---

## File Map

### Modified: `bricks/flai_init/`

| File | Responsibility |
|------|---------------|
| `__brick__/lib/{{output_dir}}/providers/auth_provider.dart` | AuthProvider interface, AuthUser, AuthResult, AuthState |
| `__brick__/lib/{{output_dir}}/providers/storage_provider.dart` | StorageProvider interface |
| `__brick__/lib/{{output_dir}}/providers/voice_provider.dart` | VoiceProvider interface, VoiceEvent |
| `__brick__/lib/{{output_dir}}/flai.dart` | Add exports for new provider files |

### Created: `bricks/auth_flow/`

| File | Responsibility |
|------|---------------|
| `brick.yaml` | Brick metadata, vars, dependencies |
| `__brick__/lib/{{output_dir}}/flows/auth/auth_controller.dart` | Auth state machine (ChangeNotifier) |
| `__brick__/lib/{{output_dir}}/flows/auth/auth_flow_config.dart` | AuthFlowConfig + SocialAuthType |
| `__brick__/lib/{{output_dir}}/flows/auth/mock_auth_provider.dart` | MockAuthProvider for development |
| `__brick__/lib/{{output_dir}}/flows/auth/screens/login_landing.dart` | Rotating taglines + auth buttons |
| `__brick__/lib/{{output_dir}}/flows/auth/screens/email_entry.dart` | Email input + social auth |
| `__brick__/lib/{{output_dir}}/flows/auth/screens/password_entry.dart` | Password input (login + signup modes) |
| `__brick__/lib/{{output_dir}}/flows/auth/screens/forgot_password.dart` | Reset password confirmation |
| `__brick__/lib/{{output_dir}}/flows/auth/screens/verification_code.dart` | Code input (shared for signup + reset) |
| `__brick__/lib/{{output_dir}}/flows/auth/screens/reset_password.dart` | New password entry |
| `__brick__/lib/{{output_dir}}/flows/auth/widgets/social_auth_button.dart` | Styled social auth button |
| `__brick__/lib/{{output_dir}}/flows/auth/widgets/auth_text_field.dart` | Themed text field for auth forms |
| `__brick__/lib/{{output_dir}}/flows/auth/widgets/typing_tagline.dart` | Animated typing text with rotation |
| `__brick__/lib/{{output_dir}}/flows/auth/auth_flow.dart` | Barrel export file |

### Modified: `packages/flai_cli/`

| File | Responsibility |
|------|---------------|
| `lib/brick_registry.dart` | Add auth_flow entry |

---

## Task 1: AuthProvider Interface

**Files:**
- Create: `bricks/flai_init/__brick__/lib/{{output_dir}}/providers/auth_provider.dart`

- [ ] **Step 1: Create AuthProvider interface with AuthUser, AuthResult, AuthState**

```dart
// bricks/flai_init/__brick__/lib/{{output_dir}}/providers/auth_provider.dart

/// Represents the current authentication state.
enum AuthState {
  /// Initial state, auth status unknown.
  unknown,

  /// User is authenticated.
  authenticated,

  /// User is not authenticated.
  unauthenticated,
}

/// Authenticated user data.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.metadata,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final Map<String, dynamic>? metadata;

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Result of an authentication operation.
sealed class AuthResult {
  const AuthResult();
}

/// Authentication succeeded.
class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final AuthUser user;
}

/// Authentication failed with an error.
class AuthFailure extends AuthResult {
  const AuthFailure(this.message, {this.code});
  final String message;
  final String? code;
}

/// Email needs verification before completing auth.
class AuthNeedsVerification extends AuthResult {
  const AuthNeedsVerification(this.email);
  final String email;
}

/// Abstract interface for authentication providers.
///
/// Implement this to connect your backend (Firebase, Supabase, custom API).
/// Use [MockAuthProvider] during development.
abstract class AuthProvider {
  // Social auth
  Future<AuthResult> signInWithApple();
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithMicrosoft();

  // Email auth
  Future<AuthResult> signInWithEmail(String email, String password);
  Future<AuthResult> signUp(String email, String password);

  // Password reset
  Future<void> sendResetEmail(String email);
  Future<AuthResult> confirmResetCode(String email, String code);
  Future<void> resetPassword(String email, String newPassword);

  // Verification
  Future<void> sendVerificationCode(String email);
  Future<AuthResult> verifyCode(String email, String code);

  // Session
  Future<void> signOut();
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
}
```

- [ ] **Step 2: Verify no syntax errors**

Run: `cd bricks/flai_init/__brick__ && dart analyze lib/`

If this fails because it's a template directory, verify manually that the Dart syntax is valid by checking for balanced braces, correct imports, and no typos.

- [ ] **Step 3: Commit**

```bash
git add bricks/flai_init/__brick__/lib/\{\{output_dir\}\}/providers/auth_provider.dart
git commit -m "feat(flai_init): add AuthProvider interface with AuthUser, AuthResult, AuthState"
```

---

## Task 2: StorageProvider Interface

**Files:**
- Create: `bricks/flai_init/__brick__/lib/{{output_dir}}/providers/storage_provider.dart`

- [ ] **Step 1: Create StorageProvider interface**

```dart
// bricks/flai_init/__brick__/lib/{{output_dir}}/providers/storage_provider.dart

import '../core/models/conversation.dart';
import '../core/models/message.dart';

/// Abstract interface for conversation persistence.
///
/// Implement this to store conversations in SQLite, Hive, or a remote API.
/// Use [InMemoryStorageProvider] during development.
abstract class StorageProvider {
  // Conversations
  Future<List<Conversation>> loadConversations();
  Future<Conversation> saveConversation(Conversation conversation);
  Future<void> deleteConversation(String id);

  // Starring
  Future<void> starConversation(String id);
  Future<void> unstarConversation(String id);
  Future<List<Conversation>> loadStarredConversations();

  // Messages
  Future<List<Message>> loadMessages(String conversationId);
  Future<void> saveMessage(String conversationId, Message message);

  // Search
  Future<List<Conversation>> searchConversations(String query);

  // Metadata
  Future<void> renameConversation(String id, String newTitle);
}

/// In-memory storage provider for development and testing.
///
/// Data is lost when the app restarts. Replace with a persistent
/// implementation for production.
class InMemoryStorageProvider implements StorageProvider {
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<Message>> _messages = {};
  final Set<String> _starred = {};

  @override
  Future<List<Conversation>> loadConversations() async {
    final list = _conversations.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<Conversation> saveConversation(Conversation conversation) async {
    _conversations[conversation.id] = conversation;
    return conversation;
  }

  @override
  Future<void> deleteConversation(String id) async {
    _conversations.remove(id);
    _messages.remove(id);
    _starred.remove(id);
  }

  @override
  Future<void> starConversation(String id) async {
    _starred.add(id);
  }

  @override
  Future<void> unstarConversation(String id) async {
    _starred.remove(id);
  }

  @override
  Future<List<Conversation>> loadStarredConversations() async {
    return _conversations.values
        .where((c) => _starred.contains(c.id))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<Message>> loadMessages(String conversationId) async {
    return _messages[conversationId] ?? [];
  }

  @override
  Future<void> saveMessage(String conversationId, Message message) async {
    _messages.putIfAbsent(conversationId, () => []);
    final messages = _messages[conversationId]!;
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.add(message);
    }
  }

  @override
  Future<List<Conversation>> searchConversations(String query) async {
    final lower = query.toLowerCase();
    return _conversations.values.where((c) {
      if (c.title?.toLowerCase().contains(lower) ?? false) return true;
      final msgs = _messages[c.id];
      if (msgs == null) return false;
      return msgs.any((m) => m.content.toLowerCase().contains(lower));
    }).toList();
  }

  @override
  Future<void> renameConversation(String id, String newTitle) async {
    final conv = _conversations[id];
    if (conv != null) {
      _conversations[id] = conv.copyWith(title: newTitle);
    }
  }
}
```

- [ ] **Step 2: Verify Conversation model has copyWith(title:)**

Read `bricks/flai_init/__brick__/lib/{{output_dir}}/core/models/conversation.dart` and confirm `copyWith` exists with a `title` parameter. If it doesn't, add it.

- [ ] **Step 3: Commit**

```bash
git add bricks/flai_init/__brick__/lib/\{\{output_dir\}\}/providers/storage_provider.dart
git commit -m "feat(flai_init): add StorageProvider interface with InMemoryStorageProvider"
```

---

## Task 3: VoiceProvider Interface

**Files:**
- Create: `bricks/flai_init/__brick__/lib/{{output_dir}}/providers/voice_provider.dart`

- [ ] **Step 1: Create VoiceProvider interface and VoiceEvent**

```dart
// bricks/flai_init/__brick__/lib/{{output_dir}}/providers/voice_provider.dart

import 'dart:typed_data';

/// Events emitted during voice conversation mode.
sealed class VoiceEvent {
  const VoiceEvent();
}

/// User speech was transcribed to text.
class VoiceTranscript extends VoiceEvent {
  const VoiceTranscript(this.text);
  final String text;
}

/// AI response audio is available for playback.
class VoiceAudio extends VoiceEvent {
  const VoiceAudio(this.audio);
  final Uint8List audio;
}

/// Voice conversation ended.
class VoiceConversationDone extends VoiceEvent {
  const VoiceConversationDone();
}

/// Voice error occurred.
class VoiceError extends VoiceEvent {
  const VoiceError(this.message);
  final String message;
}

/// Abstract interface for voice input/output.
///
/// Implement this to add speech-to-text and text-to-speech capabilities.
/// Both push-to-talk and continuous conversation modes use this interface.
abstract class VoiceProvider {
  /// Transcribe recorded audio to text (push-to-talk mode).
  Future<String> transcribe(Uint8List audio);

  /// Synthesize text to audio bytes for playback.
  Future<Uint8List> synthesize(String text);

  /// Start continuous voice conversation mode.
  Future<void> startConversation();

  /// Stop continuous voice conversation mode.
  Future<void> stopConversation();

  /// Stream of events during conversation mode.
  Stream<VoiceEvent> get conversationEvents;

  /// Whether the provider is currently listening for speech.
  bool get isListening;

  /// Whether the provider is currently playing audio.
  bool get isSpeaking;
}
```

- [ ] **Step 2: Commit**

```bash
git add bricks/flai_init/__brick__/lib/\{\{output_dir\}\}/providers/voice_provider.dart
git commit -m "feat(flai_init): add VoiceProvider interface with VoiceEvent sealed class"
```

---

## Task 4: Update flai_init Barrel Exports

**Files:**
- Modify: `bricks/flai_init/__brick__/lib/{{output_dir}}/flai.dart`

- [ ] **Step 1: Add new provider exports to barrel file**

Read the current file, then add these three lines after the existing `export 'providers/ai_provider.dart';`:

```dart
export 'providers/auth_provider.dart';
export 'providers/storage_provider.dart';
export 'providers/voice_provider.dart';
```

- [ ] **Step 2: Commit**

```bash
git add bricks/flai_init/__brick__/lib/\{\{output_dir\}\}/flai.dart
git commit -m "feat(flai_init): export new provider interfaces from barrel file"
```

---

## Task 5: Auth Flow Brick Setup

**Files:**
- Create: `bricks/auth_flow/brick.yaml`
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/auth_flow.dart`

- [ ] **Step 1: Create brick.yaml**

```yaml
# bricks/auth_flow/brick.yaml
name: auth_flow
description: Complete authentication flow with login, register, forgot password, verification, and reset screens. Uses AuthProvider interface for pluggable backend.
version: 0.1.0
environment:
  mason: ">=0.1.0 <1.0.0"
vars:
  output_dir:
    type: string
    description: Output directory for generated files
    default: flai
    prompt: "Where should FlAI files be generated?"
```

- [ ] **Step 2: Create barrel export file**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/auth_flow.dart
library;

export 'auth_controller.dart';
export 'auth_flow_config.dart';
export 'mock_auth_provider.dart';
export 'screens/login_landing.dart';
export 'screens/email_entry.dart';
export 'screens/password_entry.dart';
export 'screens/forgot_password.dart';
export 'screens/verification_code.dart';
export 'screens/reset_password.dart';
export 'widgets/social_auth_button.dart';
export 'widgets/auth_text_field.dart';
export 'widgets/typing_tagline.dart';
```

- [ ] **Step 3: Create directory structure**

Ensure these directories exist (Mason creates them from the file tree, but verify):
- `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/`
- `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/widgets/`

- [ ] **Step 4: Commit**

```bash
git add bricks/auth_flow/
git commit -m "feat(auth_flow): scaffold auth_flow brick with brick.yaml and barrel file"
```

---

## Task 6: AuthFlowConfig

**Files:**
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/auth_flow_config.dart`

- [ ] **Step 1: Create AuthFlowConfig**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/auth_flow_config.dart

import 'package:flutter/widgets.dart';

/// Types of social authentication supported.
enum SocialAuthType { apple, google, microsoft, phone }

/// Configuration for the auth flow screens.
///
/// Controls which auth methods are visible, branding, and legal links.
class AuthFlowConfig {
  const AuthFlowConfig({
    this.showAppleSignIn = true,
    this.showGoogleSignIn = true,
    this.showMicrosoftSignIn = false,
    this.showPhoneSignIn = false,
    this.showEmailSignIn = true,
    this.showSignUp = true,
    this.allowGuest = false,
    this.appLogo,
    this.taglines = const [
      "Let's brainstorm",
      "Let's collaborate",
      "Let's create",
    ],
    this.emailHeading = 'Log in or sign up',
    this.emailSubtitle,
    this.termsUrl,
    this.privacyUrl,
    this.onGuestContinue,
  });

  /// Show "Continue with Apple" button.
  final bool showAppleSignIn;

  /// Show "Continue with Google" button.
  final bool showGoogleSignIn;

  /// Show "Continue with Microsoft" button.
  final bool showMicrosoftSignIn;

  /// Show "Continue with phone" button.
  final bool showPhoneSignIn;

  /// Show email/password sign-in option.
  final bool showEmailSignIn;

  /// Show "Sign up" button. Set false for private/invite-only apps.
  final bool showSignUp;

  /// Show dismiss (X) button for guest/skip mode.
  final bool allowGuest;

  /// Custom logo widget displayed on all auth screens.
  final Widget? appLogo;

  /// Rotating taglines on the login landing screen.
  final List<String> taglines;

  /// Heading text on the email entry screen.
  final String emailHeading;

  /// Subtitle text on the email entry screen.
  final String? emailSubtitle;

  /// URL for Terms of Use link.
  final String? termsUrl;

  /// URL for Privacy Policy link.
  final String? privacyUrl;

  /// Called when guest mode dismiss button is tapped.
  final VoidCallback? onGuestContinue;

  /// Returns the list of enabled social auth types.
  List<SocialAuthType> get enabledSocialAuth {
    return [
      if (showAppleSignIn) SocialAuthType.apple,
      if (showGoogleSignIn) SocialAuthType.google,
      if (showMicrosoftSignIn) SocialAuthType.microsoft,
      if (showPhoneSignIn) SocialAuthType.phone,
    ];
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add bricks/auth_flow/__brick__/lib/\{\{output_dir\}\}/flows/auth/auth_flow_config.dart
git commit -m "feat(auth_flow): add AuthFlowConfig with button visibility and branding options"
```

---

## Task 7: MockAuthProvider

**Files:**
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/mock_auth_provider.dart`

- [ ] **Step 1: Create MockAuthProvider**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/mock_auth_provider.dart

import 'dart:async';

import '../../providers/auth_provider.dart';

/// Mock auth provider for development and testing.
///
/// Simulates authentication with a configurable delay.
/// All operations succeed by default. Set [shouldFail] to true
/// to simulate auth failures.
class MockAuthProvider implements AuthProvider {
  MockAuthProvider({
    this.delay = const Duration(milliseconds: 800),
    this.shouldFail = false,
  });

  final Duration delay;
  final bool shouldFail;

  AuthUser? _currentUser;
  final _authStateController = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _authStateController.stream;

  Future<AuthResult> _simulate(AuthUser user) async {
    await Future<void>.delayed(delay);
    if (shouldFail) {
      return const AuthFailure('Mock auth failure', code: 'mock_error');
    }
    _currentUser = user;
    _authStateController.add(user);
    return AuthSuccess(user);
  }

  AuthUser _mockUser(String email) => AuthUser(
        id: 'mock_${email.hashCode}',
        email: email,
        displayName: email.split('@').first,
      );

  @override
  Future<AuthResult> signInWithApple() =>
      _simulate(_mockUser('apple@example.com'));

  @override
  Future<AuthResult> signInWithGoogle() =>
      _simulate(_mockUser('google@example.com'));

  @override
  Future<AuthResult> signInWithMicrosoft() =>
      _simulate(_mockUser('microsoft@example.com'));

  @override
  Future<AuthResult> signInWithEmail(String email, String password) =>
      _simulate(_mockUser(email));

  @override
  Future<AuthResult> signUp(String email, String password) async {
    await Future<void>.delayed(delay);
    if (shouldFail) {
      return const AuthFailure('Mock signup failure', code: 'mock_error');
    }
    return AuthNeedsVerification(email);
  }

  @override
  Future<void> sendResetEmail(String email) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<AuthResult> confirmResetCode(String email, String code) async {
    await Future<void>.delayed(delay);
    if (shouldFail || code != '123456') {
      return const AuthFailure('Invalid code', code: 'invalid_code');
    }
    return AuthSuccess(_mockUser(email));
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<void> sendVerificationCode(String email) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<AuthResult> verifyCode(String email, String code) async {
    await Future<void>.delayed(delay);
    if (shouldFail || code != '123456') {
      return const AuthFailure('Invalid code', code: 'invalid_code');
    }
    return _simulate(_mockUser(email));
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(delay);
    _currentUser = null;
    _authStateController.add(null);
  }

  /// Dispose the stream controller.
  void dispose() {
    _authStateController.close();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add bricks/auth_flow/__brick__/lib/\{\{output_dir\}\}/flows/auth/mock_auth_provider.dart
git commit -m "feat(auth_flow): add MockAuthProvider for development and testing"
```

---

## Task 8: AuthController State Machine

**Files:**
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/auth_controller.dart`

- [ ] **Step 1: Create AuthController**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/auth_controller.dart

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../providers/auth_provider.dart';
import 'auth_flow_config.dart';

/// Auth flow screen identifiers.
enum AuthScreen {
  loginLanding,
  emailEntry,
  passwordEntry,
  forgotPassword,
  verificationCode,
  resetPassword,
}

/// Reason the verification code screen is shown.
enum VerificationReason { signUp, resetPassword }

/// Controller managing the auth flow state machine.
///
/// Handles screen navigation, loading states, error messages,
/// and delegates to [AuthProvider] for actual auth operations.
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthProvider provider,
    required AuthFlowConfig config,
    this.onAuthenticated,
    this.onGuestContinue,
  })  : _provider = provider,
        _config = config;

  final AuthProvider _provider;
  final AuthFlowConfig _config;

  /// Called when authentication succeeds.
  final void Function(AuthUser user)? onAuthenticated;

  /// Called when guest mode is selected.
  final VoidCallback? onGuestContinue;

  // State
  AuthScreen _currentScreen = AuthScreen.loginLanding;
  bool _isLoading = false;
  String? _errorMessage;
  String _email = '';
  VerificationReason _verificationReason = VerificationReason.signUp;
  bool _isSignUpMode = false;

  // Getters
  AuthScreen get currentScreen => _currentScreen;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get email => _email;
  AuthFlowConfig get config => _config;
  VerificationReason get verificationReason => _verificationReason;
  bool get isSignUpMode => _isSignUpMode;

  // Navigation

  /// Navigate to a screen in the auth flow.
  void goTo(AuthScreen screen) {
    _errorMessage = null;
    _currentScreen = screen;
    notifyListeners();
  }

  /// Navigate to email entry, setting sign-up mode.
  void goToEmailEntry({required bool isSignUp}) {
    _isSignUpMode = isSignUp;
    goTo(AuthScreen.emailEntry);
  }

  /// Go back to the previous logical screen.
  void goBack() {
    _errorMessage = null;
    switch (_currentScreen) {
      case AuthScreen.loginLanding:
        break; // Already at root
      case AuthScreen.emailEntry:
        _currentScreen = AuthScreen.loginLanding;
      case AuthScreen.passwordEntry:
        _currentScreen = AuthScreen.emailEntry;
      case AuthScreen.forgotPassword:
        _currentScreen = AuthScreen.passwordEntry;
      case AuthScreen.verificationCode:
        _currentScreen = _verificationReason == VerificationReason.resetPassword
            ? AuthScreen.forgotPassword
            : AuthScreen.emailEntry;
      case AuthScreen.resetPassword:
        _currentScreen = AuthScreen.verificationCode;
    }
    notifyListeners();
  }

  // Actions

  /// Submit email and proceed to password entry.
  void submitEmail(String email) {
    _email = email;
    _errorMessage = null;
    _currentScreen = AuthScreen.passwordEntry;
    notifyListeners();
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail(String password) async {
    await _runAsync(() async {
      final result = await _provider.signInWithEmail(_email, password);
      _handleResult(result);
    });
  }

  /// Sign up with email and password.
  Future<void> signUp(String password) async {
    await _runAsync(() async {
      final result = await _provider.signUp(_email, password);
      _handleResult(result);
    });
  }

  /// Sign in with a social provider.
  Future<void> signInWithSocial(SocialAuthType type) async {
    await _runAsync(() async {
      final result = switch (type) {
        SocialAuthType.apple => await _provider.signInWithApple(),
        SocialAuthType.google => await _provider.signInWithGoogle(),
        SocialAuthType.microsoft => await _provider.signInWithMicrosoft(),
        SocialAuthType.phone =>
          throw UnimplementedError('Phone auth not yet supported'),
      };
      _handleResult(result);
    });
  }

  /// Send password reset email.
  Future<void> sendResetEmail() async {
    await _runAsync(() async {
      await _provider.sendResetEmail(_email);
      _verificationReason = VerificationReason.resetPassword;
      _currentScreen = AuthScreen.verificationCode;
    });
  }

  /// Verify a code (for signup or password reset).
  Future<void> verifyCode(String code) async {
    await _runAsync(() async {
      final result = await _provider.verifyCode(_email, code);
      switch (result) {
        case AuthSuccess(:final user):
          if (_verificationReason == VerificationReason.resetPassword) {
            _currentScreen = AuthScreen.resetPassword;
          } else {
            onAuthenticated?.call(user);
          }
        case AuthFailure(:final message):
          _errorMessage = message;
        case AuthNeedsVerification():
          break; // Stay on verification screen
      }
    });
  }

  /// Resend verification code.
  Future<void> resendCode() async {
    await _runAsync(() async {
      await _provider.sendVerificationCode(_email);
    });
  }

  /// Reset password with new password.
  Future<void> resetPassword(String newPassword) async {
    await _runAsync(() async {
      await _provider.resetPassword(_email, newPassword);
      // Auto-login after reset
      final result = await _provider.signInWithEmail(_email, newPassword);
      _handleResult(result);
    });
  }

  // Private helpers

  void _handleResult(AuthResult result) {
    switch (result) {
      case AuthSuccess(:final user):
        onAuthenticated?.call(user);
      case AuthFailure(:final message):
        _errorMessage = message;
      case AuthNeedsVerification(:final email):
        _email = email;
        _verificationReason = VerificationReason.signUp;
        _currentScreen = AuthScreen.verificationCode;
    }
  }

  Future<void> _runAsync(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add bricks/auth_flow/__brick__/lib/\{\{output_dir\}\}/flows/auth/auth_controller.dart
git commit -m "feat(auth_flow): add AuthController state machine with screen navigation"
```

---

## Task 9: Shared Widgets

**Files:**
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/widgets/social_auth_button.dart`
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/widgets/auth_text_field.dart`
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/widgets/typing_tagline.dart`

- [ ] **Step 1: Create SocialAuthButton**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/widgets/social_auth_button.dart

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_flow_config.dart';

/// Styled button for social authentication (Apple, Google, Microsoft, Phone).
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.type,
    required this.onTap,
    this.isLoading = false,
  });

  final SocialAuthType type;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final (label, icon, isPrimary) = switch (type) {
      SocialAuthType.apple => ('Continue with Apple', Icons.apple, true),
      SocialAuthType.google => ('Continue with Google', Icons.g_mobiledata, false),
      SocialAuthType.microsoft => ('Continue with Microsoft', Icons.window, false),
      SocialAuthType.phone => ('Continue with phone', Icons.phone, false),
    };

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: isLoading ? null : onTap,
        style: TextButton.styleFrom(
          backgroundColor: isPrimary ? theme.colors.foreground : Colors.transparent,
          foregroundColor: isPrimary ? theme.colors.background : theme.colors.foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radius.full),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: theme.colors.border),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? theme.colors.background : theme.colors.foreground,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: theme.typography.base),
                ],
              ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create AuthTextField**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/widgets/auth_text_field.dart

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';

/// Themed text field for auth forms with label, error state, and suffix.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? theme.colors.destructive : theme.colors.border,
            ),
            borderRadius: BorderRadius.circular(theme.radius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Padding(
                  padding: EdgeInsets.only(
                    left: theme.spacing.md,
                    top: theme.spacing.sm,
                  ),
                  child: Text(
                    label!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              TextField(
                controller: controller,
                obscureText: obscureText,
                readOnly: readOnly,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                autofocus: autofocus,
                onSubmitted: onSubmitted,
                style: theme.typography.base.copyWith(
                  color: theme.colors.foreground,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: theme.typography.base.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.md,
                    vertical: label != null ? theme.spacing.xs : theme.spacing.sm,
                  ),
                  suffixIcon: suffix,
                  isDense: label != null,
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: theme.spacing.xs, left: theme.spacing.sm),
            child: Text(
              errorText!,
              style: theme.typography.sm.copyWith(
                color: theme.colors.destructive,
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 3: Create TypingTagline**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/widgets/typing_tagline.dart

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
```

- [ ] **Step 4: Commit**

```bash
git add bricks/auth_flow/__brick__/lib/\{\{output_dir\}\}/flows/auth/widgets/
git commit -m "feat(auth_flow): add shared widgets — SocialAuthButton, AuthTextField, TypingTagline"
```

---

## Task 10: Login Landing Screen

**Files:**
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/login_landing.dart`

- [ ] **Step 1: Create FlaiLoginLanding**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/login_landing.dart

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';
import '../auth_flow_config.dart';
import '../widgets/social_auth_button.dart';
import '../widgets/typing_tagline.dart';

/// Login landing screen with rotating taglines and auth buttons.
///
/// First screen in the auth flow. Displays animated taglines and
/// buttons for social auth, sign up, and log in.
class FlaiLoginLanding extends StatelessWidget {
  const FlaiLoginLanding({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = controller.config;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Dismiss button (guest mode)
            if (config.allowGuest)
              Positioned(
                top: theme.spacing.md,
                right: theme.spacing.md,
                child: IconButton(
                  onPressed: controller.onGuestContinue,
                  icon: Icon(
                    Icons.close,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),

            // Main content
            Column(
              children: [
                // Tagline area (takes up top ~60%)
                Expanded(
                  flex: 3,
                  child: Center(
                    child: TypingTagline(taglines: config.taglines),
                  ),
                ),

                // Auth buttons area (bottom ~40%)
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.spacing.lg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Social auth buttons
                        ...config.enabledSocialAuth.map(
                          (type) => Padding(
                            padding: EdgeInsets.only(bottom: theme.spacing.sm),
                            child: SocialAuthButton(
                              type: type,
                              onTap: () => controller.signInWithSocial(type),
                            ),
                          ),
                        ),

                        // Sign up button
                        if (config.showSignUp)
                          Padding(
                            padding: EdgeInsets.only(bottom: theme.spacing.sm),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: TextButton(
                                onPressed: () {
                                  controller.goToEmailEntry(isSignUp: true);
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: theme.colors.foreground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      theme.radius.full,
                                    ),
                                    side: BorderSide(
                                      color: theme.colors.border,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Sign up',
                                  style: theme.typography.base,
                                ),
                              ),
                            ),
                          ),

                        // Log in button
                        if (config.showEmailSignIn)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton(
                              onPressed: () {
                                controller.goToEmailEntry(isSignUp: false);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colors.foreground,
                              ),
                              child: Text(
                                'Log in',
                                style: theme.typography.base,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add bricks/auth_flow/__brick__/lib/\{\{output_dir\}\}/flows/auth/screens/login_landing.dart
git commit -m "feat(auth_flow): add LoginLanding screen with taglines and auth buttons"
```

---

## Task 11: Email Entry Screen

**Files:**
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/email_entry.dart`

- [ ] **Step 1: Create FlaiEmailEntry**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/email_entry.dart

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_button.dart';

/// Email entry screen for login or sign up.
class FlaiEmailEntry extends StatefulWidget {
  const FlaiEmailEntry({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<FlaiEmailEntry> createState() => _FlaiEmailEntryState();
}

class _FlaiEmailEntryState extends State<FlaiEmailEntry> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    widget.controller.submitEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = widget.controller.config;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
          child: Column(
            children: [
              // Header with close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: theme.spacing.md),
                  child: IconButton(
                    onPressed: () => widget.controller.goTo(
                      AuthScreen.loginLanding,
                    ),
                    icon: Icon(
                      Icons.close,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ),

              SizedBox(height: theme.spacing.lg),

              // Logo
              if (config.appLogo != null) ...[
                config.appLogo!,
                SizedBox(height: theme.spacing.md),
              ],

              // Heading
              Text(
                config.emailHeading,
                style: theme.typography.lg.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (config.emailSubtitle != null) ...[
                SizedBox(height: theme.spacing.xs),
                Text(
                  config.emailSubtitle!,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: theme.spacing.lg),

              // Email field
              AuthTextField(
                controller: _emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofocus: true,
                onSubmitted: (_) => _submit(),
              ),

              SizedBox(height: theme.spacing.md),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _submit,
                  style: TextButton.styleFrom(
                    backgroundColor: theme.colors.foreground,
                    foregroundColor: theme.colors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme.radius.full),
                    ),
                  ),
                  child: Text('Continue', style: theme.typography.base),
                ),
              ),

              // OR divider + social buttons
              if (config.enabledSocialAuth.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: theme.colors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: theme.spacing.md,
                        ),
                        child: Text(
                          'OR',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: theme.colors.border)),
                    ],
                  ),
                ),
                ...config.enabledSocialAuth.map(
                  (type) => Padding(
                    padding: EdgeInsets.only(bottom: theme.spacing.sm),
                    child: SocialAuthButton(
                      type: type,
                      onTap: () => widget.controller.signInWithSocial(type),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add bricks/auth_flow/__brick__/lib/\{\{output_dir\}\}/flows/auth/screens/email_entry.dart
git commit -m "feat(auth_flow): add EmailEntry screen with email field and social auth"
```

---

## Task 12: Password Entry Screen

**Files:**
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/password_entry.dart`

- [ ] **Step 1: Create FlaiPasswordEntry**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/password_entry.dart

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';

/// Password entry screen for both login and sign up flows.
///
/// In sign up mode, the heading reads "Create a password".
/// In login mode, the heading reads "Enter your password".
class FlaiPasswordEntry extends StatefulWidget {
  const FlaiPasswordEntry({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<FlaiPasswordEntry> createState() => _FlaiPasswordEntryState();
}

class _FlaiPasswordEntryState extends State<FlaiPasswordEntry> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    if (widget.controller.isSignUpMode) {
      widget.controller.signUp(password);
    } else {
      widget.controller.signInWithEmail(password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = widget.controller.config;
    final isSignUp = widget.controller.isSignUpMode;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: theme.colors.background,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
              child: Column(
                children: [
                  // Header: back + logo + close
                  Padding(
                    padding: EdgeInsets.only(top: theme.spacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: widget.controller.goBack,
                          icon: Icon(
                            Icons.arrow_back,
                            color: theme.colors.foreground,
                          ),
                        ),
                        if (config.appLogo != null)
                          config.appLogo!
                        else
                          const SizedBox(width: 24),
                        IconButton(
                          onPressed: () => widget.controller.goTo(
                            AuthScreen.loginLanding,
                          ),
                          icon: Icon(
                            Icons.close,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // Heading
                  Text(
                    isSignUp ? 'Create a password' : 'Enter your password',
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // Email (read-only)
                  AuthTextField(
                    controller: TextEditingController(
                      text: widget.controller.email,
                    ),
                    label: 'Email',
                    readOnly: true,
                  ),

                  SizedBox(height: theme.spacing.md),

                  // Password
                  AuthTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: _obscurePassword,
                    autofocus: true,
                    errorText: widget.controller.errorMessage,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: theme.colors.mutedForeground,
                        size: 20,
                      ),
                    ),
                  ),

                  SizedBox(height: theme.spacing.md),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: widget.controller.isLoading ? null : _submit,
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colors.foreground,
                        foregroundColor: theme.colors.background,
                        disabledBackgroundColor: theme.colors.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme.radius.full),
                        ),
                      ),
                      child: widget.controller.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colors.background,
                              ),
                            )
                          : Text('Continue', style: theme.typography.base),
                    ),
                  ),

                  // Forgot password (login mode only)
                  if (!isSignUp) ...[
                    SizedBox(height: theme.spacing.md),
                    TextButton(
                      onPressed: () => widget.controller.goTo(
                        AuthScreen.forgotPassword,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: theme.typography.base.copyWith(
                          color: theme.colors.foreground,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Terms + Privacy
                  if (config.termsUrl != null || config.privacyUrl != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: theme.spacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (config.termsUrl != null)
                            Text(
                              'Terms of Use',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          if (config.termsUrl != null &&
                              config.privacyUrl != null)
                            Text(
                              ' · ',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          if (config.privacyUrl != null)
                            Text(
                              'Privacy Policy',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                                decoration: TextDecoration.underline,
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
```

- [ ] **Step 2: Commit**

```bash
git add bricks/auth_flow/__brick__/lib/\{\{output_dir\}\}/flows/auth/screens/password_entry.dart
git commit -m "feat(auth_flow): add PasswordEntry screen for login and signup modes"
```

---

## Task 13: Forgot Password Screen

**Files:**
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/forgot_password.dart`

- [ ] **Step 1: Create FlaiForgotPassword**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/forgot_password.dart

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';

/// Forgot password confirmation screen.
///
/// Shows the user's email and a Continue button to send the reset email.
class FlaiForgotPassword extends StatelessWidget {
  const FlaiForgotPassword({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = controller.config;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: theme.colors.background,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
              child: Column(
                children: [
                  // Header: back + logo + close
                  Padding(
                    padding: EdgeInsets.only(top: theme.spacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: controller.goBack,
                          icon: Icon(
                            Icons.arrow_back,
                            color: theme.colors.foreground,
                          ),
                        ),
                        if (config.appLogo != null)
                          config.appLogo!
                        else
                          const SizedBox(width: 24),
                        IconButton(
                          onPressed: () => controller.goTo(
                            AuthScreen.loginLanding,
                          ),
                          icon: Icon(
                            Icons.close,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: theme.spacing.xl),

                  // Heading
                  Text(
                    'Reset password',
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: theme.spacing.sm),

                  // Subtitle with email
                  Text(
                    'Click "Continue" to reset your password for ${controller.email}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: controller.isLoading
                          ? null
                          : controller.sendResetEmail,
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colors.foreground,
                        foregroundColor: theme.colors.background,
                        disabledBackgroundColor: theme.colors.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme.radius.full),
                        ),
                      ),
                      child: controller.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colors.background,
                              ),
                            )
                          : Text('Continue', style: theme.typography.base),
                    ),
                  ),

                  if (controller.errorMessage != null) ...[
                    SizedBox(height: theme.spacing.md),
                    Text(
                      controller.errorMessage!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.destructive,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add bricks/auth_flow/__brick__/lib/\{\{output_dir\}\}/flows/auth/screens/forgot_password.dart
git commit -m "feat(auth_flow): add ForgotPassword screen"
```

---

## Task 14: Verification Code Screen

**Files:**
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/verification_code.dart`

- [ ] **Step 1: Create FlaiVerificationCode**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/verification_code.dart

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';

/// Verification code entry screen.
///
/// Shared for both sign-up verification and password reset flows.
/// Shows email, code input, resend option, and password fallback.
class FlaiVerificationCode extends StatefulWidget {
  const FlaiVerificationCode({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<FlaiVerificationCode> createState() => _FlaiVerificationCodeState();
}

class _FlaiVerificationCodeState extends State<FlaiVerificationCode> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    widget.controller.verifyCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = widget.controller.config;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: theme.colors.background,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(top: theme.spacing.md),
                      child: IconButton(
                        onPressed: () => widget.controller.goTo(
                          AuthScreen.loginLanding,
                        ),
                        icon: Icon(
                          Icons.close,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // Logo
                  if (config.appLogo != null) ...[
                    config.appLogo!,
                    SizedBox(height: theme.spacing.md),
                  ],

                  // Heading
                  Text(
                    'Check your inbox',
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: theme.spacing.sm),

                  Text(
                    'Enter the verification code we just sent to ${widget.controller.email}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // Code field
                  AuthTextField(
                    controller: _codeController,
                    hintText: 'Code',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    errorText: widget.controller.errorMessage,
                    onSubmitted: (_) => _submit(),
                  ),

                  SizedBox(height: theme.spacing.md),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: widget.controller.isLoading ? null : _submit,
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colors.foreground,
                        foregroundColor: theme.colors.background,
                        disabledBackgroundColor: theme.colors.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme.radius.full),
                        ),
                      ),
                      child: widget.controller.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colors.background,
                              ),
                            )
                          : Text('Continue', style: theme.typography.base),
                    ),
                  ),

                  SizedBox(height: theme.spacing.md),

                  // Resend
                  TextButton(
                    onPressed: widget.controller.isLoading
                        ? null
                        : widget.controller.resendCode,
                    child: Text(
                      'Resend email',
                      style: theme.typography.base.copyWith(
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),

                  // OR + password fallback
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: theme.colors.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: theme.spacing.md,
                          ),
                          child: Text(
                            'OR',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: theme.colors.border)),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => widget.controller.goTo(
                        AuthScreen.passwordEntry,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colors.foreground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme.radius.full),
                          side: BorderSide(color: theme.colors.border),
                        ),
                      ),
                      child: Text(
                        'Continue with password',
                        style: theme.typography.base,
                      ),
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
```

- [ ] **Step 2: Commit**

```bash
git add bricks/auth_flow/__brick__/lib/\{\{output_dir\}\}/flows/auth/screens/verification_code.dart
git commit -m "feat(auth_flow): add VerificationCode screen for signup and reset flows"
```

---

## Task 15: Reset Password Screen

**Files:**
- Create: `bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/reset_password.dart`

- [ ] **Step 1: Create FlaiResetPassword**

```dart
// bricks/auth_flow/__brick__/lib/{{output_dir}}/flows/auth/screens/reset_password.dart

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';

/// Reset password screen — set a new password after code verification.
class FlaiResetPassword extends StatefulWidget {
  const FlaiResetPassword({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<FlaiResetPassword> createState() => _FlaiResetPasswordState();
}

class _FlaiResetPasswordState extends State<FlaiResetPassword> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _localError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty) {
      setState(() => _localError = 'Password is required');
      return;
    }
    if (password != confirm) {
      setState(() => _localError = 'Passwords do not match');
      return;
    }
    setState(() => _localError = null);
    widget.controller.resetPassword(password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = widget.controller.config;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final error = _localError ?? widget.controller.errorMessage;

        return Scaffold(
          backgroundColor: theme.colors.background,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
              child: Column(
                children: [
                  // Header: back + logo + close
                  Padding(
                    padding: EdgeInsets.only(top: theme.spacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: widget.controller.goBack,
                          icon: Icon(
                            Icons.arrow_back,
                            color: theme.colors.foreground,
                          ),
                        ),
                        if (config.appLogo != null)
                          config.appLogo!
                        else
                          const SizedBox(width: 24),
                        IconButton(
                          onPressed: () => widget.controller.goTo(
                            AuthScreen.loginLanding,
                          ),
                          icon: Icon(
                            Icons.close,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  Text(
                    'Set new password',
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // New password
                  AuthTextField(
                    controller: _passwordController,
                    hintText: 'New password',
                    obscureText: _obscurePassword,
                    autofocus: true,
                    suffix: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: theme.colors.mutedForeground,
                        size: 20,
                      ),
                    ),
                  ),

                  SizedBox(height: theme.spacing.md),

                  // Confirm password
                  AuthTextField(
                    controller: _confirmController,
                    hintText: 'Confirm password',
                    obscureText: _obscureConfirm,
                    errorText: error,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: theme.colors.mutedForeground,
                        size: 20,
                      ),
                    ),
                  ),

                  SizedBox(height: theme.spacing.md),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed:
                          widget.controller.isLoading ? null : _submit,
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colors.foreground,
                        foregroundColor: theme.colors.background,
                        disabledBackgroundColor: theme.colors.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            theme.radius.full,
                          ),
                        ),
                      ),
                      child: widget.controller.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colors.background,
                              ),
                            )
                          : Text(
                              'Reset password',
                              style: theme.typography.base,
                            ),
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
```

- [ ] **Step 2: Commit**

```bash
git add bricks/auth_flow/__brick__/lib/\{\{output_dir\}\}/flows/auth/screens/reset_password.dart
git commit -m "feat(auth_flow): add ResetPassword screen with password confirmation"
```

---

## Task 16: Update Brick Registry

**Files:**
- Modify: `packages/flai_cli/lib/brick_registry.dart`

- [ ] **Step 1: Add auth_flow to the brick registry**

Add a new category constant and the auth_flow entry. Read the existing file first, then add after the providers category:

```dart
// Add new category
static const String flows = 'Flows';

// Add to the components map:
'auth_flow': BrickInfo(
  name: 'auth_flow',
  description: 'Complete authentication flow with login, register, forgot password, verification, and reset screens.',
  category: flows,
  dependencies: [],
  pubDependencies: [],
),
```

- [ ] **Step 2: Verify CLI still compiles**

Run: `cd packages/flai_cli && dart analyze`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add packages/flai_cli/lib/brick_registry.dart
git commit -m "feat(cli): register auth_flow brick in BrickRegistry"
```

---

## Task 17: Integration Verification

- [ ] **Step 1: Generate flai_init into a test project and verify new providers exist**

```bash
cd /tmp && flutter create flai_auth_test && cd flai_auth_test
mason make flai_init --output-dir lib --output_dir flai --on-conflict overwrite
```

Verify these files exist:
- `lib/flai/providers/auth_provider.dart`
- `lib/flai/providers/storage_provider.dart`
- `lib/flai/providers/voice_provider.dart`

- [ ] **Step 2: Generate auth_flow into the test project**

```bash
mason make auth_flow --output-dir lib --output_dir flai --on-conflict overwrite
```

Verify the `lib/flai/flows/auth/` directory has all expected files.

- [ ] **Step 3: Run dart analyze on the test project**

```bash
cd /tmp/flai_auth_test && flutter analyze
```

Expected: No errors. Fix any import path issues.

- [ ] **Step 4: Clean up test project**

```bash
rm -rf /tmp/flai_auth_test
```

- [ ] **Step 5: Commit any fixes from integration test**

```bash
git add -A && git commit -m "fix(auth_flow): resolve import paths from integration test"
```

(Skip this step if no fixes were needed.)

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | AuthProvider interface | 1 created |
| 2 | StorageProvider interface | 1 created |
| 3 | VoiceProvider interface | 1 created |
| 4 | Update barrel exports | 1 modified |
| 5 | Auth flow brick setup | 2 created |
| 6 | AuthFlowConfig | 1 created |
| 7 | MockAuthProvider | 1 created |
| 8 | AuthController state machine | 1 created |
| 9 | Shared widgets (3) | 3 created |
| 10 | Login Landing screen | 1 created |
| 11 | Email Entry screen | 1 created |
| 12 | Password Entry screen | 1 created |
| 13 | Forgot Password screen | 1 created |
| 14 | Verification Code screen | 1 created |
| 15 | Reset Password screen | 1 created |
| 16 | Update brick registry | 1 modified |
| 17 | Integration verification | 0 (test only) |

**Total: 17 tasks, 18 files created, 2 files modified**
