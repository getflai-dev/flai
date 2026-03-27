---
name: flai
description: Install and use FlAI AI chat components in Flutter projects. Guides installation, theming, provider setup, and customization of the full app scaffold.
---

# FlAI -- AI Chat Components for Flutter

FlAI is a shadcn/ui-style component library for Flutter that gives you a production-ready AI chat app as source code you own. Components are distributed via a Mason-powered CLI -- you install exactly what you need, and the code lives in your project, not behind a package abstraction.

Docs: https://getflai.dev

## When to Use This Skill

- User wants to add AI chat UI to a Flutter app
- User asks about FlAI components (message bubbles, input bars, streaming text, etc.)
- User needs help with FlAI theming (colors, typography, spacing, radius, icons)
- User wants to connect to a backend (CMMD, OpenAI, Anthropic)
- User asks about building a chat screen, conversation list, or model selector
- User wants to understand what `flai init`, `flai add`, or `flai connect` does

## Installation

### Prerequisites

- Flutter 3.22+ with Dart 3.4+
- An existing Flutter project

### Install the CLI

```bash
dart pub global activate flai_cli
```

### Quick 3-Command Setup

This is the fastest path to a fully working AI chat app:

```bash
flai init                          # Interactive: app name, assistant name, theme
flai add app_scaffold              # Installs 83+ files + auto-generates main.dart
flutter pub get && flutter run     # Run the app
```

That is it. You have a complete AI chat app with mock providers. No code to write.

### What `flai init` Does

Runs an interactive setup that asks for:

1. **App name** -- your application's display name (default: "FlAI Chat")
2. **Assistant name** -- the AI assistant's display name (default: "Assistant")
3. **Theme preset** -- one of 4 presets: `dark`, `light`, `ios`, `premium` (default: "dark")

It then generates:

- `flai.yaml` -- stores branding values (app name, assistant name, theme) that flow into all generated code
- `lib/flai/core/theme/` -- FlaiTheme, FlaiColors, FlaiTypography, FlaiRadius, FlaiSpacing, FlaiIconData
- `lib/flai/core/models/` -- Message, Conversation, ChatEvent (sealed class), ChatRequest
- `lib/flai/providers/ai_provider.dart` -- Abstract AiProvider interface
- `lib/flai/flai.dart` -- Barrel export file
- Platform permissions for iOS (camera, photo library, microphone, speech recognition) and Android

For CI or scripted use, skip prompts with `--no-interactive` and pass values as flags:

```bash
flai init --no-interactive --app-name "My App" --assistant-name "Aria" --theme ios
```

### What `flai add app_scaffold` Does

Installs the full app shell along with all its dependencies. The CLI resolves the dependency graph automatically:

```
app_scaffold
  auth_flow          -- 6-screen auth flow
  onboarding_flow    -- splash, naming, multi-select, reveal animation
  chat_experience    -- composer, voice, model selector, attachments
  sidebar_nav        -- drawer, conversation list, settings
  message_bubble     -- markdown message rendering
  typing_indicator   -- animated loading dots
```

It also:

- Adds pub dependencies to `pubspec.yaml` (go_router, flutter_secure_storage, share_plus, flutter_markdown, markdown, image_picker, file_picker)
- Configures platform permissions (camera, photo library, microphone)
- **Auto-generates `lib/main.dart`** using values from `flai.yaml` -- the developer does not need to write any wiring code

The generated `main.dart` creates a `FlaiApp` with `MockAuthProvider` (auto-login) so the app runs immediately without any backend.

### What You Get Out of the Box

The `app_scaffold` provides a complete ChatGPT/Claude-style chat app with:

- **Auth flow** -- 6 screens: login landing, email entry, password, forgot password, verification code, reset password. Branded OAuth buttons (Apple, Google).
- **Onboarding flow** -- splash screen, name entry, interest pills, custom steps, reveal animation
- **Chat with rich content** -- markdown rendering, code blocks with copy, thinking/reasoning blocks, tool call cards, citation cards, image previews
- **Sidebar** -- conversation list with temporal grouping (Today, Yesterday, Previous 7 Days), search, rename, delete, star
- **Share conversation** -- share chat content via the system share sheet
- **Animated send button** -- morphs between send, stop (cancel streaming), and microphone states
- **Attachment menu** -- camera, photo library, file picker
- **Voice input** -- hold-to-record or tap-to-toggle voice modes via VoiceController
- **Model selector** -- bottom sheet picker for switching AI models
- **Session persistence** -- secure token storage with automatic session restore on app launch
- **Scroll-to-bottom FAB** -- floating action button appears when scrolled up in a long conversation
- **Regenerate response** -- retry button on the last assistant message to re-run a failed or unsatisfying response
- **Empty state** -- branded landing screen with assistant name when no conversation is active
- **GoRouter navigation** -- declarative routing with auth redirects and deep link support

## Connect a Backend

The default `main.dart` uses `MockAuthProvider` (no real authentication) and no AI provider (responses are simulated). To connect to a real backend:

### CMMD Backend

```bash
flai connect cmmd                  # Rewrites main.dart with CMMD production providers
flutter pub get && flutter run
```

This is a hidden command that:

- Generates CMMD provider implementations (`CmmdAiProvider`, `CmmdAuthProvider`, `CmmdStorageProvider`, `CmmdVoiceProvider`)
- Adds dependencies: `http`, `sign_in_with_apple`, `google_sign_in`, `url_launcher`, `speech_to_text`
- Rewrites `main.dart` to wire all 4 CMMD providers using values from `flai.yaml`

After connecting, the app is wired to cmmd.ai with real authentication (email, Apple, Google), AI chat streaming, conversation persistence, and voice (on-device STT + CMMD TTS).

### Direct API Providers

For connecting directly to OpenAI or Anthropic without a backend server:

```bash
flai add openai_provider           # or: flai add anthropic_provider
```

Then manually update `main.dart` to use the provider (see the Provider Setup section below).

## Available Components

### Flows (Multi-Screen Features)

| Component | Command | Description |
|---|---|---|
| `app_scaffold` | `flai add app_scaffold` | Production-ready app shell with GoRouter. Depends on: auth_flow, onboarding_flow, chat_experience, sidebar_nav, message_bubble, typing_indicator. Adds: go_router, flutter_secure_storage, share_plus |
| `auth_flow` | `flai add auth_flow` | 6-screen auth flow: login landing, email entry, password, forgot password, verification code, reset password. AuthController state machine + AuthFlowConfig |
| `onboarding_flow` | `flai add onboarding_flow` | Splash, naming, multi-select pills, custom steps, reveal animation. OnboardingController state machine |
| `chat_experience` | `flai add chat_experience` | Composer v2, voice recorder, model selector sheet, ghost mode banner, attachment menu, empty state. Adds: image_picker, file_picker |
| `sidebar_nav` | `flai add sidebar_nav` | Sidebar drawer, conversation list with temporal grouping, search, settings drawer (6 sub-pages), workspace switcher |

### Chat Essentials

| Component | Command | Description |
|---|---|---|
| `chat_screen` | `flai add chat_screen` | Full chat screen with header, message list, and input bar. Depends on: message_bubble, input_bar, streaming_text, typing_indicator |
| `message_bubble` | `flai add message_bubble` | Message bubble with user/assistant styling, markdown, thinking blocks, tool call chips, citations, streaming cursor, error retry. Adds: flutter_markdown, markdown |
| `input_bar` | `flai add input_bar` | Text input with send button, attachment support, Enter-to-send on desktop, multi-line growth |
| `streaming_text` | `flai add streaming_text` | Token-by-token text rendering with blinking cursor. Two modes: stream-driven or text-driven |
| `typing_indicator` | `flai add typing_indicator` | Animated three-dot bouncing indicator styled as an assistant bubble |

### AI Widgets

| Component | Command | Description |
|---|---|---|
| `tool_call_card` | `flai add tool_call_card` | Function/tool call display card with status and arguments |
| `code_block` | `flai add code_block` | Syntax-highlighted code display with copy-to-clipboard. Adds: flutter_highlight |
| `thinking_indicator` | `flai add thinking_indicator` | AI reasoning/thinking panel (collapsible) |
| `citation_card` | `flai add citation_card` | Source attribution card with title, URL, and snippet |
| `image_preview` | `flai add image_preview` | Image thumbnail with tap-to-zoom |

### Conversation Management

| Component | Command | Description |
|---|---|---|
| `conversation_list` | `flai add conversation_list` | Conversation history list with search and selection |
| `model_selector` | `flai add model_selector` | AI model picker dropdown |
| `token_usage` | `flai add token_usage` | Token count display (input/output/cache) |

### AI Providers

| Provider | Command | Description |
|---|---|---|
| `openai_provider` | `flai add openai_provider` | OpenAI Chat Completions API with streaming, tool use, and vision. Uses raw HTTP (package:http) |
| `anthropic_provider` | `flai add anthropic_provider` | Anthropic Messages API with streaming, tool use, extended thinking, and vision. Uses raw HTTP (package:http) |

## CLI Commands Reference

| Command | Description |
|---|---|
| `flai init` | Initialize FlAI in a Flutter project (interactive setup, creates flai.yaml + core files) |
| `flai add <component>` | Install a component and all its dependencies. Supports `--dry-run` |
| `flai list` | List all available components grouped by category, with install status |
| `flai doctor` | Check project health: validates flai.yaml, core files, installed components, pub dependencies |
| `flai connect cmmd` | (Hidden) Connect to CMMD backend -- rewrites main.dart with production providers |

## Quick Start -- Full App (Recommended)

The fastest path to a working AI chat app. No code to write -- everything is generated.

### 1. Create a Flutter project and initialize FlAI

```bash
flutter create my_chat_app && cd my_chat_app
dart pub global activate flai_cli
flai init
```

Follow the interactive prompts to set your app name, assistant name, and theme.

### 2. Install the app scaffold

```bash
flai add app_scaffold
```

This installs 83+ files including auth, onboarding, chat, and sidebar flows. It also generates `lib/main.dart` automatically.

### 3. Run the app

```bash
flutter pub get && flutter run
```

The app launches with `MockAuthProvider` (auto-login, no real backend needed). To connect a real backend, see the "Connect a Backend" section.

### Generated main.dart

You do not need to write `main.dart`. The CLI generates it from your `flai.yaml` values:

```dart
import 'package:flutter/material.dart';

import 'flai/app_scaffold.dart';
import 'flai/core/theme/flai_theme.dart';
import 'flai/flows/auth/mock_auth_provider.dart';
import 'flai/flows/chat/chat_experience_config.dart';
import 'flai/flows/sidebar/settings_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FlaiApp(
      config: AppScaffoldConfig(
        appTitle: 'My Chat App',          // from flai.yaml app_name
        authProvider: MockAuthProvider(),
        theme: FlaiThemeData.dark(),       // from flai.yaml theme
        chatExperienceConfig: ChatExperienceConfig(
          assistantName: 'Assistant',      // from flai.yaml assistant_name
        ),
        settingsConfig: SettingsConfig(
          sections: [
            SettingsSection(
              title: 'Account',
              rows: [
                NavigationRow(
                  icon: Icons.logout,
                  label: 'Sign Out',
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
```

To customize, edit `main.dart` directly. The developer owns all generated code.

## Quick Start -- Single Chat Screen

For a minimal chat screen without the full app scaffold (no auth, no sidebar, no routing):

### 1. Install components

```bash
flai init
flai add chat_screen openai_provider
```

### 2. Wire the chat screen

```dart
import 'package:flutter/material.dart';
import 'flai/flai.dart';
import 'flai/components/chat_screen/chat_screen.dart';
import 'flai/components/chat_screen/chat_screen_controller.dart';
import 'flai/providers/openai_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlaiTheme(
      data: FlaiThemeData.dark(),
      child: MaterialApp(
        title: 'AI Chat',
        theme: ThemeData.dark(),
        home: const ChatPage(),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatScreenController(
      provider: OpenAiProvider(
        apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
        model: 'gpt-4o',
      ),
      systemPrompt: 'You are a helpful assistant.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlaiChatScreen(
        controller: _controller,
        title: 'AI Assistant',
        subtitle: 'GPT-4o',
      ),
    );
  }
}
```

### 3. Run with your API key

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
```

## Architecture

### Provider Interfaces

FlAI defines 4 pluggable abstract interfaces. The developer implements these against their backend:

| Interface | Purpose | Default |
|---|---|---|
| `AiProvider` | Chat streaming, tool use, vision | None (install a provider brick) |
| `AuthProvider` | Login, register, reset, verify, session | `MockAuthProvider` (auto-login) |
| `StorageProvider` | Save, load, delete, star conversations | `InMemoryStorageProvider` |
| `VoiceProvider` | Transcribe, synthesize, conversation mode | None |

`AppScaffoldConfig` accepts all 4 providers. Only `authProvider` is required -- the others are optional and the scaffold gracefully degrades when they are absent.

### App Scaffold Wiring

The `app_scaffold` ships fully wired. The key classes:

- **`FlaiApp`** -- root widget, accepts `AppScaffoldConfig` with providers + flow configs
- **`FlaiProviders`** -- InheritedWidget that distributes providers down the tree
- **`HomeController`** -- bridges providers to the home screen (conversations, messages, streaming)
- **`FlaiHomeScreen`** -- sidebar drawer + top nav + chat area (empty state or active chat)
- **`FlaiChatContent`** -- message list + composer, uses `MessageBubble` + `FlaiTypingIndicator`

The scaffold transitions from empty state to active chat automatically when the user sends a message.

### State Management

Vanilla Flutter only -- no external packages:

- `ChangeNotifier` for controllers (HomeController, AuthController, OnboardingController)
- `Stream<ChatEvent>` for AI streaming
- `InheritedWidget` for provider distribution

### Streaming

`ChatEvent` is a sealed Dart class with subtypes for type-safe pattern matching:

- `TextDelta(text)` -- Incremental text chunk
- `TextDone(fullText)` -- Text complete with full content
- `ThinkingStart()` -- AI began reasoning
- `ThinkingDelta(text)` -- Thinking text chunk
- `ThinkingEnd()` -- Reasoning complete
- `ToolCallStart(id, name)` -- Tool call initiated
- `ToolCallDelta(id, argumentsDelta)` -- Tool call argument chunk
- `ToolCallEnd(id)` -- Tool call complete
- `CitationsReceived(citations)` -- Source citations
- `UsageUpdate(inputTokens, outputTokens, ...)` -- Token usage report
- `ChatDone()` -- Stream finished
- `ChatError(error, stackTrace?)` -- Error occurred

Providers parse SSE byte streams from raw HTTP responses. HTTP send has 30s timeout; SSE stream has 60s per-event timeout.

### flai.yaml

The config file stores project-level settings that flow into generated code:

```yaml
output_dir: lib/flai
theme: dark
app_name: My Chat App
assistant_name: Aria
installed:
  - flai_init
  - app_scaffold
  - auth_flow
  - onboarding_flow
  - chat_experience
  - sidebar_nav
  - message_bubble
  - typing_indicator
```

`flai add` updates the `installed` list automatically. `flai connect cmmd` reads `app_name`, `assistant_name`, and `theme` when rewriting `main.dart`.

## Theming

FlAI uses an InheritedWidget-based theme system with semantic color tokens modeled after shadcn/ui.

### FlaiThemeData

`FlaiThemeData` composes five sub-systems:

| Field | Type | Description |
|---|---|---|
| `colors` | `FlaiColors` | Semantic color tokens (background, foreground, primary, muted, userBubble, etc.) |
| `icons` | `FlaiIconData` | Semantic icon set (20 icon fields). Defaults to `FlaiIconData.material()` |
| `typography` | `FlaiTypography` | Font families and size scale |
| `radius` | `FlaiRadius` | Border radius tokens |
| `spacing` | `FlaiSpacing` | Spacing tokens |

### Built-in Presets

| Preset | Factory | Icons | Description |
|---|---|---|---|
| Zinc Light | `FlaiThemeData.light()` | `FlaiIconData.material()` | Clean light theme with zinc neutrals |
| Zinc Dark | `FlaiThemeData.dark()` | `FlaiIconData.material()` | Dark theme with zinc neutrals |
| iOS | `FlaiThemeData.ios()` | `FlaiIconData.cupertino()` | Apple Messages-inspired blue bubbles, iOS system colors, larger radii, Cupertino icons |
| Premium | `FlaiThemeData.premium()` | `FlaiIconData.sharp()` | Linear-inspired dark theme with indigo accents, sharp Material icons |

### FlaiIconData

Semantic icon set with 20 fields. Components access icons via `FlaiTheme.of(context).icons` instead of hardcoding `Icons.*` or `CupertinoIcons.*`.

**Presets:**

- `FlaiIconData.material()` -- Material Design rounded icons (default for light/dark)
- `FlaiIconData.cupertino()` -- Apple SF Symbols style (used by ios() preset)
- `FlaiIconData.sharp()` -- Material Design sharp icons (used by premium() preset)

**Icon fields:** toolCall, thinking, citation, image, brokenImage, code, copy, check, close, send, attach, search, delete, add, expand, collapse, chat, model, refresh, error

```dart
// Override specific icons on a preset
final customTheme = FlaiThemeData.dark().copyWith(
  icons: FlaiIconData.material().copyWith(
    send: Icons.arrow_upward_rounded,
    chat: Icons.forum_rounded,
  ),
);
```

### Applying a Theme

Wrap your app (or a subtree) with `FlaiTheme`:

```dart
FlaiTheme(
  data: FlaiThemeData.dark(),
  child: MaterialApp(
    home: ChatPage(),
  ),
)
```

All FlAI widgets read their styling via `FlaiTheme.of(context)`.

When using the `app_scaffold`, the theme is passed via `AppScaffoldConfig.theme` and the scaffold wraps the widget tree with `FlaiTheme` automatically.

### Custom Theme

Create a fully custom theme by constructing `FlaiThemeData` directly:

```dart
final myTheme = FlaiThemeData(
  colors: FlaiColors(
    background: Color(0xFF0F172A),
    foreground: Color(0xFFF8FAFC),
    card: Color(0xFF1E293B),
    cardForeground: Color(0xFFF8FAFC),
    popover: Color(0xFF1E293B),
    popoverForeground: Color(0xFFF8FAFC),
    primary: Color(0xFF3B82F6),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF334155),
    secondaryForeground: Color(0xFFF8FAFC),
    muted: Color(0xFF334155),
    mutedForeground: Color(0xFF94A3B8),
    accent: Color(0xFF3B82F6),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFF334155),
    input: Color(0xFF334155),
    ring: Color(0xFF3B82F6),
    userBubble: Color(0xFF3B82F6),
    userBubbleForeground: Color(0xFFFFFFFF),
    assistantBubble: Color(0xFF1E293B),
    assistantBubbleForeground: Color(0xFFF8FAFC),
  ),
  icons: FlaiIconData.material(),  // or .cupertino(), .sharp(), or custom
  typography: FlaiTypography(
    fontFamily: 'Inter',
    monoFontFamily: 'Fira Code',
    base: 15.0,
  ),
  radius: FlaiRadius(sm: 6, md: 10, lg: 16, xl: 20, full: 9999),
  spacing: FlaiSpacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48),
);
```

### Modifying a Preset

Use `copyWith` to tweak an existing preset:

```dart
final customDark = FlaiThemeData.dark().copyWith(
  colors: FlaiColors.dark().copyWith(
    primary: Color(0xFF10B981),        // emerald accent
    userBubble: Color(0xFF10B981),
    userBubbleForeground: Color(0xFFFFFFFF),
  ),
  icons: FlaiIconData.cupertino(),     // swap to Cupertino icons
  typography: FlaiTypography(fontFamily: 'Inter', monoFontFamily: 'Fira Code'),
);
```

### Theme Token Reference

**Colors:** background, foreground, card, cardForeground, popover, popoverForeground, primary, primaryForeground, secondary, secondaryForeground, muted, mutedForeground, accent, accentForeground, destructive, destructiveForeground, border, input, ring, userBubble, userBubbleForeground, assistantBubble, assistantBubbleForeground

**Icons:** toolCall, thinking, citation, image, brokenImage, code, copy, check, close, send, attach, search, delete, add, expand, collapse, chat, model, refresh, error

**Typography:** fontFamily, monoFontFamily, sm (12), base (14), lg (16), xl (20), xxl (24). Methods: `bodySmall()`, `bodyBase()`, `bodyLarge()`, `heading()`, `headingLarge()`, `mono()`

**Radius:** sm (4), md (8), lg (12), xl (16), full (9999)

**Spacing:** xs (4), sm (8), md (16), lg (24), xl (32), xxl (48)

## Provider Setup

### OpenAI Provider

```dart
import 'flai/providers/openai_provider.dart';

final provider = OpenAiProvider(
  apiKey: 'sk-your-key',
  model: 'gpt-4o',            // default: 'gpt-4o'
  // baseUrl: 'https://your-proxy.com/v1',  // optional
  // organization: 'org-xxx',                // optional
);

// Capabilities:
// provider.supportsToolUse    == true
// provider.supportsVision     == true
// provider.supportsStreaming   == true
// provider.supportsThinking   == false
```

### Anthropic Provider

```dart
import 'flai/providers/anthropic_provider.dart';

final provider = AnthropicProvider(
  apiKey: 'sk-ant-your-key',
  model: 'claude-sonnet-4-20250514',   // default
  // thinkingBudgetTokens: 8192,          // enable extended thinking
  // baseUrl: 'https://your-proxy.com',   // optional
);

// Capabilities:
// provider.supportsToolUse    == true
// provider.supportsVision     == true
// provider.supportsStreaming   == true
// provider.supportsThinking   == true
```

### Using a Provider with ChatScreenController

```dart
final controller = ChatScreenController(
  provider: provider,
  systemPrompt: 'You are a helpful AI assistant.',
  // initialMessages: [...],  // optional conversation history
);

// Send a message (streams the response automatically):
await controller.sendMessage('Hello!');

// Cancel streaming:
await controller.cancel();

// Retry last failed message:
await controller.retry();

// Clear conversation:
controller.clearMessages();

// Listen to state changes:
controller.addListener(() {
  print('Streaming: ${controller.isStreaming}');
  print('Current text: ${controller.streamingText}');
  print('Messages: ${controller.messages.length}');
});
```

### Tool Use

Define tools and send them with requests:

```dart
final tools = [
  ToolDefinition(
    name: 'get_weather',
    description: 'Get the current weather for a location',
    parameters: {
      'type': 'object',
      'properties': {
        'location': {
          'type': 'string',
          'description': 'City name',
        },
      },
      'required': ['location'],
    },
  ),
];

final request = ChatRequest(
  messages: messages,
  tools: tools,
);

// Stream and handle tool call events:
await for (final event in provider.streamChat(request)) {
  switch (event) {
    case TextDelta(:final text):
      // Append text to UI
      break;
    case ToolCallStart(:final id, :final name):
      // Show tool call card
      break;
    case ToolCallDelta(:final id, :final argumentsDelta):
      // Update tool call arguments
      break;
    case ToolCallEnd(:final id):
      // Execute tool and send result back
      break;
    case ChatDone():
      // Stream complete
      break;
    case ChatError(:final error):
      // Handle error
      break;
    default:
      break;
  }
}
```

## Data Models

### Message

```dart
Message(
  id: 'unique-id',
  role: MessageRole.user,        // user, assistant, system, tool
  content: 'Hello!',
  timestamp: DateTime.now(),
  status: MessageStatus.complete, // streaming, complete, error
  attachments: [...],            // optional
  toolCalls: [...],              // optional
  thinkingContent: '...',        // optional (Anthropic thinking)
  citations: [...],              // optional
  usage: UsageInfo(...),         // optional
)
```

### ChatEvent (sealed class)

See the Streaming section above for the full list of event subtypes.

## Customization Patterns

### Swapping the Theme in AppScaffoldConfig

```dart
FlaiApp(
  config: AppScaffoldConfig(
    appTitle: 'My App',
    authProvider: MockAuthProvider(),
    theme: FlaiThemeData.ios(),    // change to any preset or custom theme
    chatExperienceConfig: ChatExperienceConfig(
      assistantName: 'Siri',
    ),
    settingsConfig: SettingsConfig(sections: []),
  ),
)
```

### Adding Model Options

```dart
chatExperienceConfig: ChatExperienceConfig(
  assistantName: 'Assistant',
  availableModels: [
    ModelOption(
      id: 'gpt-4o',
      name: 'GPT-4o',
      description: 'Fast and capable',
      icon: Icons.bolt_rounded,
    ),
    ModelOption(
      id: 'claude-sonnet-4-20250514',
      name: 'Claude Sonnet',
      description: 'Intelligent and fast',
      icon: Icons.auto_awesome,
    ),
  ],
),
```

### Multi-Model Switching (Without App Scaffold)

```dart
final providers = {
  'GPT-4o': OpenAiProvider(
    apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
    model: 'gpt-4o',
  ),
  'Claude': AnthropicProvider(
    apiKey: const String.fromEnvironment('ANTHROPIC_API_KEY'),
    model: 'claude-sonnet-4-20250514',
  ),
};

// Swap provider at runtime:
void switchModel(String name) {
  _controller.dispose();
  setState(() {
    _controller = ChatScreenController(
      provider: providers[name]!,
      systemPrompt: 'You are a helpful assistant.',
    );
  });
}
```

### Tool Calling with ChatScreenController

```dart
final controller = ChatScreenController(
  provider: OpenAiProvider(
    apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
    model: 'gpt-4o',
  ),
  systemPrompt: 'You can look up weather.',
  tools: [
    ToolDefinition(
      name: 'get_weather',
      description: 'Get weather for a city',
      parameters: {
        'type': 'object',
        'properties': {
          'city': {'type': 'string', 'description': 'City name'},
        },
        'required': ['city'],
      },
    ),
  ],
  onToolCall: (name, args) async {
    if (name == 'get_weather') {
      return '{"temp": 72, "condition": "sunny"}';
    }
    return '{"error": "unknown tool"}';
  },
);
```

### Custom Theme with Brand Colors

```dart
final brandTheme = FlaiThemeData.dark().copyWith(
  colors: FlaiColors.dark().copyWith(
    primary: Color(0xFF10B981),
    userBubble: Color(0xFF10B981),
    userBubbleForeground: Color(0xFFFFFFFF),
  ),
  icons: FlaiIconData.cupertino(),
  typography: FlaiTypography(fontFamily: 'Inter', monoFontFamily: 'Fira Code'),
);

// In main.dart with app_scaffold:
FlaiApp(
  config: AppScaffoldConfig(
    appTitle: 'My App',
    authProvider: MockAuthProvider(),
    theme: brandTheme,
    // ...
  ),
)
```

### Switch Between Light and Dark Theme

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    return FlaiTheme(
      data: _isDark ? FlaiThemeData.dark() : FlaiThemeData.light(),
      child: MaterialApp(
        theme: _isDark ? ThemeData.dark() : ThemeData.light(),
        home: ChatPage(
          onToggleTheme: () => setState(() => _isDark = !_isDark),
        ),
      ),
    );
  }
}
```

### Use StreamingText Standalone

```dart
FlaiStreamingText(
  text: controller.streamingText,
  isStreaming: controller.isStreaming,
  style: FlaiTheme.of(context).typography.bodyBase(
    color: FlaiTheme.of(context).colors.foreground,
  ),
)
```

Or directly from a stream:

```dart
FlaiStreamingText.fromStream(
  stream: provider.streamChat(request)
      .whereType<TextDelta>()
      .map((e) => e.text),
  onStreamDone: () => print('Done!'),
)
```

### Using Theme Icons in Custom Widgets

```dart
Widget build(BuildContext context) {
  final theme = FlaiTheme.of(context);

  return IconButton(
    icon: Icon(theme.icons.send, color: theme.colors.primary),
    onPressed: onSend,
  );
}
```

## Architecture Notes

- All widgets use `FlaiTheme.of(context)` to read styling -- no hardcoded colors or icons
- Components access icons via `theme.icons.send`, `theme.icons.copy`, etc.
- Components use the Widget + Controller + State pattern for complex state
- The `AiProvider` abstract class defines the interface; implementations use raw HTTP via `package:http`
- No external state management dependency -- vanilla Flutter (`ChangeNotifier`, `Stream`)
- Components are Mason bricks; the `{{output_dir}}` variable controls output location
- Zero external dependencies in core; provider bricks add `package:http`
- The developer owns all generated source code and can modify it freely
