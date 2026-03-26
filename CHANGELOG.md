# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
