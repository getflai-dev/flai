# FlAI

**AI chat components for Flutter — own your code, not your dependencies.**

[![Pub Version](https://img.shields.io/pub/v/flai_cli)](https://pub.dev/packages/flai_cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/getflai-dev/flutter-ai-chat-components/actions/workflows/ci.yml/badge.svg)](https://github.com/getflai-dev/flutter-ai-chat-components/actions/workflows/ci.yml)

FlAI is a [shadcn/ui](https://ui.shadcn.com)-style component library for Flutter, purpose-built for AI chat interfaces. Instead of importing a package, you install component source code directly into your project via a CLI — giving you full ownership and customization.

## Quick Start

```bash
# Install the CLI
dart pub global activate flai_cli

# Initialize FlAI in your Flutter project
flai init

# Add components
flai add chat_screen

# That's it — source code is now in lib/flai/
```

Wrap your app with the theme:

```dart
import 'flai/core/theme/flai_theme.dart';

MaterialApp(
  home: FlaiTheme(
    data: FlaiThemeData.dark(),
    child: const MyChatScreen(),
  ),
);
```

## Components

| Category | Components |
|----------|-----------|
| **Chat Essentials** | `chat_screen` `message_bubble` `input_bar` `streaming_text` `typing_indicator` |
| **AI Widgets** | `tool_call_card` `code_block` `thinking_indicator` `citation_card` `image_preview` |
| **Conversation** | `conversation_list` `model_selector` `token_usage` |
| **Providers** | `openai_provider` `anthropic_provider` |

Each component resolves its dependencies automatically. For example, `flai add chat_screen` also installs `message_bubble`, `input_bar`, and `streaming_text`.

## Theme Presets

FlAI ships with 4 built-in theme presets:

- **`FlaiThemeData.light()`** — Clean zinc light theme (shadcn-inspired)
- **`FlaiThemeData.dark()`** — Zinc dark theme
- **`FlaiThemeData.ios()`** — Apple Messages inspired with SF-style icons and larger radii
- **`FlaiThemeData.premium()`** — Linear-inspired deep dark with indigo accents and sharp icons

All theme files are installed into your project — edit them directly.

## Documentation

Full documentation, component gallery, and guides at **[getflai.dev](https://getflai.dev)**.

## Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
