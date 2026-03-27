# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.3.0] - 2026-03-27

### Added
- **Zero-config CLI** — interactive `flai init` prompts for app name, assistant name, and theme preset (dark/light/ios/premium)
- **Auto-generated main.dart** — `flai add app_scaffold` now generates a ready-to-run `main.dart` with your branding and theme
- **Connect auto-wiring** — `flai connect cmmd` rewrites `main.dart` to swap mock providers with production CMMD providers (auth, AI, storage, voice)
- **Share conversation** — system share sheet integration via `share_plus`
- **Animated send button** — smooth mic/arrow icon morph with `AnimatedSwitcher` as user types
- **Attachment preview row** — picked files shown as thumbnails in the composer with remove button
- **Conversation grouping** — sidebar groups conversations by Today, Yesterday, Previous 7 Days, Older
- **Markdown rendering** — `MessageBubble` renders markdown with `flutter_markdown`, code blocks with copy-to-clipboard
- **Thinking/reasoning panel** — collapsible thinking content in assistant messages
- **Code block copy** — one-tap copy for code blocks with haptic feedback
- **Copy message** — long-press to copy message content
- **Scroll-to-bottom FAB** — appears when scrolled up, smooth scroll with haptic feedback
- **Regenerate response** — button below assistant messages to retry with the previous user message
- **Assistant avatar** — configurable avatar in message bubbles
- **Model selector** — bottom sheet to switch AI models per-conversation
- **Haptic feedback** — on send, star, delete, copy, scroll-to-bottom actions
- **3 new Maestro E2E tests** — share_test, send_button_test, attachment_test
- **`flai.yaml` branding** — stores app_name, assistant_name, theme for downstream code generation
- **`--no-interactive` flag** — CI/scripting mode for `flai init` with `--app-name`, `--assistant-name`, `--theme` flags

### Changed
- **Brick templates synced** — 15 files across 6 bricks (app_scaffold, chat_experience, message_bubble, sidebar_nav, flai_init, cmmd_providers) synced with example app
- **CLI dependency chain** — `app_scaffold` now properly declares `message_bubble` and `typing_indicator` as dependencies
- **`message_bubble` brick** — added `markdown` to pub dependencies
- **MCP server** — updated all tools for new DX, added Flows category with 5 flow bricks
- **Claude Code skill** — complete rewrite documenting zero-config pipeline
- **README** — rewritten with 3-command quick start and feature table
- **Landing page** — new hero headline, interactive terminal mockup, updated 3-step section
- **Getting started docs** — complete rewrite with new pipeline, connect backend, feature list

### Fixed
- **`cmmd_client_base.dart`** — added to `cmmd_providers` brick (was in example only)
- **Connect command** — now lists `cmmd_client_base.dart` in output
- **Second-brain plugin** — fixed relative path in PreCompact hook (resolved from CWD, not plugin dir)

- **Auth flow brick** (`auth_flow`) — complete authentication flow with 6 screens: login landing (social auth + typing taglines), email entry, password entry (login/signup modes), forgot password, verification code, reset password
- **AuthProvider interface** — pluggable authentication backend with social auth (Apple, Google, Microsoft), email auth, password reset, verification, session management
- **StorageProvider interface** — pluggable conversation persistence with `InMemoryStorageProvider` default
- **VoiceProvider interface** — pluggable voice I/O with push-to-talk and conversation mode support
- **AuthController** — state machine managing auth flow navigation, loading states, and error handling
- **MockAuthProvider** — development/testing auth provider with configurable delay and failure simulation
- **AuthFlowConfig** — configurable button visibility, branding (logo, taglines), legal links, guest mode
- **Shared auth widgets** — `SocialAuthButton`, `AuthTextField`, `TypingTagline` (letter-by-letter animation)
- **FlaiTypography TextStyle getters** — `sm`, `base`, `lg`, `xl` now return `TextStyle` for `.copyWith()` support
- **Onboarding flow brick** (`onboarding_flow`) — configurable onboarding with 5 screens: splash (pulse animation), name-your-assistant (suggestion pills), multi-select pills (staggered animation), custom steps, reveal (gradient glow + typing name)
- **OnboardingController** — step navigation state machine with result collection
- **OnboardingConfig** — step pipeline with `OnboardingStep` sealed class (naming, multiSelect, custom, reveal)
- **Shared onboarding widgets** — `PillChip` (animated toggle), `TypingText` (letter-by-letter animation)
- **Chat experience brick** (`chat_experience`) — AI chat experience with composer v2, model selector, voice modes, ghost mode, and empty chat state
- **AvatarConfig + FlaiAvatar** — 5-mode avatar rendering (icon+gradient, icon+solid, image, custom widget, default)
- **FlaiComposerV2** — pill-shaped message composer with text field, sectioned + menu, model chip, animated mic/send toggle
- **Voice modes** — `VoiceRecorder` (inline push-to-talk waveform), `FlaiVoiceConversationOverlay` (full-screen orb with gradient glow)
- **ChatExperienceConfig** — configurable assistant name, avatar, greeting, composer sections, model list, voice/ghost toggles
- **Sidebar nav brick** (`sidebar_nav`) — slide-out drawer with conversation list, settings sheet, and workspace switcher
- **SidebarConfig** — nav items, user profile, conversation list, new-chat callback
- **SettingsConfig** — sealed `SettingsRow` class (navigation, dropdown, toggle, info, custom), sections, info items, app version
- **Settings sub-pages** — profile, billing, usage, connectors, notifications, privacy
- **TopNavBar** — hamburger menu + new chat + model display
- **ChatListItem** — swipe-to-delete, long-press context menu, inline rename
- **WorkspaceSwitcher** — team/workspace selector with avatar and chevron
- **App scaffold brick** (`app_scaffold`) — rewritten as thin wiring shell composing all 4 flow bricks with GoRouter
- **AppScaffoldConfig** — single config object bundling all providers, theme, and flow configurations
- **FlaiProviders** — InheritedWidget exposing AiProvider, AuthProvider, StorageProvider, VoiceProvider to the widget tree
- **FlaiHomeScreen** — main screen composing TopNavBar + SidebarDrawer + chat content area
- **GoRouter routing** — splash → auth → onboarding → main chat with auth state redirects

## [0.2.0] - 2026-03-26

### Added
- **App scaffold brick** (`app_scaffold`) — full production app template with auth flow (login, register, forgot password), chat list + detail screens, settings page (theme/model/API key), profile page, GoRouter routing with auth redirects
- **MCP server** updated with `scaffold_chat_app` and `get_starter_template` tools
- **MCP server** ready for npm publishing as `@getflai/mcp`
- **Skill** updated with FlaiIconData docs, starter patterns, icon system
- **Brand asset kit** (13 SVGs, 28 PNGs) — icons, horizontal/stacked/mono logos, social banners, Twitter header, GitHub social preview
- **GitHub org** (`getflai-dev`) with branding and social preview
- **Cloudflare Email Routing** for getflai.dev
- **GitHub Actions secrets** for CI/CD

### Changed
- Repository moved to `getflai-dev/flai`
- Domain references updated to `getflai.dev`
- README redesigned to minimal shadcn-style with social banner hero
- Homepage header aligned with content container
- Docs header full-width for sidebar layout alignment

### Fixed
- README logo dark/light mode via `<picture>` element
- Unused import in CLI tests failing CI
- `docs/superpowers/` excluded from version control

## [0.1.0] - 2026-03-25

### Added
- **CLI tool** (`flai_cli`) with four commands: `init`, `add`, `list`, `doctor`
- **Core foundation** (`flai_init` brick): FlaiTheme system, data models (Message, ChatEvent, ChatRequest), AiProvider interface
- **Theme system**: 4 built-in presets — light, dark, iOS, premium — with FlaiColors, FlaiTypography, FlaiRadius, FlaiSpacing, FlaiIconData
- **Themed icon sets**: Material rounded (default), Cupertino (iOS), Material sharp (premium) with 20 semantic icon slots
- **Chat essentials**: chat_screen, message_bubble, input_bar, streaming_text, typing_indicator bricks
- **AI-specific widgets**: tool_call_card, code_block, thinking_indicator, citation_card, image_preview bricks
- **Conversation management**: conversation_list, model_selector, token_usage bricks
- **AI providers**: openai_provider and anthropic_provider bricks with SSE streaming, tool use, and vision support
- **Dependency resolver**: automatic component dependency resolution and pubspec.yaml modification
- **Documentation site** at getflai.dev with component gallery, theme previews, and getting started guide
- **Example app** dogfooding all components
