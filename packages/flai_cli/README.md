# FlAI CLI

A CLI tool for installing AI chat components into Flutter projects. Like shadcn/ui — you own the source code.

## Install

```bash
dart pub global activate flai_cli
```

## Usage

```bash
# Initialize FlAI in your Flutter project
flai init

# Add components
flai add chat_screen
flai add openai_provider

# List available components
flai list

# Check project health
flai doctor
```

## How it works

FlAI generates component source code directly into your project using [Mason](https://pub.dev/packages/mason) brick templates. You get full ownership of every file — customize freely.

### Available components

| Component | Description |
|-----------|-------------|
| `chat_screen` | Full chat screen with messages, input, and streaming |
| `message_bubble` | Styled message bubble with markdown support |
| `input_bar` | Chat input bar with send button |
| `streaming_text` | Token-by-token text rendering |
| `typing_indicator` | Animated loading dots |
| `tool_call_card` | AI function call display |
| `code_block` | Syntax-highlighted code with copy |
| `thinking_indicator` | AI reasoning panel |
| `citation_card` | Source attribution card |
| `image_preview` | Image thumbnail with zoom |
| `conversation_list` | Chat history list |
| `model_selector` | AI model picker |
| `token_usage` | Token count display |
| `openai_provider` | OpenAI API integration |
| `anthropic_provider` | Anthropic API integration |
| `auth_flow` | Complete auth flow (login, register, forgot password, verify, reset) |
| `onboarding_flow` | Onboarding flow (splash, naming, multi-select pills, custom steps, reveal) |
| `chat_experience` | Chat experience (composer v2, model selector, voice modes, ghost mode, empty state) |
| `sidebar_nav` | Sidebar drawer (conversation list, settings sheet, workspace switcher, sub-pages) |
| `app_scaffold` | Production app shell wiring auth, onboarding, chat, and sidebar flows with GoRouter |

## Links

- [Documentation](https://getflai.dev)
- [GitHub](https://github.com/getflai-dev/flai)
