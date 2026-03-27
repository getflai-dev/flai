<p align="center">
  <a href="https://getflai.dev">
    <img src="brand/png/github-social-preview.png" alt="flai — Beautiful AI chat components for Flutter" />
  </a>
</p>

<p align="center">
  <a href="https://getflai.dev">Documentation</a> · <a href="https://getflai.dev/components">Components</a> · <a href="https://getflai.dev/themes">Themes</a>
</p>

<p align="center">
  <a href="https://pub.dev/packages/flai_cli"><img src="https://img.shields.io/pub/v/flai_cli" alt="Pub Version" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT" /></a>
  <a href="https://github.com/getflai-dev/flai/actions/workflows/ci.yml"><img src="https://github.com/getflai-dev/flai/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
</p>

---

**FlAI** is a [shadcn/ui](https://ui.shadcn.com)-style component library for Flutter focused on AI chat interfaces. Components are distributed as source code via a CLI — you own every line.

## Quick Start

```bash
dart pub global activate flai_cli

flai init                    # Set your app name, assistant name, and theme
flai add app_scaffold        # Generates 83 files + a ready-to-run main.dart
flutter pub get && flutter run
```

That's it. You have a fully functional AI chat app with auth, onboarding, sidebar, and streaming chat — running on your device.

### Connect a backend

```bash
flai connect cmmd            # Rewrites main.dart with production CMMD providers
flutter pub get && flutter run
```

Your app is now connected to a real AI backend with authentication, conversation persistence, voice, and model selection. Zero boilerplate.

## What you get

`flai add app_scaffold` installs **7 bricks (83 files)** with a single command:

| Brick | What it does |
|-------|-------------|
| **auth_flow** | Login, register, forgot password, verification, reset (6 screens) |
| **onboarding_flow** | Splash, naming, multi-select pills, reveal animation |
| **chat_experience** | Composer with voice, model selector, attachments, ghost mode |
| **sidebar_nav** | Drawer, conversation list with grouping, settings sheet |
| **message_bubble** | Markdown rendering, code copy, thinking blocks, citations |
| **typing_indicator** | Animated loading dots |
| **app_scaffold** | GoRouter wiring, session persistence, home controller |

Plus a generated `main.dart` with your branding and chosen theme preset.

## Themes

4 built-in presets, fully customizable:

```dart
FlaiThemeData.dark()      // Default dark theme
FlaiThemeData.light()     // Clean light theme
FlaiThemeData.ios()       // Apple-style
FlaiThemeData.premium()   // Linear-inspired
```

Set during `flai init` or change anytime in code.

## Provider interfaces

FlAI defines 4 pluggable abstract interfaces. Implement against your own backend, or use a built-in provider brick:

| Interface | Purpose |
|-----------|---------|
| `AiProvider` | Chat streaming, tool use, vision |
| `AuthProvider` | Login, register, session management |
| `StorageProvider` | Conversation persistence |
| `VoiceProvider` | Speech-to-text, text-to-speech |

## Not a package

FlAI is **not** a pub.dev dependency. Source code is installed directly into your project at `lib/flai/`. You own it, you customize it, you ship it. No lock-in, no breaking updates, no opaque abstractions.

## Documentation

Visit [getflai.dev](https://getflai.dev) for full documentation, component API reference, and guides.

## Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
