# FlAI -- AI Chat Components for Flutter

## What is FlAI?

A shadcn/ui-style component library for Flutter focused on AI chat interfaces. Components are distributed as Mason brick templates via a Dart CLI. Developers own the source code -- it lives in their project, not behind a package abstraction.

## Project Structure

```
bricks/                          Mason brick templates (one per component)
  flai_init/                     Core foundation (theme, models, provider interfaces)
  auth_flow/                     Login, register, forgot password, verification, reset
  chat_screen/                   Full chat screen widget
  message_bubble/                Message bubble with markdown, thinking, citations
  input_bar/                     Text input with send button
  streaming_text/                Token-by-token text rendering
  typing_indicator/              Animated loading dots
  tool_call_card/                Function call display
  code_block/                    Code display with copy
  thinking_indicator/            AI reasoning panel
  citation_card/                 Source attribution
  image_preview/                 Image thumbnail with zoom
  conversation_list/             Conversation history list
  model_selector/                AI model picker
  token_usage/                   Token count display
  openai_provider/               OpenAI API integration
  anthropic_provider/            Anthropic API integration
packages/
  flai_cli/                      Dart CLI tool (flai init, flai add)
  flai_mcp/                      MCP server for AI assistants
  flai_skill/                    Claude Code skill
example/                         Showcase Flutter app (dogfoods all components)
docs-site/                       Documentation website
docs/                            Additional documentation
```

## Architecture

### Component Distribution
- Mason-powered CLI distributes component source code as bricks
- Each brick has a `brick.yaml` and template files under `__brick__/`
- Templates use `{{output_dir}}` variable for target path in consumer projects
- `flai init` generates the core foundation; `flai add <component>` adds individual components

### Theme System
- InheritedWidget-based `FlaiTheme` (not MaterialTheme extension)
- All widgets access styling via `FlaiTheme.of(context)`
- `FlaiThemeData` composes: `FlaiColors`, `FlaiTypography`, `FlaiRadius`, `FlaiSpacing`
- Semantic color tokens matching shadcn/ui naming (background, foreground, primary, muted, etc.)
- Chat-specific tokens: userBubble, userBubbleForeground, assistantBubble, assistantBubbleForeground
- 4 built-in presets: `light()`, `dark()`, `ios()`, `premium()`

### State Management
- Vanilla Flutter: ChangeNotifier + Streams, no external packages
- `ChatScreenController` extends `ChangeNotifier` for chat state
- `AuthController` extends `ChangeNotifier` for auth flow state machine
- `AiProvider` abstract interface returns `Stream<ChatEvent>` for streaming

### Streaming
- `ChatEvent` is a sealed Dart class with subtypes: TextDelta, TextDone, ThinkingStart, ThinkingDelta, ThinkingEnd, ToolCallStart, ToolCallDelta, ToolCallEnd, UsageUpdate, ChatDone, ChatError
- Providers parse SSE byte streams from raw HTTP responses
- Both OpenAI and Anthropic providers use `package:http` directly (no SDK wrappers)

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

## Development

### Monorepo Management
```bash
# Bootstrap (install deps across all packages)
melos bootstrap

# Run analysis across all packages
melos run analyze

# Run formatting check
melos run format

# Run tests
melos run test
```

### CLI Development
```bash
cd packages/flai_cli
dart analyze
dart run bin/flai.dart init
dart run bin/flai.dart add chat_screen
```

### Example App
```bash
cd example
flutter run --dart-define=OPENAI_API_KEY=sk-...
```

### Brick Development
- Bricks live in `bricks/<component_name>/`
- Each has `brick.yaml` (metadata, vars) and `__brick__/` (template files)
- Template paths use `{{output_dir}}` which defaults to `flai` in consumer projects
- Test bricks by running: `mason make <brick_name> --output-dir test_output`

## Key Conventions

1. **Theme access:** All widgets use `FlaiTheme.of(context)` -- never hardcode colors, sizes, or fonts
2. **No external deps in core:** The `flai_init` brick has zero dependencies beyond Flutter. Component bricks add deps only when installed (e.g., `package:http` for providers)
3. **Widget pattern:** Complex components follow Widget + Controller + State. Simple components are StatelessWidget or single StatefulWidget
4. **Naming:** Widget classes prefixed with `Flai` (e.g., `FlaiChatScreen`, `FlaiInputBar`, `FlaiTypingIndicator`). Data classes are unprefixed (e.g., `Message`, `ChatEvent`)
5. **Imports:** Components import from relative paths within the generated structure, not package imports
6. **Sealed events:** Use Dart sealed classes and pattern matching for type-safe event handling
7. **Cancellation:** Providers support mid-stream cancellation by closing the HTTP client

## Code Style

- Dart 3.4+ features: sealed classes, pattern matching, records
- Follow `dart analyze --fatal-infos` with no warnings
- `dart format` with default line length
- Prefer `const` constructors where possible
- Use `///` doc comments on all public APIs
- Named parameters for constructors with more than 2 parameters
