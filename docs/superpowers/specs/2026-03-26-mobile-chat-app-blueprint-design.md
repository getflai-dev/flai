# Mobile AI Chat App Blueprint — Design Spec

**Date:** 2026-03-26
**Status:** Approved for implementation planning
**Scope:** Replace existing `app_scaffold` brick with a complete ChatGPT/Claude-inspired mobile AI chat experience

---

## 1. Architecture

### 1.1 Scaffold + Flow Bricks

The `app_scaffold` brick generates the app shell (routing, provider wiring, theme) and auto-installs 4 flow bricks as dependencies:

```
app_scaffold
├── auth_flow          — Login, register, forgot password, verification, reset
├── onboarding_flow    — Splash, assistant naming, multi-select pills, reveal animation
├── chat_experience    — Composer v2, empty state, ghost mode, voice, model selector
└── sidebar_nav        — Drawer, top bar, starred/recent chats, settings drawer
```

Each flow brick can also be installed individually via `flai add auth_flow`. Flow bricks pull in existing component bricks as needed (e.g., `chat_experience` installs `chat_screen`, `message_bubble`, `input_bar`, etc.).

### 1.2 Four Pluggable Provider Interfaces

All follow the same abstract interface pattern — developer implements against their backend.

| Interface | Purpose | Default |
|-----------|---------|---------|
| `AiProvider` | Chat streaming, tool use, vision | None (install provider brick) |
| `AuthProvider` | Login, register, reset, verify, session | `MockAuthProvider` (auto-logged-in) |
| `StorageProvider` | Save, load, delete, star conversations | `InMemoryStorageProvider` |
| `VoiceProvider` | Transcribe, synthesize, conversation mode | None (developer implements) |

---

## 2. Auth Flow

### 2.1 AuthProvider Interface

```dart
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

### 2.2 AuthFlowConfig

```dart
AuthFlowConfig(
  // Button visibility — controls which auth methods are shown
  showAppleSignIn: true,       // default true on iOS, false on Android
  showGoogleSignIn: true,      // default true
  showMicrosoftSignIn: false,  // default false
  showPhoneSignIn: false,      // default false
  showEmailSignIn: true,       // default true
  showSignUp: true,            // false = private/invite-only app
  allowGuest: false,           // show X dismiss for guest/skip mode

  // Branding
  appLogo: Widget?,            // custom logo for all auth screens
  taglines: ['Let\'s brainstorm', 'Let\'s collaborate', 'Let\'s create'],

  // Legal
  termsUrl: String?,
  privacyUrl: String?,
)
```

### 2.3 Screens

#### 2.3.1 Login Landing
- Full black screen with centered animated rotating tagline (developer-configurable list)
- Tagline types in letter-by-letter, pauses, fades, cycles to next
- Bottom section: social auth buttons + Sign up + Log in
- Only enabled buttons render (controlled by AuthFlowConfig)
- X dismiss button (top-right) if `allowGuest: true`
- Sign up → EmailEntry (register mode)
- Log in → EmailEntry (login mode)

#### 2.3.2 Email Entry
- App logo (developer-configurable widget) centered at top
- "Log in or sign up" heading (configurable text)
- Subtitle text (configurable)
- Email text field with validation
- Continue button — checks email, routes to PasswordEntry (existing user) or SignUp (new user)
- OR divider + social auth buttons below
- X close button (top-right)

#### 2.3.3 Password Entry
- Back arrow (left) + app logo (center) + X close (right)
- "Enter your password" heading
- Email field pre-filled (read-only)
- Password field with visibility toggle (eye icon)
- Continue button → calls `AuthProvider.signInWithEmail`
- "Forgot password?" link → ForgotPassword screen
- Terms of Use / Privacy Policy links at bottom

#### 2.3.4 Forgot Password
- Back arrow + app logo + X close
- "Reset password" heading
- Shows email from previous screen
- Continue button → calls `AuthProvider.sendResetEmail`
- On success → VerificationCode screen

#### 2.3.5 Verification Code
- X close button (top-right)
- App logo centered
- "Check your inbox" heading
- "Enter the verification code we just sent to {email}" subtitle
- Code input field (numeric, optional auto-advance)
- Continue button → calls `AuthProvider.verifyCode`
- "Resend email" link → calls `AuthProvider.sendVerificationCode`
- OR divider + "Continue with password" fallback
- Reused for both sign-up verification and password reset flows

#### 2.3.6 Reset Password
- Back arrow + app logo + X close
- "Set new password" heading
- New password + confirm password fields
- "Reset password" button → calls `AuthProvider.resetPassword`
- On success → auto-login and navigate to app

### 2.4 State Machine

```
LoginLanding
  ├── Social auth buttons → [success] → App / Onboarding
  ├── "Sign up" → EmailEntry (register mode)
  └── "Log in" → EmailEntry (login mode)

EmailEntry
  ├── Continue (existing user) → PasswordEntry
  └── Continue (new user) → SignUp (password creation) → VerificationCode → App / Onboarding
      (SignUp reuses PasswordEntry layout with "Create password" heading)

PasswordEntry
  ├── Continue → [success] → App
  ├── Continue → [error] → show error inline
  └── "Forgot password?" → ForgotPassword

ForgotPassword
  └── Continue → VerificationCode → ResetPassword → [success] → auto-login → App
```

---

## 3. Onboarding Flow

### 3.1 OnboardingConfig

```dart
OnboardingConfig(
  splashLogo: Widget,                    // app logo for splash screen
  steps: [                              // ordered, removable, reorderable
    OnboardingStep.naming(
      title: 'What should I call your assistant?',  // custom question
      subtitle: 'You can change this later',
      suggestions: ['Atlas', 'Nova', 'Sage', 'Aria', 'Kai'],
    ),
    OnboardingStep.multiSelect(
      title: 'What interests you?',                 // custom question
      subtitle: 'Select all that apply',
      options: [PillOption(label: 'Coding', icon: Icons.code), ...],
      minSelections: 0,
      maxSelections: null,
    ),
    OnboardingStep.custom(builder: myCustomPage),   // arbitrary widget as a step
    OnboardingStep.reveal(
      title: 'Meet {name}',           // {name} interpolated from naming step
      subtitle: 'Your AI assistant is ready',
    ),
  ],
  revealGradient: [Color(0xFF818CF8), Color(0xFF34D399)],
  onComplete: Function(OnboardingResult),
)
```

### 3.2 Screens

#### 3.2.1 Splash / App Loading
- Full black screen with centered app logo
- Logo has subtle pulse/breathing animation
- Shown during initial app load + auth state check
- Transitions to Login Landing (unauthenticated) or Onboarding/Chat (authenticated)
- Developer provides logo widget via `OnboardingConfig.splashLogo`

#### 3.2.2 Name Your Assistant
- Title + subtitle (developer-configurable text)
- Text input field with cursor
- Suggestion pills below input — tapping fills the text field
- Suggestion names are developer-configurable
- Skip option available (uses default name)
- Continue button → next step

#### 3.2.3 Multi-Select Pills
- Title + subtitle (developer-configurable text)
- Pill labels and icons are 100% developer-defined (scaffold ships with sample data)
- Toggle selection with spring animation + checkmark
- "AI chat feel" — pills float/stagger in on entry with animation
- Skip button allows bypassing
- Continue button → next step
- Result: `onComplete(List<String> selected)`

#### 3.2.4 Custom Steps
- `OnboardingStep.custom(builder: (context, onNext) => Widget)`
- Developer injects any widget as an onboarding step
- Receives `onNext` callback to advance to next step
- Use case: voice picker, avatar chooser, terms acceptance, etc.

#### 3.2.5 Reveal Animation
- Celebratory reveal of the named assistant
- Logo scale-up animation with gradient glow (colors configurable)
- Assistant name types in letter-by-letter
- Brief hold (~1.5s), then auto-transitions to empty chat state
- No button — purely animated transition
- Developer can customize: logo, gradient colors, hold duration

### 3.3 Flow Control
- Only shown on first launch after authentication
- Developer controls which steps appear and in what order via `steps` list
- Remove a step → it's skipped
- Reorder → follows that order
- `OnboardingStep.custom()` allows injecting arbitrary pages
- Reveal is conventionally last but not enforced
- `OnboardingController` manages step navigation and collects results

---

## 4. Chat Experience

### 4.1 Empty Chat State
- Top nav bar (see Section 5.1)
- Centered assistant avatar + greeting
- Avatar: fully customizable via `AvatarConfig` (icon, gradient, solid color, image, or arbitrary widget)
- Greeting uses assistant name from onboarding: "Hi, I'm {name}"
- Subtitle: "How can I help you today?" (configurable)
- All text is developer-configurable

### 4.2 AvatarConfig

```dart
AvatarConfig(
  icon: IconData?,              // icon inside the avatar
  gradient: List<Color>?,       // gradient background
  backgroundColor: Color?,      // solid color alternative
  size: double,                 // default 40
  borderRadius: double,         // default 20 (circle)
  image: ImageProvider?,        // image instead of icon
  child: Widget?,               // fully custom widget overrides everything
)
```

Renders everywhere: empty state, message bubbles, onboarding reveal, sidebar.

### 4.3 Message Composer v2

#### 4.3.1 Layout
- Rounded pill-shaped container
- Top area: multi-line text field (auto-grows)
- Bottom row left: + button, mode/model selector chip
- Bottom row right: mic button, send button
- Placeholder text uses assistant name: "Ask {name} anything..."

#### 4.3.2 + Button (Sectioned Menu)
Opens a popup/bottom sheet with categorized sections:

```dart
ComposerConfig(
  attachmentSections: [
    AttachmentSection.attach(
      items: [
        AttachItem.camera(onTap: callback),
        AttachItem.photos(onTap: callback),
        AttachItem.files(onTap: callback),
      ],
    ),
    AttachmentSection.custom(
      title: 'CONTEXT',
      items: [
        AttachItem(icon: icon, label: 'Brain Collections', onTap: callback),
        AttachItem(icon: icon, label: 'Projects', onTap: callback),
        AttachItem(icon: icon, label: 'People', onTap: callback),
      ],
    ),
    AttachmentSection.chips(
      title: 'SEARCH MODE',
      items: [
        ChipItem(label: 'Smart', icon: icon, isDefault: true),
        ChipItem(label: 'Internal', icon: icon),
        ChipItem(label: 'External', icon: icon),
      ],
    ),
  ],
)
```

- ATTACH section: horizontal grid of Camera, Photos, Files
- Custom sections: vertical list with icons and chevrons
- Chips section: horizontal selectable pills
- Developers define their own sections — scaffold ships with ATTACH only as default

#### 4.3.3 Mode / Model Selector
- Chip in composer bottom-left row
- Tapping opens a bottom sheet with available models/modes
- Per-conversation default model, with optional per-message override
- Developer configures available options:

```dart
availableModels: [
  ModelOption(id: 'gpt-4o', name: 'GPT-4o', description: 'Most capable', icon: icon),
  ModelOption(id: 'gpt-4o-mini', name: 'GPT-4o mini', description: 'Faster', icon: icon),
  ModelOption(id: 'claude-sonnet', name: 'Claude Sonnet', description: 'Balanced', icon: icon),
]
```

#### 4.3.4 Send / Mic Button
- Default state: mic button (when text field is empty)
- Text entered: mic transitions to send button (animated)
- Send button: calls `ChatScreenController.sendMessage()`
- Mic button: enters push-to-talk recording mode

### 4.4 Voice Modes

#### 4.4.1 VoiceProvider Interface

```dart
abstract class VoiceProvider {
  // Push-to-talk
  Future<String> transcribe(Uint8List audio);
  Future<AudioStream> synthesize(String text);

  // Conversation mode
  Future<void> startConversation();
  Future<void> stopConversation();
  Stream<VoiceEvent> get conversationEvents;

  // State
  bool get isListening;
  bool get isSpeaking;
}
```

#### 4.4.2 Push-to-Talk
- Tap mic button → recording state
- Waveform visualizer + timer replaces text area inline in composer
- Stop button (red circle) replaces mic button
- Send arrow remains visible
- Tap stop → transcribed text appears in composer → user hits send
- Uses `VoiceProvider.transcribe()`

#### 4.4.3 Conversation Mode
- Toggle via voice chat button in composer bottom-right
- Full-screen overlay with animated orb/circle
- Gradient glow animation while listening
- Continuous back-and-forth: user speaks → AI responds with voice → user speaks again
- "Tap to end conversation" instruction
- Uses `VoiceProvider.startConversation()` / `stopConversation()`

### 4.5 Ghost Mode (Temporary Chat)
- Toggle via ghost icon in **top nav bar** (not in composer)
- Active state: icon highlighted (accent color) + banner below top nav: "Temporary Chat — not saved"
- Subtle visual tint on chat area when active
- `StorageProvider` is bypassed — no save calls
- Closing the chat discards it completely
- `ChatScreenController.isTemporary` flag
- Configurable: `enableGhostMode: bool` in top nav config

### 4.6 Chat Experience Config

```dart
ChatExperienceConfig(
  assistantName: String,                    // from onboarding or developer-set
  assistantAvatar: AvatarConfig,            // fully customizable avatar
  greeting: String,                         // empty state greeting
  greetingSubtitle: String,                 // below greeting
  composerPlaceholder: String,              // "Ask {name} anything..."
  composerConfig: ComposerConfig,           // + menu sections
  availableModels: List<ModelOption>,       // model selector options
  enableVoice: bool,                        // show mic + conversation toggle
  enableGhostMode: bool,                    // show ghost toggle in top nav
  enablePerMessageModelSwitch: bool,        // allow model switch mid-conversation
)
```

---

## 5. Sidebar Nav

### 5.1 Top Nav Bar
- **Left-aligned**: hamburger menu icon + app name (together, left side)
- **Right side**: configurable actions (ghost toggle, new chat button, custom widgets)
- Ghost active state: icon highlighted with accent color
- Developer configures right-side actions via `topNavActions: List<Widget>`

### 5.2 Sidebar Drawer
- Slides in from left (standard Flutter Drawer)
- **Header**: app logo + app name + new chat button (right)
- **Search bar**: filters all conversations (configurable via `enableSearch: bool`)
- **Static nav items**: developer-configurable list of navigation items, each routes to a developer-defined page/empty template. Default: just "Chats" (active)
- **Starred section** (always shown, required): developer passes starred conversation data via `StorageProvider`
- **Recents section** (always shown, required): developer passes recent conversation data via `StorageProvider`
- **Sticky user profile** at bottom: avatar (initials or image), name, workspace label. No overflow menu. Tapping opens settings drawer.

### 5.3 Chat List Item Interactions
- **Tap** → opens conversation
- **Long press** → context menu: Star, Rename, Share, Delete
- **Swipe left** → quick actions: Star (yellow), Delete (red)
- All actions route through `StorageProvider`
- Callbacks: `onStar`, `onRename`, `onShare`, `onDelete`

### 5.4 Settings Drawer (Bottom Sheet)
- Opens when tapping user profile section at bottom of sidebar
- **Bottom drawer** sliding up from bottom of screen, taking 60-80% height (configurable)
- Sub-pages slide within the same drawer (back arrow navigation, no separate full-screen pages)

#### 5.4.1 Default Header
- User name + email at top
- Workspace switcher below (developer-configurable)

#### 5.4.2 Default Settings Rows

| Row | Type | Sub-page content |
|-----|------|-----------------|
| Profile | → sub-page | Full name, nickname, personal preferences text area, Update/Save buttons, Delete account |
| Billing | → sub-page | Plan label, developer-configurable content |
| Usage | → sub-page | Current session usage, weekly limits with progress bars, reset times |
| Connectors | → sub-page | List of connected services with icons, counts, connect/disconnect |
| Appearance | inline dropdown | Light / Dark / System — ties into FlaiTheme |
| Notifications | → sub-page | Toggle per notification type (developer-defined list) |
| Privacy | → sub-page | Privacy text (configurable) + toggles |
| Haptic feedback | inline toggle | On/off |
| Info button | popup | App version, legal links (Acceptable Use, Terms, Privacy Policy, Licenses), Help & Support |

All rows are removable. Developer can hide any default row and add custom rows/sub-pages.

#### 5.4.3 Settings Row Types

```dart
SettingsRow.navigation(label: 'Profile', icon: icon, page: ProfileSubPage()),
SettingsRow.dropdown(label: 'Appearance', icon: icon, value: 'Dark', options: [...]),
SettingsRow.toggle(label: 'Haptic feedback', icon: icon, value: true, onChanged: callback),
SettingsRow.info(label: 'Version', icon: icon, value: 'v1.0.0'),
SettingsRow.custom(builder: (context) => Widget),
```

#### 5.4.4 SettingsConfig

```dart
SettingsConfig(
  drawerHeightRatio: 0.7,               // 60-80% of screen
  showWorkspaceSwitcher: true,
  sections: [
    SettingsSection(title: null, rows: [profile, billing, usage]),
    SettingsSection(title: null, rows: [connectors]),
    SettingsSection(title: null, rows: [appearance, notifications, privacy]),
    SettingsSection(title: null, rows: [hapticFeedback]),
  ],
  infoItems: [                          // info button popup
    InfoItem(label: 'Acceptable Use Policy', url: '...'),
    InfoItem(label: 'Privacy Policy', url: '...'),
    InfoItem(label: 'Help & Support', url: '...'),
  ],
  appVersion: String?,
)
```

### 5.5 Sidebar Config

```dart
SidebarConfig(
  appName: String,
  appLogo: Widget?,                      // falls back to gradient icon
  navItems: [                            // static nav items, developer-defined
    NavItem(icon: Icons.chat, label: 'Chats', page: ChatsPage()),
    NavItem(icon: Icons.settings, label: 'Custom', page: CustomPage()),
  ],
  enableSearch: bool,                    // show search bar
  topNavActions: List<Widget>,           // right side of top nav
  settingsConfig: SettingsConfig,        // settings drawer configuration
)
```

---

## 6. StorageProvider Interface

```dart
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
```

---

## 7. Implementation Phases

### Phase 1: Provider Interfaces + Auth Flow
- Define `AuthProvider`, `StorageProvider`, `VoiceProvider` interfaces
- `MockAuthProvider` and `InMemoryStorageProvider` defaults
- `AuthController` state machine
- All 6 auth screens
- `auth_flow` brick

### Phase 2: Onboarding Flow
- `OnboardingController` with step pipeline
- Splash, naming, multi-select pills, reveal animation screens
- Custom step support
- `onboarding_flow` brick

### Phase 3: Chat Experience
- Composer v2 (sectioned + menu, mode/model selector, voice UI)
- Empty chat state with configurable greeting + avatar
- Ghost mode (temporary chat) with visual treatment
- Voice recording UI (push-to-talk inline, conversation mode overlay)
- `chat_experience` brick

### Phase 4: Sidebar Nav
- Top nav bar (left-aligned app name + hamburger, configurable right actions)
- Sidebar drawer (search, static nav items, starred, recents, sticky user profile)
- Chat list interactions (tap, long press context menu, swipe actions)
- Settings bottom drawer with sub-page navigation
- Default settings rows (Profile, Billing, Usage, Connectors, Appearance, Notifications, Privacy, Haptic, Info)
- `sidebar_nav` brick

### Phase 5: App Scaffold
- Shell brick that wires all 4 flow bricks together
- Routing: splash → auth → onboarding → chat
- Provider injection points for all 4 interfaces
- `app_scaffold` brick with auto-install of flow dependencies

---

## 8. File Structure (Generated)

```
lib/flai/
├── core/                          # From flai_init (existing)
│   ├── theme/
│   ├── models/
│   └── providers/
│       ├── ai_provider.dart       # Existing
│       ├── auth_provider.dart     # NEW
│       ├── storage_provider.dart  # NEW
│       └── voice_provider.dart    # NEW
├── components/                    # Existing component bricks
│   ├── chat_screen/
│   ├── message_bubble/
│   ├── input_bar/
│   └── ...
├── flows/                         # NEW — flow bricks generate here
│   ├── auth/
│   │   ├── auth_controller.dart
│   │   ├── auth_flow_config.dart
│   │   ├── screens/
│   │   │   ├── login_landing.dart
│   │   │   ├── email_entry.dart
│   │   │   ├── password_entry.dart
│   │   │   ├── forgot_password.dart
│   │   │   ├── verification_code.dart
│   │   │   └── reset_password.dart
│   │   └── widgets/
│   │       ├── social_auth_button.dart
│   │       └── auth_text_field.dart
│   ├── onboarding/
│   │   ├── onboarding_controller.dart
│   │   ├── onboarding_config.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── naming_screen.dart
│   │   │   ├── multi_select_screen.dart
│   │   │   └── reveal_screen.dart
│   │   └── widgets/
│   │       ├── pill_chip.dart
│   │       └── typing_text.dart
│   ├── chat/
│   │   ├── chat_experience_config.dart
│   │   ├── composer_v2.dart
│   │   ├── avatar_config.dart
│   │   ├── screens/
│   │   │   ├── empty_chat_state.dart
│   │   │   └── voice_conversation_overlay.dart
│   │   └── widgets/
│   │       ├── attachment_menu.dart
│   │       ├── model_selector_sheet.dart
│   │       ├── voice_recorder.dart
│   │       └── ghost_mode_banner.dart
│   └── sidebar/
│       ├── sidebar_config.dart
│       ├── settings_config.dart
│       ├── screens/
│       │   ├── sidebar_drawer.dart
│       │   ├── settings_drawer.dart
│       │   └── settings_sub_pages/
│       │       ├── profile_page.dart
│       │       ├── billing_page.dart
│       │       ├── usage_page.dart
│       │       ├── connectors_page.dart
│       │       ├── notifications_page.dart
│       │       └── privacy_page.dart
│       └── widgets/
│           ├── top_nav_bar.dart
│           ├── chat_list_item.dart
│           ├── settings_row.dart
│           └── workspace_switcher.dart
└── app_scaffold.dart              # NEW — main app shell with routing
```

---

## 9. Design References

Screenshots from ChatGPT and Claude iOS apps are stored in:
- `~/Downloads/samples/` — Auth flow, sidebar, settings, onboarding, splash
- `~/Downloads/sample2/` — Settings drawer sub-pages (profile, usage, connectors, notifications, privacy)

These serve as visual reference for implementation, not as pixel-perfect targets.
