/// Metadata for a single FlAI component brick.
class BrickInfo {
  final String name;
  final String description;
  final String category;

  /// Other FlAI components this brick depends on.
  final List<String> dependencies;

  /// Pub.dev packages that must be added to the project's pubspec.yaml.
  final List<String> pubDependencies;

  const BrickInfo({
    required this.name,
    required this.description,
    required this.category,
    this.dependencies = const [],
    this.pubDependencies = const [],
  });
}

/// Categories used to group components in the CLI output.
abstract final class BrickCategory {
  static const String chatEssentials = 'Chat Essentials';
  static const String aiWidgets = 'AI Widgets';
  static const String conversation = 'Conversation';
  static const String providers = 'Providers';
  static const String flows = 'Flows';
}

/// Static registry of all available FlAI component bricks.
abstract final class BrickRegistry {
  static const Map<String, BrickInfo> components = {
    // ── Chat Essentials ──────────────────────────────────────────────
    'chat_screen': BrickInfo(
      name: 'chat_screen',
      description:
          'Full-featured chat screen with messages, input, and streaming.',
      category: BrickCategory.chatEssentials,
      dependencies: [
        'message_bubble',
        'input_bar',
        'streaming_text',
        'typing_indicator',
      ],
    ),
    'message_bubble': BrickInfo(
      name: 'message_bubble',
      description: 'Styled message bubble supporting markdown content.',
      category: BrickCategory.chatEssentials,
      pubDependencies: ['flutter_markdown'],
    ),
    'input_bar': BrickInfo(
      name: 'input_bar',
      description: 'Chat input bar with send button and text field.',
      category: BrickCategory.chatEssentials,
    ),
    'streaming_text': BrickInfo(
      name: 'streaming_text',
      description: 'Animated text widget that renders streamed token output.',
      category: BrickCategory.chatEssentials,
    ),
    'typing_indicator': BrickInfo(
      name: 'typing_indicator',
      description: 'Animated dots indicating the AI is responding.',
      category: BrickCategory.chatEssentials,
    ),

    // ── AI Widgets ───────────────────────────────────────────────────
    'tool_call_card': BrickInfo(
      name: 'tool_call_card',
      description:
          'Card that displays an AI tool/function call and its result.',
      category: BrickCategory.aiWidgets,
    ),
    'code_block': BrickInfo(
      name: 'code_block',
      description: 'Syntax-highlighted code block with copy button.',
      category: BrickCategory.aiWidgets,
      pubDependencies: ['flutter_highlight'],
    ),
    'thinking_indicator': BrickInfo(
      name: 'thinking_indicator',
      description:
          'Expandable panel showing the AI reasoning/thinking process.',
      category: BrickCategory.aiWidgets,
    ),
    'citation_card': BrickInfo(
      name: 'citation_card',
      description: 'Inline citation card linking to source material.',
      category: BrickCategory.aiWidgets,
    ),
    'image_preview': BrickInfo(
      name: 'image_preview',
      description: 'Thumbnail image preview with full-screen expansion.',
      category: BrickCategory.aiWidgets,
    ),

    // ── Conversation ─────────────────────────────────────────────────
    'conversation_list': BrickInfo(
      name: 'conversation_list',
      description: 'Scrollable list of past conversations with search.',
      category: BrickCategory.conversation,
    ),
    'model_selector': BrickInfo(
      name: 'model_selector',
      description: 'Dropdown selector for switching between AI models.',
      category: BrickCategory.conversation,
    ),
    'token_usage': BrickInfo(
      name: 'token_usage',
      description: 'Widget displaying token count and usage statistics.',
      category: BrickCategory.conversation,
    ),

    // ── Providers ────────────────────────────────────────────────────
    'openai_provider': BrickInfo(
      name: 'openai_provider',
      description: 'Provider implementation for the OpenAI API.',
      category: BrickCategory.providers,
      pubDependencies: ['http'],
    ),
    'anthropic_provider': BrickInfo(
      name: 'anthropic_provider',
      description: 'Provider implementation for the Anthropic API.',
      category: BrickCategory.providers,
      pubDependencies: ['http'],
    ),

    // ── Flows ───────────────────────────────────────────────────────
    'auth_flow': BrickInfo(
      name: 'auth_flow',
      description:
          'Complete authentication flow with login, register, forgot password, verification, and reset screens.',
      category: BrickCategory.flows,
    ),
    'onboarding_flow': BrickInfo(
      name: 'onboarding_flow',
      description:
          'Configurable onboarding flow with splash, naming, multi-select pills, custom steps, and reveal animation.',
      category: BrickCategory.flows,
    ),
    'chat_experience': BrickInfo(
      name: 'chat_experience',
      description:
          'AI chat experience with composer v2, model selector, voice modes, ghost mode, and empty state.',
      category: BrickCategory.flows,
      pubDependencies: [
        'image_picker',
        'file_picker',
      ],
    ),
    'sidebar_nav': BrickInfo(
      name: 'sidebar_nav',
      description:
          'Sidebar navigation flow with drawer, conversation lists, search, and settings sheet.',
      category: BrickCategory.flows,
    ),
    'app_scaffold': BrickInfo(
      name: 'app_scaffold',
      description:
          'Production-ready app shell wiring auth, onboarding, chat, and sidebar flows with GoRouter.',
      category: BrickCategory.flows,
      dependencies: [
        'auth_flow',
        'onboarding_flow',
        'chat_experience',
        'sidebar_nav',
      ],
      pubDependencies: ['go_router', 'flutter_secure_storage'],
    ),
  };

  /// Returns all unique categories in display order.
  static List<String> get categories => const [
    BrickCategory.chatEssentials,
    BrickCategory.aiWidgets,
    BrickCategory.conversation,
    BrickCategory.providers,
    BrickCategory.flows,
  ];

  /// Returns all bricks belonging to [category].
  static List<BrickInfo> byCategory(String category) {
    return components.values
        .where((b) => b.category == category)
        .toList(growable: false);
  }

  /// Looks up a brick by name. Returns `null` if not found.
  static BrickInfo? lookup(String name) => components[name];
}
