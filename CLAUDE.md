# FlAI -- AI Chat Components for Flutter

## What is FlAI?

A shadcn/ui-style component library for Flutter focused on AI chat interfaces. Components are distributed as Mason brick templates via a Dart CLI. Developers own the source code -- it lives in their project, not behind a package abstraction.

## Project Structure

```
bricks/                          Mason brick templates (one per component)
  flai_init/                     Core foundation (theme, models, provider interfaces)
  auth_flow/                     Login, register, forgot password, verification, reset
  onboarding_flow/               Splash, naming, multi-select pills, reveal animation
  chat_experience/               Composer v2, voice, model selector, ghost mode, empty state
  sidebar_nav/                   Drawer, conversation list, search, settings sheet
  app_scaffold/                  Production-ready shell wiring all 4 flows with GoRouter
  cmmd_providers/                CMMD API backend implementation (hidden, via `flai connect cmmd`)
  message_bubble/                Message bubble with markdown, thinking, citations
  streaming_text/                Token-by-token text rendering with cursor
  typing_indicator/              Animated loading dots
  thinking_indicator/            AI reasoning panel
  tool_call_card/                Function call display
  code_block/                    Code display with copy
  citation_card/                 Source attribution
  image_preview/                 Image thumbnail with zoom
  chat_screen/                   Full chat screen layout
  input_bar/                     Text input bar component
  conversation_list/             Conversation history list
  model_selector/                AI model picker
  token_usage/                   Token count display
  openai_provider/               OpenAI API integration
  anthropic_provider/            Anthropic API integration
packages/
  flai_cli/                      Dart CLI tool (flai init, flai add, flai connect)
  flai_mcp/                      MCP server for AI assistants
  flai_skill/                    Claude Code skill
example/                         Dogfood app (flai init → flai add app_scaffold → flai connect cmmd)
docs-site/                       Documentation website
docs/                            Additional documentation
```

## Architecture

### Component Distribution
- Mason-powered CLI distributes component source code as bricks
- Each brick has a `brick.yaml` and template files under `__brick__/`
- Templates use `{{output_dir}}` variable for target path in consumer projects
- `flai init` generates the core foundation; `flai add <component>` adds individual components

### Brick Hierarchy

Two kinds of bricks:

1. **Component bricks** — single-widget (message_bubble, typing_indicator, streaming_text, etc.)
2. **Flow bricks** — multi-screen features (auth_flow, onboarding_flow, chat_experience, sidebar_nav, app_scaffold)

`app_scaffold` depends on all 4 flow bricks and provides the full app shell. Component bricks are installed separately for the chat content area. The minimal viable chat app requires:

```bash
flai init                          # Core foundation
flai add app_scaffold              # Full app shell (pulls auth, onboarding, chat, sidebar)
flai add message_bubble            # Chat message rendering
flai add streaming_text            # Streaming text with cursor
flai add typing_indicator          # Loading animation
flai connect cmmd                  # (optional) CMMD backend providers
```

### Theme System
- InheritedWidget-based `FlaiTheme` (not MaterialTheme extension)
- All widgets access styling via `FlaiTheme.of(context)`
- `FlaiThemeData` composes: `FlaiColors`, `FlaiTypography`, `FlaiRadius`, `FlaiSpacing`
- Semantic color tokens matching shadcn/ui naming (background, foreground, primary, muted, etc.)
- Chat-specific tokens: userBubble, userBubbleForeground, assistantBubble, assistantBubbleForeground
- 4 built-in presets: `light()`, `dark()`, `ios()`, `premium()`

### State Management
- Vanilla Flutter: ChangeNotifier + Streams, no external packages
- `HomeController` extends `ChangeNotifier` — bridges providers to the home screen (conversations, messages, streaming)
- `AuthController` extends `ChangeNotifier` — auth flow state machine
- `OnboardingController` extends `ChangeNotifier` — onboarding step state machine
- `AiProvider` abstract interface returns `Stream<ChatEvent>` for streaming

### App Scaffold Wiring
The `app_scaffold` brick ships fully wired. Developers only provide backend providers:

- **`FlaiApp`** — root widget, accepts `AppScaffoldConfig` with providers + flow configs
- **`_WiredHomePage`** — stateful wrapper that creates `HomeController` from `FlaiProviders` and passes data to `FlaiHomeScreen`
- **`HomeController`** — loads conversations, handles send/stream, manages active chat state
- **`FlaiChatContent`** — message list + composer, uses `MessageBubble` + `FlaiTypingIndicator`
- **`FlaiHomeScreen`** — sidebar drawer + top nav + chat area (empty state or active chat)

The scaffold transitions from empty state to active chat automatically when the user sends a message (sets a local conversation ID immediately, replaced by server ID after streaming completes).

### Streaming
- `ChatEvent` is a sealed Dart class with subtypes: TextDelta, TextDone, ThinkingStart, ThinkingDelta, ThinkingEnd, ToolCallStart, ToolCallDelta, ToolCallEnd, CitationsReceived, UsageUpdate, ChatDone, ChatError
- Providers parse SSE byte streams from raw HTTP responses
- HTTP send has 30s timeout; SSE stream has 60s per-event timeout (no infinite hangs)

### Provider Interfaces
4 pluggable abstract interfaces — developer implements against their backend:

| Interface | Purpose | Default |
|-----------|---------|---------|
| `AiProvider` | Chat streaming, tool use, vision | None (install provider brick) |
| `AuthProvider` | Login, register, reset, verify, session | `MockAuthProvider` |
| `StorageProvider` | Save, load, delete, star conversations | `InMemoryStorageProvider` |
| `VoiceProvider` | Transcribe, synthesize, conversation mode | None |

### Flow Bricks
Flow bricks generate complete multi-screen features into `lib/flai/flows/`:
- `auth_flow` — 6 screens (login landing, email entry, password entry, forgot password, verification code, reset password) + AuthController state machine + AuthFlowConfig
- `onboarding_flow` — splash, naming, multi-select pills, custom steps, reveal animation + OnboardingController
- `chat_experience` — composer v2, voice recorder, model selector sheet, ghost mode banner, attachment menu, empty chat state
- `sidebar_nav` — sidebar drawer, settings drawer (6 sub-pages), top nav bar, workspace switcher, chat list items
- `app_scaffold` — FlaiApp root widget, GoRouter with auth redirects, HomeController, FlaiChatContent, FlaiProviders InheritedWidget

## Development

### Monorepo Management
```bash
melos bootstrap                    # Install deps across all packages
melos run analyze                  # Run analysis across all packages
melos run format                   # Run formatting check
melos run test                     # Run tests
```

### CLI Development
```bash
cd packages/flai_cli
dart analyze
dart run bin/flai.dart init
dart run bin/flai.dart add app_scaffold
dart run bin/flai.dart connect cmmd
```

### Example App
The example app dogfoods the full CLI pipeline:
```bash
cd example
flutter pub get
flutter analyze                    # Analyze ONLY the example app (not brick templates)
flutter run
```

### E2E Tests (Maestro)
```bash
cd example
maestro test .maestro/chat_flow_test.yaml \
  -e FLAI_TEST_EMAIL=<email> \
  -e FLAI_TEST_PASSWORD=<password>
maestro test .maestro/                    # Run ALL tests
```
Test files: `chat_flow_test`, `sidebar_test`, `logout_test`, `session_test`, `markdown_test`, `rename_test`, `voice_test`, `forgot_password_test`, `tool_calls_test`, `citations_test`. Shared helpers: `shared_login.yaml`, `assert_real_response.yaml`. Credentials in `.maestro/.env` (gitignored) but pass `-e` flags explicitly — auto-loading is unreliable.

### Brick Development
- Bricks live in `bricks/<component_name>/`
- Each has `brick.yaml` (metadata, vars) and `__brick__/` (template files)
- Template paths use `{{output_dir}}` which defaults to `flai` in consumer projects
- Test bricks by running: `mason make <brick_name> --output-dir test_output`
- **Brick ↔ example sync:** The example app's `lib/flai/` is the generated output. When updating brick source, also regenerate or manually update the example. They must stay in sync.

## Key Conventions

1. **Theme access:** All widgets use `FlaiTheme.of(context)` -- never hardcode colors, sizes, or fonts
2. **No external deps in core:** The `flai_init` brick has zero dependencies beyond Flutter. Component bricks add deps only when installed (e.g., `flutter_markdown` for message_bubble, `package:http` for providers)
3. **Widget pattern:** Complex components follow Widget + Controller + State. Simple components are StatelessWidget or single StatefulWidget
4. **Naming:** Widget classes prefixed with `Flai` (e.g., `FlaiChatScreen`, `FlaiInputBar`, `FlaiTypingIndicator`). Data classes are unprefixed (e.g., `Message`, `ChatEvent`). Exception: `MessageBubble` (no prefix, matches the data model it renders)
5. **Imports:** Components import from relative paths within the generated structure, not package imports
6. **Sealed events:** Use Dart sealed classes and pattern matching for type-safe event handling
7. **Cancellation:** Providers support mid-stream cancellation by closing the HTTP client
8. **Use our own components:** The app scaffold's `FlaiChatContent` MUST use the real component bricks (MessageBubble, FlaiTypingIndicator, FlaiStreamingText) — never hand-roll message rendering with plain Text/Container widgets

## Code Style

- Dart 3.11+ features: sealed classes, pattern matching, records
- Follow `dart analyze --fatal-infos` with no warnings
- `dart format` with default line length
- Prefer `const` constructors where possible
- Use `///` doc comments on all public APIs
- Named parameters for constructors with more than 2 parameters

## GitHub Actions (Claude Code Action)

When Claude runs via `@claude` mentions on issues/PRs:
- Always create a feature branch from `main` — never commit directly to `main`
- Run `melos bootstrap` first, then `melos run analyze` and `melos run format` before opening PRs
- Run `flutter analyze` from `example/` to validate the example app compiles
- Keep brick templates and the example app in sync — if you change a brick, update the corresponding files in `example/lib/flai/`
- PR titles: `type(scope): description` (e.g., `fix(chat_experience): handle empty message list`)
- Link related issues with "Fixes #123" in PR body
- Do not modify CI/CD config, secrets, or deployment files unless explicitly asked
- Do not add new dependencies without explicit approval
- Do not touch `bricks/cmmd_providers/` — that brick is private to the CMMD backend

## Gotchas

- **Brick template paths** — `{{output_dir}}` in paths breaks shell globbing. Use `find` with quotes: `find "bricks/app_scaffold/__brick__" -name "*.dart"`
- **`flutter analyze` scope** — Run from `example/` to analyze only the app. Running from monorepo root includes brick templates which can't compile standalone and produce hundreds of false errors.
- **Example app base URL** — `main.dart` uses `CmmdConfig()` (production cmmd.ai). Change to `CmmdConfig.dev()` for localhost:3000 or `CmmdConfig.staging()` for staging.cmmd.ai.
- **Simulator "Lost connection"** — Usually caused by a new `flutter run` killing the old process, not a crash. Boot simulator first: `xcrun simctl boot <UDID> && open -a Simulator`
- **CMMD SSE format** — Uses standard SSE with `event:` field (NOT bare `data:` lines with a `type` field). Text arrives as `event: delta`, not `event: message`. See `.claude.local.md` for full protocol spec.
- **Maestro hamburger tap** — Use `point: "10%,10%"` to open the sidebar drawer on iPhone 17 Pro. `12%,13%` misses the button and hits the title text. Confirm sidebar open with `extendedWaitUntil: visible: "RECENTS"` (not `"FlAI Chat"` which is also in the app bar). (2026-03-27)
- **Maestro env vars** — Always pass `-e FLAI_TEST_EMAIL=... -e FLAI_TEST_PASSWORD=...` explicitly. The `.maestro/.env` auto-loading is unreliable. (2026-03-27)
- **Bottom sheets from Drawer** — Any `showModalBottomSheet` called from within the Scaffold Drawer must use `useRootNavigator: true`, otherwise the sheet opens behind the drawer. `showDialog` already defaults to `useRootNavigator: true`. (2026-03-27)
- **Drawer rebuild crash** — Calling `notifyListeners()` on `HomeController` while the Scaffold drawer is open can trigger `_dependents.isEmpty` assertion in debug mode. The rename flow hits this; delete does not. Root cause is InheritedElement lifecycle during drawer rebuild. (2026-03-27)
