#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

// ---------------------------------------------------------------------------
// Component Registry
// ---------------------------------------------------------------------------

interface ComponentInfo {
  name: string;
  description: string;
  category: string;
  dependencies: string[];
  pubDependencies: string[];
  props: Record<string, string>;
  usageExample: string;
}

const CATEGORIES = {
  CHAT_ESSENTIALS: "Chat Essentials",
  AI_WIDGETS: "AI Widgets",
  CONVERSATION: "Conversation",
  PROVIDERS: "Providers",
  FLOWS: "Flows",
} as const;

const COMPONENT_REGISTRY: Record<string, ComponentInfo> = {
  // ── Chat Essentials ─────────────────────────────────────────────────────
  chat_screen: {
    name: "chat_screen",
    description:
      "Full-page AI chat screen composing message bubbles, input bar, streaming text, and typing indicator into a complete chat experience. Connects to a ChatScreenController for state management and AI provider interaction.",
    category: CATEGORIES.CHAT_ESSENTIALS,
    dependencies: ["message_bubble", "input_bar", "streaming_text", "typing_indicator"],
    pubDependencies: [],
    props: {
      controller: "ChatScreenController — manages chat state and AI interaction",
      title: "String? — title displayed in the header",
      subtitle: "String? — subtitle below the title (e.g., model name)",
      leading: "Widget? — optional leading widget in the header (e.g., avatar)",
      actions: "List<Widget>? — trailing widgets in the header",
      onTapCitation: "Function(Citation)? — called when a citation is tapped",
      onLongPress: "Function(Message)? — called when a message is long-pressed",
      onAttachmentTap: "VoidCallback? — called when attachment button is tapped",
      showHeader: "bool — whether to show the header bar (default: true)",
      inputPlaceholder: "String — placeholder text for the input field",
      emptyState: "Widget? — widget to display when there are no messages",
    },
    usageExample: `final controller = ChatScreenController(provider: myAiProvider);

FlaiChatScreen(
  controller: controller,
  title: 'AI Assistant',
  subtitle: 'Claude 3.5 Sonnet',
  onAttachmentTap: () => pickImage(),
)`,
  },

  message_bubble: {
    name: "message_bubble",
    description:
      "Chat message bubble that renders user, assistant, system, and tool messages with distinct styling. Supports thinking blocks, tool call chips, citation cards, streaming cursors, and error retry actions.",
    category: CATEGORIES.CHAT_ESSENTIALS,
    dependencies: [],
    pubDependencies: ["flutter_markdown"],
    props: {
      message: "Message — the message to display (required)",
      onTapCitation: "Function(Citation)? — called when a citation is tapped",
      onRetry: "Function(Message)? — called when retry button is tapped on an error message",
      onLongPress: "Function(Message)? — called when the bubble is long-pressed",
    },
    usageExample: `MessageBubble(
  message: Message(
    id: '1',
    role: MessageRole.assistant,
    content: 'Hello! How can I help you today?',
    status: MessageStatus.complete,
  ),
  onTapCitation: (citation) => launchUrl(citation.url),
  onRetry: (msg) => controller.retry(msg),
)`,
  },

  input_bar: {
    name: "input_bar",
    description:
      "Production-quality chat input bar with text field, send button, and optional attachment support. Supports multi-line input with dynamic height growth, Enter-to-send on desktop/web, and SafeArea bottom padding.",
    category: CATEGORIES.CHAT_ESSENTIALS,
    dependencies: [],
    pubDependencies: [],
    props: {
      onSend: "ValueChanged<String> — called when the user submits a message (required)",
      onAttachmentTap: "VoidCallback? — called when attachment button is tapped; hidden if null",
      onTextChanged: "ValueChanged<String>? — called when text field content changes",
      placeholder: "String — hint text when field is empty (default: 'Message...')",
      enabled: "bool — whether the input bar is interactive (default: true)",
      maxLines: "int — max visible text lines before scrolling (default: 5)",
      autofocus: "bool — whether to autofocus on build (default: false)",
    },
    usageExample: `FlaiInputBar(
  onSend: (text) => controller.sendMessage(text),
  onAttachmentTap: () => pickFile(),
  placeholder: 'Ask anything...',
)`,
  },

  streaming_text: {
    name: "streaming_text",
    description:
      "Widget that renders text being streamed token-by-token from an AI provider, with an animated blinking cursor. Supports two modes: stream-driven (accepts a Stream<String> of deltas) and text-driven (accepts a changing String).",
    category: CATEGORIES.CHAT_ESSENTIALS,
    dependencies: [],
    pubDependencies: [],
    props: {
      text: "String? — current text to display (text-driven mode)",
      stream: "Stream<String>? — stream of text deltas (stream-driven mode)",
      isStreaming: "bool — whether streaming is active (text-driven mode, default: false)",
      style: "TextStyle? — text style for the rendered text",
      showCursor: "bool — whether to show the blinking cursor while streaming",
      cursorColor: "Color? — override color for the cursor",
    },
    usageExample: `// Stream-driven mode
FlaiStreamingText.fromStream(
  stream: aiProvider.streamChat(request)
      .whereType<TextDelta>()
      .map((e) => e.text),
  style: theme.typography.bodyBase(color: theme.colors.foreground),
)

// Text-driven mode
FlaiStreamingText(
  text: controller.currentText,
  isStreaming: controller.isStreaming,
)`,
  },

  typing_indicator: {
    name: "typing_indicator",
    description:
      "Animated three-dot typing indicator showing the AI is generating a response. Styled as an assistant bubble (left-aligned) with each dot bouncing with a staggered delay, creating a wave-like animation.",
    category: CATEGORIES.CHAT_ESSENTIALS,
    dependencies: [],
    pubDependencies: [],
    props: {
      dotSize: "double — diameter of each dot (default: 7.0)",
      dotColor: "Color? — override color for dots; defaults to FlaiColors.mutedForeground",
      bounceHeight: "double — how far each dot bounces upward in logical pixels (default: 6.0)",
    },
    usageExample: `FlaiTypingIndicator(
  dotSize: 8.0,
  bounceHeight: 7.0,
)`,
  },

  // ── AI Widgets ──────────────────────────────────────────────────────────
  tool_call_card: {
    name: "tool_call_card",
    description:
      "Card displaying an AI tool/function call with its name, arguments, result, and loading state. Shows a wrench icon and tool name in the header, parsed JSON arguments in mono-font, and the result once available.",
    category: CATEGORIES.AI_WIDGETS,
    dependencies: [],
    pubDependencies: [],
    props: {
      toolCall: "ToolCall — the tool call data to display (required)",
      onTap: "VoidCallback? — called when the card is tapped",
    },
    usageExample: `FlaiToolCallCard(
  toolCall: ToolCall(
    id: 'call_1',
    name: 'search_web',
    arguments: '{"query": "Flutter AI components"}',
    result: '3 results found...',
    isComplete: true,
  ),
  onTap: () => showToolDetails(),
)`,
  },

  code_block: {
    name: "code_block",
    description:
      "Styled code block with a language label, optional line numbers, horizontal scrolling, and a copy-to-clipboard button. Uses mono font styling from FlaiTheme and a muted background.",
    category: CATEGORIES.AI_WIDGETS,
    dependencies: [],
    pubDependencies: ["flutter_highlight"],
    props: {
      code: "String — the source code to display (required)",
      language: "String? — language identifier shown in the header (e.g. 'dart', 'json')",
      showLineNumbers: "bool — whether to show line numbers (default: false)",
      onCopy: "VoidCallback? — called after the code is copied to clipboard",
    },
    usageExample: `FlaiCodeBlock(
  code: '''
void main() {
  runApp(MyApp());
}
''',
  language: 'dart',
  showLineNumbers: true,
)`,
  },

  thinking_indicator: {
    name: "thinking_indicator",
    description:
      "Expandable panel showing the AI's reasoning/thinking process with a shimmer animation. When isThinking is true, the label pulses with a shimmer effect. Tapping the header toggles between collapsed and expanded states.",
    category: CATEGORIES.AI_WIDGETS,
    dependencies: [],
    pubDependencies: [],
    props: {
      thinkingText: "String — the raw thinking/reasoning text (required)",
      isThinking: "bool — whether the model is still actively thinking (default: false)",
      label: "String — display label in the header row (default: 'Thinking...')",
      initiallyExpanded: "bool — if true, starts in expanded state (default: false)",
    },
    usageExample: `FlaiThinkingIndicator(
  thinkingText: 'Let me analyze this step by step...',
  isThinking: true,
  label: 'Reasoning',
  initiallyExpanded: false,
)`,
  },

  citation_card: {
    name: "citation_card",
    description:
      "Compact inline citation card displaying a source reference with title and optional snippet. Shows a link icon and title in bold. Tapping invokes onTap with the Citation object.",
    category: CATEGORIES.AI_WIDGETS,
    dependencies: [],
    pubDependencies: [],
    props: {
      citation: "Citation — the citation data to display (required)",
      onTap: "Function(Citation)? — called when the card is tapped",
    },
    usageExample: `FlaiCitationCard(
  citation: Citation(
    title: 'Flutter Documentation',
    url: 'https://docs.flutter.dev',
    snippet: 'Official Flutter documentation and API reference.',
  ),
  onTap: (c) => launchUrl(Uri.parse(c.url!)),
)`,
  },

  image_preview: {
    name: "image_preview",
    description:
      "Image preview thumbnail that loads from a URL, displays a shimmer placeholder while loading, shows a broken-image icon on error, and opens a full-screen interactive viewer dialog on tap.",
    category: CATEGORIES.AI_WIDGETS,
    dependencies: [],
    pubDependencies: [],
    props: {
      imageUrl: "String — network URL of the image (required)",
      alt: "String? — alt text shown as tooltip and dialog title",
      width: "double? — constrained thumbnail width (default: 200)",
      height: "double? — constrained thumbnail height (default: 200)",
      onTap: "VoidCallback? — overrides default tap behavior (full-screen dialog)",
    },
    usageExample: `FlaiImagePreview(
  imageUrl: 'https://example.com/diagram.png',
  alt: 'Architecture Diagram',
  width: 300,
  height: 200,
)`,
  },

  // ── Conversation ────────────────────────────────────────────────────────
  conversation_list: {
    name: "conversation_list",
    description:
      "Scrollable list of past conversations with search filtering, selection highlighting, swipe-to-delete, and an empty state. Includes a search bar and new conversation button.",
    category: CATEGORIES.CONVERSATION,
    dependencies: [],
    pubDependencies: [],
    props: {
      conversations: "List<Conversation> — the conversations to display (required)",
      selectedId: "String? — currently selected conversation id",
      onSelect: "Function(Conversation)? — called when a conversation is tapped",
      onDelete: "Function(Conversation)? — called when a conversation is swiped away",
      onCreate: "VoidCallback? — called when 'New Conversation' button is tapped",
      searchPlaceholder: "String — placeholder text in the search bar",
    },
    usageExample: `FlaiConversationList(
  conversations: conversations,
  selectedId: currentConversation?.id,
  onSelect: (conv) => loadConversation(conv),
  onDelete: (conv) => deleteConversation(conv),
  onCreate: () => createNewConversation(),
)`,
  },

  model_selector: {
    name: "model_selector",
    description:
      "Compact chip showing the currently selected AI model that opens a bottom sheet picker. Displays provider badges and capability tags for each model option.",
    category: CATEGORIES.CONVERSATION,
    dependencies: [],
    pubDependencies: [],
    props: {
      models: "List<FlaiModelOption> — all available models (required)",
      selectedModelId: "String? — id of the currently selected model",
      onSelect: "Function(FlaiModelOption)? — called when the user picks a model",
    },
    usageExample: `FlaiModelSelector(
  models: [
    FlaiModelOption(
      id: 'claude-sonnet-4-20250514',
      name: 'Claude Sonnet 4',
      provider: 'Anthropic',
      contextWindow: 200000,
      capabilities: ['vision', 'tool_use', 'thinking'],
    ),
    FlaiModelOption(
      id: 'gpt-4o',
      name: 'GPT-4o',
      provider: 'OpenAI',
      contextWindow: 128000,
      capabilities: ['vision', 'tool_use'],
    ),
  ],
  selectedModelId: 'claude-sonnet-4-20250514',
  onSelect: (model) => switchModel(model),
)`,
  },

  token_usage: {
    name: "token_usage",
    description:
      "Widget displaying token usage statistics with optional cost estimation and a progress bar showing utilisation against a maximum token limit. Supports compact and expanded views.",
    category: CATEGORIES.CONVERSATION,
    dependencies: [],
    pubDependencies: [],
    props: {
      usage: "UsageInfo — token usage data: input, output, cache tokens, total (required)",
      costPerInputToken: "double? — cost per input token in dollars",
      costPerOutputToken: "double? — cost per output token in dollars",
      maxTokens: "int? — maximum token limit; shows a progress bar when provided",
      expanded: "bool — whether to show the expanded breakdown view (default: false)",
    },
    usageExample: `FlaiTokenUsage(
  usage: UsageInfo(inputTokens: 1250, outputTokens: 340),
  costPerInputToken: 0.000003,
  costPerOutputToken: 0.000015,
  maxTokens: 4096,
  expanded: true,
)`,
  },

  // ── Providers ───────────────────────────────────────────────────────────
  openai_provider: {
    name: "openai_provider",
    description:
      "OpenAI API provider implementing the AiProvider interface with streaming, tool use, and vision support. Uses raw HTTP requests to the Chat Completions API.",
    category: CATEGORIES.PROVIDERS,
    dependencies: [],
    pubDependencies: ["http"],
    props: {
      apiKey: "String — required for authentication",
      baseUrl: "String? — defaults to https://api.openai.com/v1",
      model: "String — defaults to 'gpt-4o'",
      organization: "String? — optional OpenAI-Organization header",
    },
    usageExample: `final provider = OpenAiProvider(
  apiKey: 'sk-...',
  model: 'gpt-4o',
);

final stream = provider.streamChat(ChatRequest(
  messages: [Message(role: MessageRole.user, content: 'Hello!')],
));

await for (final event in stream) {
  // Handle ChatEvent (TextDelta, ToolCallDelta, Done, Error, etc.)
}`,
  },

  anthropic_provider: {
    name: "anthropic_provider",
    description:
      "Anthropic Messages API provider implementing the AiProvider interface with streaming, tool use, extended thinking, and vision support. Uses raw HTTP requests to the Messages API.",
    category: CATEGORIES.PROVIDERS,
    dependencies: [],
    pubDependencies: ["http"],
    props: {
      apiKey: "String — required for authentication",
      baseUrl: "String — defaults to https://api.anthropic.com",
      model: "String — defaults to 'claude-sonnet-4-20250514'",
      anthropicVersion: "String — API version header (default: '2023-06-01')",
      thinkingBudgetTokens: "int? — optional thinking budget for extended thinking",
    },
    usageExample: `final provider = AnthropicProvider(
  apiKey: 'sk-ant-...',
  model: 'claude-sonnet-4-20250514',
  thinkingBudgetTokens: 10000,

);

final stream = provider.streamChat(ChatRequest(
  messages: [Message(role: MessageRole.user, content: 'Hello!')],
));

await for (final event in stream) {
  // Handle ChatEvent (TextDelta, ThinkingDelta, ToolCallDelta, etc.)
}`,
  },

  // ── Flows ───────────────────────────────────────────────────────────
  auth_flow: {
    name: "auth_flow",
    description:
      "Complete authentication flow with login, register, forgot password, verification, and reset screens. Includes AuthController state machine and AuthFlowConfig.",
    category: CATEGORIES.FLOWS,
    dependencies: [],
    pubDependencies: [],
    props: {
      config: "AuthFlowConfig — configures available auth methods, branding, and callbacks",
    },
    usageExample: `// Installed automatically by app_scaffold, or standalone:
flai add auth_flow`,
  },

  onboarding_flow: {
    name: "onboarding_flow",
    description:
      "Configurable onboarding flow with splash, naming, multi-select pills, custom steps, and reveal animation. Includes OnboardingController state machine.",
    category: CATEGORIES.FLOWS,
    dependencies: [],
    pubDependencies: [],
    props: {
      config: "OnboardingConfig — configures steps, branding, and completion callback",
    },
    usageExample: `// Installed automatically by app_scaffold, or standalone:
flai add onboarding_flow`,
  },

  chat_experience: {
    name: "chat_experience",
    description:
      "AI chat experience with composer v2, model selector, voice recorder, ghost mode banner, attachment menu, and empty chat state.",
    category: CATEGORIES.FLOWS,
    dependencies: [],
    pubDependencies: ["image_picker", "file_picker"],
    props: {
      controller: "HomeController — manages chat state, streaming, and conversations",
    },
    usageExample: `// Installed automatically by app_scaffold, or standalone:
flai add chat_experience`,
  },

  sidebar_nav: {
    name: "sidebar_nav",
    description:
      "Sidebar navigation flow with drawer, conversation lists, search, settings sheet, and workspace switcher.",
    category: CATEGORIES.FLOWS,
    dependencies: [],
    pubDependencies: [],
    props: {
      conversations: "List<Conversation> — conversation list for the sidebar",
      onSelect: "Function(Conversation) — callback when a conversation is selected",
    },
    usageExample: `// Installed automatically by app_scaffold, or standalone:
flai add sidebar_nav`,
  },

  app_scaffold: {
    name: "app_scaffold",
    description:
      "Production-ready app shell wiring auth, onboarding, chat, and sidebar flows with GoRouter. Auto-generates main.dart. Installs all 4 flow bricks plus message_bubble and typing_indicator as dependencies.",
    category: CATEGORIES.FLOWS,
    dependencies: ["auth_flow", "onboarding_flow", "chat_experience", "sidebar_nav", "message_bubble", "typing_indicator"],
    pubDependencies: ["go_router", "flutter_secure_storage", "share_plus"],
    props: {
      config: "AppScaffoldConfig — accepts FlaiProviders (AI, auth, storage, voice) and flow configs",
    },
    usageExample: `// 3-command pipeline to a running chat app:
// flai init
// flai add app_scaffold
// flutter run
//
// For production backend:
// flai connect cmmd`,
  },
};

// ---------------------------------------------------------------------------
// Theme Information
// ---------------------------------------------------------------------------

const THEME_INFO = {
  overview:
    "FlAI uses a custom InheritedWidget-based theme system (FlaiTheme) that provides design tokens for colors, typography, radius, and spacing. All components read tokens exclusively via FlaiTheme.of(context) — no hardcoded values.",
  presets: [
    {
      name: "Light (Zinc)",
      factory: "FlaiThemeData.light()",
      description:
        "Clean light theme with zinc-based neutral palette. The default theme, inspired by shadcn/ui's zinc color scheme.",
    },
    {
      name: "Dark",
      factory: "FlaiThemeData.dark()",
      description:
        "Dark mode theme with inverted zinc palette. High contrast foreground on dark backgrounds.",
    },
    {
      name: "iOS",
      factory: "FlaiThemeData.ios()",
      description:
        "Apple-style theme with iOS blue accent, rounded corners (sm: 8, md: 12, lg: 18, xl: 22), and system font styling.",
    },
    {
      name: "Premium (Linear-inspired)",
      factory: "FlaiThemeData.premium()",
      description:
        "Premium dark theme inspired by Linear's design system. Subtle gradients and refined spacing for a polished look.",
    },
  ],
  tokens: {
    colors:
      "FlaiColors — background, foreground, card, cardForeground, primary, primaryForeground, secondary, secondaryForeground, muted, mutedForeground, accent, accentForeground, destructive, destructiveForeground, border, input, ring",
    typography:
      "FlaiTypography — bodyBase(), bodySmall(), heading(), label(), mono() methods that return TextStyle",
    radius: "FlaiRadius — sm, md, lg, xl, full (double values for BorderRadius)",
    spacing: "FlaiSpacing — xs, sm, md, lg, xl (double values for padding/margin)",
    icons:
      "FlaiIconData — icon data system with 3 presets: `.material()` (Material Design icons), `.cupertino()` (SF Symbols-style icons), `.sharp()` (sharp-edged icon variants). Access via FlaiTheme.of(context).icons",
  },
  customization: `// Wrap your widget tree with FlaiTheme
FlaiTheme(
  data: FlaiThemeData.dark(),
  child: MaterialApp(home: MyHomePage()),
)

// Custom theme
FlaiTheme(
  data: FlaiThemeData(
    colors: FlaiColors.dark().copyWith(
      primary: Color(0xFF6366F1),
      accent: Color(0xFF8B5CF6),
    ),
    radius: FlaiRadius(sm: 4, md: 8, lg: 12, xl: 16, full: 9999),
  ),
  child: MaterialApp(home: MyHomePage()),
)

// Access tokens in any widget
final theme = FlaiTheme.of(context);
Container(
  color: theme.colors.card,
  padding: EdgeInsets.all(theme.spacing.md),
  child: Text('Hello', style: theme.typography.bodyBase(
    color: theme.colors.foreground,
  )),
)`,
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const CATEGORY_ORDER = [
  CATEGORIES.CHAT_ESSENTIALS,
  CATEGORIES.AI_WIDGETS,
  CATEGORIES.CONVERSATION,
  CATEGORIES.PROVIDERS,
  CATEGORIES.FLOWS,
];

function componentsByCategory(): Record<string, ComponentInfo[]> {
  const grouped: Record<string, ComponentInfo[]> = {};
  for (const cat of CATEGORY_ORDER) {
    grouped[cat] = [];
  }
  for (const comp of Object.values(COMPONENT_REGISTRY)) {
    if (!grouped[comp.category]) {
      grouped[comp.category] = [];
    }
    grouped[comp.category].push(comp);
  }
  return grouped;
}

function formatComponentList(): string {
  const grouped = componentsByCategory();
  const lines: string[] = [
    "# FlAI Components",
    "",
    `${Object.keys(COMPONENT_REGISTRY).length} components available across ${CATEGORY_ORDER.length} categories.`,
    "",
  ];

  for (const category of CATEGORY_ORDER) {
    const components = grouped[category];
    if (!components || components.length === 0) continue;

    lines.push(`## ${category}`);
    lines.push("");
    for (const comp of components) {
      const deps =
        comp.dependencies.length > 0
          ? ` (depends on: ${comp.dependencies.join(", ")})`
          : "";
      const pubDeps =
        comp.pubDependencies.length > 0
          ? ` [pub: ${comp.pubDependencies.join(", ")}]`
          : "";
      lines.push(`- **${comp.name}** — ${comp.description}${deps}${pubDeps}`);
    }
    lines.push("");
  }

  lines.push("---");
  lines.push(
    "Use `add_component` to install any component, or `get_component_info` for detailed API docs."
  );

  return lines.join("\n");
}

function formatComponentInfo(comp: ComponentInfo): string {
  const lines: string[] = [
    `# ${comp.name}`,
    "",
    comp.description,
    "",
    `**Category:** ${comp.category}`,
  ];

  if (comp.dependencies.length > 0) {
    lines.push(
      `**FlAI Dependencies:** ${comp.dependencies.join(", ")} (auto-installed)`
    );
  }

  if (comp.pubDependencies.length > 0) {
    lines.push(
      `**Pub Dependencies:** ${comp.pubDependencies.join(", ")} (auto-added to pubspec.yaml)`
    );
  }

  lines.push("");
  lines.push("## Props");
  lines.push("");
  for (const [prop, desc] of Object.entries(comp.props)) {
    lines.push(`- \`${prop}\`: ${desc}`);
  }

  lines.push("");
  lines.push("## Usage");
  lines.push("");
  lines.push("```dart");
  lines.push(comp.usageExample);
  lines.push("```");

  lines.push("");
  lines.push("## Install");
  lines.push("");
  lines.push("```bash");
  lines.push(`flai add ${comp.name}`);
  lines.push("```");

  return lines.join("\n");
}

async function runFlaiCommand(
  command: string,
  projectPath?: string
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  const cwd = projectPath || process.cwd();
  try {
    const { stdout, stderr } = await execAsync(`flai ${command}`, {
      cwd,
      timeout: 60_000,
    });
    return { stdout, stderr, exitCode: 0 };
  } catch (error: unknown) {
    const execError = error as {
      stdout?: string;
      stderr?: string;
      code?: number;
    };
    return {
      stdout: execError.stdout ?? "",
      stderr: execError.stderr ?? String(error),
      exitCode: execError.code ?? 1,
    };
  }
}

// ---------------------------------------------------------------------------
// MCP Server
// ---------------------------------------------------------------------------

const server = new McpServer({
  name: "flai",
  version: "0.2.0",
});

// ── Tool: list_components ─────────────────────────────────────────────────

server.tool(
  "list_components",
  "Lists all available FlAI components with descriptions and categories. Returns the full component registry grouped by category: Chat Essentials, AI Widgets, Conversation, Providers, and Flows.",
  {},
  async () => {
    return {
      content: [{ type: "text", text: formatComponentList() }],
    };
  }
);

// ── Tool: add_component ───────────────────────────────────────────────────

server.tool(
  "add_component",
  "Installs a FlAI component into a Flutter project. Validates the component exists, resolves dependencies, and runs `flai add <name>`. Installing app_scaffold also auto-generates main.dart with full app wiring. Requires FlAI CLI to be installed and the project to be initialized with `flai init`.",
  {
    component_name: z
      .string()
      .describe("Name of the component to install (e.g., 'message_bubble', 'chat_screen')"),
    project_path: z
      .string()
      .optional()
      .describe(
        "Absolute path to the Flutter project. Defaults to the current working directory."
      ),
  },
  async ({ component_name, project_path }) => {
    // Validate component exists
    const comp = COMPONENT_REGISTRY[component_name];
    if (!comp) {
      const available = Object.keys(COMPONENT_REGISTRY).join(", ");
      return {
        content: [
          {
            type: "text",
            text: `Error: Unknown component "${component_name}".\n\nAvailable components: ${available}`,
          },
        ],
        isError: true,
      };
    }

    // Show what will be installed
    const installPlan: string[] = [
      `Installing: ${comp.name}`,
      `Category: ${comp.category}`,
    ];

    if (comp.dependencies.length > 0) {
      installPlan.push(
        `FlAI dependencies (auto-installed): ${comp.dependencies.join(", ")}`
      );
    }
    if (comp.pubDependencies.length > 0) {
      installPlan.push(
        `Pub dependencies (auto-added): ${comp.pubDependencies.join(", ")}`
      );
    }

    installPlan.push("", "Running `flai add " + component_name + "`...", "");

    // Run the CLI command
    const result = await runFlaiCommand(`add ${component_name}`, project_path);

    if (result.exitCode !== 0) {
      installPlan.push("Installation failed:");
      if (result.stderr) installPlan.push(result.stderr);
      if (result.stdout) installPlan.push(result.stdout);
      installPlan.push(
        "",
        "Troubleshooting:",
        "- Make sure `flai` CLI is installed: `dart pub global activate flai_cli`",
        "- Make sure the project is initialized: run `flai init` first",
        "- Make sure you're in a Flutter project directory (has pubspec.yaml)"
      );
      return {
        content: [{ type: "text", text: installPlan.join("\n") }],
        isError: true,
      };
    }

    installPlan.push("Installation successful!");
    if (result.stdout) installPlan.push("", result.stdout.trim());

    if (component_name === "app_scaffold") {
      installPlan.push(
        "",
        "Note: `app_scaffold` auto-generated main.dart with full app wiring.",
        "Run `flutter run` to launch the app. Use `flai connect cmmd` for production backend."
      );
    }

    return {
      content: [{ type: "text", text: installPlan.join("\n") }],
    };
  }
);

// ── Tool: get_component_info ──────────────────────────────────────────────

server.tool(
  "get_component_info",
  "Gets detailed information about a specific FlAI component including description, category, dependencies, pub dependencies, all props with types, and a usage code example.",
  {
    component_name: z
      .string()
      .describe("Name of the component (e.g., 'message_bubble', 'chat_screen')"),
  },
  async ({ component_name }) => {
    const comp = COMPONENT_REGISTRY[component_name];
    if (!comp) {
      const available = Object.keys(COMPONENT_REGISTRY).join(", ");
      return {
        content: [
          {
            type: "text",
            text: `Error: Unknown component "${component_name}".\n\nAvailable components: ${available}`,
          },
        ],
        isError: true,
      };
    }

    return {
      content: [{ type: "text", text: formatComponentInfo(comp) }],
    };
  }
);

// ── Tool: init_project ────────────────────────────────────────────────────

server.tool(
  "init_project",
  "Initializes FlAI in a Flutter project. Runs `flai init` which interactively prompts for app name, assistant name, and theme preset (dark/light/ios/premium). Creates the core theme system, data models, provider interfaces, and a flai.yaml config file. Use `--no-interactive` with `--app-name`, `--assistant-name`, `--theme` flags for CI/scripting.",
  {
    project_path: z
      .string()
      .optional()
      .describe(
        "Absolute path to the Flutter project. Defaults to the current working directory."
      ),
  },
  async ({ project_path }) => {
    const lines: string[] = [
      "Initializing FlAI...",
      "",
      "This will create:",
      "- lib/flai/core/theme/ — FlaiTheme, FlaiColors, FlaiTypography, FlaiRadius, FlaiSpacing",
      "- lib/flai/core/models/ — Message, Conversation, ChatEvent, ChatRequest, UsageInfo, ToolCall, Citation",
      "- lib/flai/providers/ — AiProvider abstract interface",
      "- lib/flai/flai.dart — barrel export file",
      "- flai.yaml — project config (output_dir, theme, app_name, assistant_name, installed components)",
      "",
      "Interactive prompts:",
      "- App name (displayed in the UI)",
      "- Assistant name (AI assistant's display name)",
      "- Theme preset: dark, light, ios, or premium",
      "",
      "For CI/scripting, use: `flai init --no-interactive --app-name \"My App\" --assistant-name \"Assistant\" --theme dark`",
      "",
      "Running `flai init`...",
      "",
    ];

    const result = await runFlaiCommand("init --no-interactive", project_path);

    if (result.exitCode !== 0) {
      lines.push("Initialization failed:");
      if (result.stderr) lines.push(result.stderr);
      if (result.stdout) lines.push(result.stdout);
      lines.push(
        "",
        "Troubleshooting:",
        "- Make sure `flai` CLI is installed: `dart pub global activate flai_cli`",
        "- Make sure you're in a Flutter project directory (has pubspec.yaml)",
        "- Make sure the lib/ directory exists"
      );
      return {
        content: [{ type: "text", text: lines.join("\n") }],
        isError: true,
      };
    }

    lines.push("Initialization successful!");
    if (result.stdout) lines.push("", result.stdout.trim());
    lines.push(
      "",
      "Next steps:",
      "1. Install the app scaffold for a complete chat app (auto-generates main.dart):",
      "   ```bash",
      "   flai add app_scaffold",
      "   flutter run",
      "   ```",
      "2. Or install individual components: `flai add message_bubble`, `flai add chat_screen`, etc.",
      "3. For production backend: `flai connect cmmd`",
      '4. Use `list_components` to see all available components.'
    );

    return {
      content: [{ type: "text", text: lines.join("\n") }],
    };
  }
);

// ── Tool: doctor ──────────────────────────────────────────────────────────

server.tool(
  "doctor",
  "Checks the health of a FlAI project. Runs `flai doctor` to verify FlAI is properly initialized, check installed components, validate dependencies, and identify any issues.",
  {
    project_path: z
      .string()
      .optional()
      .describe(
        "Absolute path to the Flutter project. Defaults to the current working directory."
      ),
  },
  async ({ project_path }) => {
    const lines: string[] = [
      "Running FlAI health check...",
      "",
    ];

    const result = await runFlaiCommand("doctor", project_path);

    if (result.exitCode !== 0) {
      lines.push("Health check encountered issues:");
      if (result.stdout) lines.push(result.stdout.trim());
      if (result.stderr) lines.push(result.stderr.trim());
      lines.push(
        "",
        "Common fixes:",
        "- Run `flai init` to initialize the project",
        "- Run `flutter pub get` to resolve dependencies",
        "- Make sure `flai` CLI is installed: `dart pub global activate flai_cli`"
      );
      return {
        content: [{ type: "text", text: lines.join("\n") }],
        isError: true,
      };
    }

    lines.push("Health check results:");
    lines.push("");
    if (result.stdout) lines.push(result.stdout.trim());

    return {
      content: [{ type: "text", text: lines.join("\n") }],
    };
  }
);

// ── Tool: get_theme_info ──────────────────────────────────────────────────

server.tool(
  "get_theme_info",
  "Gets detailed theming information for FlAI including the 4 theme presets (Light/Zinc, Dark, iOS, Premium/Linear), all design tokens (colors, typography, radius, spacing), and customization examples. Themes can be set during `flai init` and are stored in flai.yaml.",
  {},
  async () => {
    const lines: string[] = [
      "# FlAI Theme System",
      "",
      THEME_INFO.overview,
      "",
      "## Setting a Theme",
      "",
      "Themes can be selected during project initialization:",
      "- Interactive: `flai init` (prompts for theme choice)",
      "- Non-interactive: `flai init --no-interactive --theme premium`",
      "- The selected theme is stored in `flai.yaml` and used when generating main.dart via `flai add app_scaffold`.",
      "",
      "## Theme Presets",
      "",
    ];

    for (const preset of THEME_INFO.presets) {
      lines.push(`### ${preset.name}`);
      lines.push(`- Factory: \`${preset.factory}\``);
      lines.push(`- ${preset.description}`);
      lines.push("");
    }

    lines.push("## Design Tokens");
    lines.push("");
    for (const [token, desc] of Object.entries(THEME_INFO.tokens)) {
      lines.push(`### ${token}`);
      lines.push(desc);
      lines.push("");
    }

    lines.push("## Customization");
    lines.push("");
    lines.push("```dart");
    lines.push(THEME_INFO.customization);
    lines.push("```");

    return {
      content: [{ type: "text", text: lines.join("\n") }],
    };
  }
);

// ── Tool: scaffold_chat_app ────────────────────────────────────────────────

server.tool(
  "scaffold_chat_app",
  "Explains how to scaffold a complete FlAI chat app. The recommended approach is the 3-command pipeline: `flai init` -> `flai add app_scaffold` -> `flutter run`. The `app_scaffold` brick auto-generates main.dart with full app wiring (auth, onboarding, chat, sidebar, GoRouter). Use `flai connect cmmd` for production backend.",
  {
    provider: z
      .enum(["openai", "anthropic", "cmmd"])
      .default("cmmd")
      .describe("AI provider to use: 'openai', 'anthropic', or 'cmmd' (default: 'cmmd')"),
    theme: z
      .enum(["light", "dark", "ios", "premium"])
      .default("dark")
      .describe("Theme preset to use (default: 'dark')"),
  },
  async ({ provider, theme }) => {
    const themeFactory: Record<string, string> = {
      light: "FlaiThemeData.light()",
      dark: "FlaiThemeData.dark()",
      ios: "FlaiThemeData.ios()",
      premium: "FlaiThemeData.premium()",
    };

    const lines: string[] = [
      `# FlAI Chat App — ${provider} + ${theme} theme`,
      "",
      "## Recommended: 3-Command Pipeline",
      "",
      "`flai add app_scaffold` **auto-generates main.dart** with full app wiring — you do NOT need to write it manually.",
      "",
      "```bash",
      "# 1. Initialize FlAI (creates core theme, models, providers, and flai.yaml)",
      `flai init --no-interactive --theme ${theme}`,
      "",
      "# 2. Install the app scaffold (auto-generates main.dart, installs all flow bricks)",
      "flai add app_scaffold",
      "",
      "# 3. Run the app",
      "flutter run",
      "```",
      "",
    ];

    if (provider === "cmmd") {
      lines.push(
        "## Production Backend (CMMD)",
        "",
        "```bash",
        "# Wire CMMD backend providers (AI, auth, storage, voice)",
        "flai connect cmmd",
        "```",
        "",
        "This generates `CmmdAiProvider`, `CmmdAuthProvider`, `CmmdStorageProvider`, and `CmmdVoiceProvider`",
        "that implement the FlAI provider interfaces against the CMMD API.",
        "",
      );
    } else {
      lines.push(
        `## Adding ${provider === "openai" ? "OpenAI" : "Anthropic"} Provider`,
        "",
        "```bash",
        `flai add ${provider}_provider`,
        "```",
        "",
      );
    }

    lines.push(
      "## What Gets Generated",
      "",
      "The `app_scaffold` brick generates:",
      "- **main.dart** — complete app entry point with FlaiApp root widget",
      "- **FlaiApp** — root widget accepting AppScaffoldConfig with providers and flow configs",
      "- **GoRouter** — navigation with auth redirects between flows",
      "- **HomeController** — bridges providers to chat UI (conversations, messages, streaming)",
      "- **FlaiChatContent** — message list + composer using MessageBubble + FlaiTypingIndicator",
      "- **FlaiHomeScreen** — sidebar drawer + top nav + chat area with empty state",
      "",
      "Dependencies auto-installed: auth_flow, onboarding_flow, chat_experience, sidebar_nav, message_bubble, typing_indicator",
      "",
      `Pub packages auto-added: go_router, flutter_secure_storage, share_plus`,
      "",
      "## Auto-Generated main.dart (for reference)",
      "",
      "The generated main.dart uses the theme selected during `flai init` (stored in flai.yaml).",
      "It wires FlaiApp with MockAuthProvider and InMemoryStorageProvider by default.",
      `To use ${themeFactory[theme]}, either select "${theme}" during \`flai init\` or edit flai.yaml.`,
      "",
      "```dart",
      "// This is auto-generated by `flai add app_scaffold` — you don't write this manually.",
      "// The generated code uses your flai.yaml settings (app_name, assistant_name, theme).",
      "import 'package:flutter/material.dart';",
      "import 'package:your_app/flai/flai.dart';",
      "",
      "void main() {",
      "  runApp(",
      "    FlaiApp(",
      "      config: AppScaffoldConfig(",
      "        providers: FlaiProviders(",
      "          ai: yourAiProvider,       // Implement or use a provider brick",
      "          auth: MockAuthProvider(),  // Default, replace with real auth",
      "          storage: InMemoryStorageProvider(), // Default, replace with real storage",
      "        ),",
      `        theme: ${themeFactory[theme]},`,
      "      ),",
      "    ),",
      "  );",
      "}",
      "```",
    );

    return {
      content: [{ type: "text", text: lines.join("\n") }],
    };
  }
);

// ── Tool: get_starter_template ────────────────────────────────────────────

const STARTER_TEMPLATES: Record<
  string,
  { title: string; description: string; code: string; setup: string }
> = {
  basic_chat: {
    title: "Basic Chat",
    description:
      "Minimal chat app with a single provider and default settings.",
    setup: `flai init
flai add chat_screen
flai add openai_provider`,
    code: `import 'package:flutter/material.dart';
import 'package:your_app/flai/flai.dart';
import 'package:your_app/flai/providers/openai_provider.dart';

void main() => runApp(const BasicChatApp());

class BasicChatApp extends StatelessWidget {
  const BasicChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlaiTheme(
      data: FlaiThemeData.dark(),
      child: MaterialApp(
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
        title: 'Chat',
      ),
    );
  }
}`,
  },

  multi_model: {
    title: "Multi-Model Chat",
    description:
      "Chat app with a model selector that switches between OpenAI and Anthropic providers at runtime.",
    setup: `flai init
flai add chat_screen
flai add model_selector
flai add openai_provider
flai add anthropic_provider`,
    code: `import 'package:flutter/material.dart';
import 'package:your_app/flai/flai.dart';
import 'package:your_app/flai/providers/openai_provider.dart';
import 'package:your_app/flai/providers/anthropic_provider.dart';

void main() => runApp(const MultiModelApp());

class MultiModelApp extends StatelessWidget {
  const MultiModelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlaiTheme(
      data: FlaiThemeData.dark(),
      child: MaterialApp(home: const MultiModelChat()),
    );
  }
}

class MultiModelChat extends StatefulWidget {
  const MultiModelChat({super.key});

  @override
  State<MultiModelChat> createState() => _MultiModelChatState();
}

class _MultiModelChatState extends State<MultiModelChat> {
  late ChatScreenController _controller;
  String _selectedModelId = 'gpt-4o';

  final _models = [
    FlaiModelOption(
      id: 'gpt-4o',
      name: 'GPT-4o',
      provider: 'OpenAI',
      contextWindow: 128000,
      capabilities: ['vision', 'tool_use'],
    ),
    FlaiModelOption(
      id: 'claude-sonnet-4-20250514',
      name: 'Claude Sonnet 4',
      provider: 'Anthropic',
      contextWindow: 200000,
      capabilities: ['vision', 'tool_use', 'thinking'],
    ),
  ];

  AiProvider _providerFor(String modelId) {
    if (modelId.startsWith('claude')) {
      return AnthropicProvider(
        apiKey: const String.fromEnvironment('ANTHROPIC_API_KEY'),
        model: modelId,
      );
    }
    return OpenAiProvider(
      apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
      model: modelId,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = ChatScreenController(
      provider: _providerFor(_selectedModelId),
    );
  }

  void _onModelSelected(FlaiModelOption model) {
    setState(() {
      _selectedModelId = model.id;
      _controller.dispose();
      _controller = ChatScreenController(
        provider: _providerFor(model.id),
      );
    });
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
        title: 'Multi-Model Chat',
        actions: [
          FlaiModelSelector(
            models: _models,
            selectedModelId: _selectedModelId,
            onSelect: _onModelSelected,
          ),
        ],
      ),
    );
  }
}`,
  },

  tool_calling: {
    title: "Tool Calling",
    description:
      "Chat app that demonstrates tool use / function calling with AI, including a weather tool example.",
    setup: `flai init
flai add chat_screen
flai add tool_call_card
flai add openai_provider`,
    code: `import 'package:flutter/material.dart';
import 'package:your_app/flai/flai.dart';
import 'package:your_app/flai/providers/openai_provider.dart';

void main() => runApp(const ToolCallingApp());

class ToolCallingApp extends StatelessWidget {
  const ToolCallingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlaiTheme(
      data: FlaiThemeData.dark(),
      child: MaterialApp(home: const ToolCallingChat()),
    );
  }
}

class ToolCallingChat extends StatefulWidget {
  const ToolCallingChat({super.key});

  @override
  State<ToolCallingChat> createState() => _ToolCallingChatState();
}

class _ToolCallingChatState extends State<ToolCallingChat> {
  late final ChatScreenController _controller;

  // Define tools the AI can call
  final _tools = [
    ToolDefinition(
      name: 'get_weather',
      description: 'Get current weather for a city',
      parameters: {
        'type': 'object',
        'properties': {
          'city': {
            'type': 'string',
            'description': 'City name',
          },
        },
        'required': ['city'],
      },
    ),
  ];

  // Handle tool calls from the AI
  Future<String> _handleToolCall(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'get_weather':
        final city = args['city'] as String;
        // Replace with real API call
        return '{"city": "\$city", "temp": 22, "condition": "sunny"}';
      default:
        return '{"error": "Unknown tool: \$name"}';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = ChatScreenController(
      provider: OpenAiProvider(
        apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
        model: 'gpt-4o',
      ),
      tools: _tools,
      onToolCall: _handleToolCall,
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
        title: 'Tool Calling Demo',
        subtitle: 'Try: "What\\'s the weather in Tokyo?"',
      ),
    );
  }
}`,
  },

  custom_theme: {
    title: "Custom Theme",
    description:
      "Demonstrates custom theming with brand colors, custom typography, and a theme toggle between light and dark modes.",
    setup: `flai init
flai add chat_screen
flai add openai_provider`,
    code: `import 'package:flutter/material.dart';
import 'package:your_app/flai/flai.dart';
import 'package:your_app/flai/providers/openai_provider.dart';

void main() => runApp(const CustomThemeApp());

// Define brand colors
class BrandColors {
  static const indigo = Color(0xFF6366F1);
  static const violet = Color(0xFF8B5CF6);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
}

// Custom light theme
final brandLight = FlaiThemeData(
  colors: FlaiColors.light().copyWith(
    primary: BrandColors.indigo,
    primaryForeground: Colors.white,
    accent: BrandColors.violet,
    userBubble: BrandColors.indigo,
    userBubbleForeground: Colors.white,
  ),
  typography: FlaiTypography(
    fontFamily: 'Inter',
    monoFontFamily: 'JetBrains Mono',
  ),
  radius: const FlaiRadius(sm: 6, md: 10, lg: 16, xl: 24, full: 9999),
  spacing: const FlaiSpacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32),
);

// Custom dark theme
final brandDark = FlaiThemeData(
  colors: FlaiColors.dark().copyWith(
    background: BrandColors.slate900,
    card: BrandColors.slate800,
    primary: BrandColors.indigo,
    primaryForeground: Colors.white,
    accent: BrandColors.violet,
    userBubble: BrandColors.indigo,
    userBubbleForeground: Colors.white,
  ),
  typography: FlaiTypography(
    fontFamily: 'Inter',
    monoFontFamily: 'JetBrains Mono',
  ),
  radius: const FlaiRadius(sm: 6, md: 10, lg: 16, xl: 24, full: 9999),
  spacing: const FlaiSpacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32),
);

class CustomThemeApp extends StatefulWidget {
  const CustomThemeApp({super.key});

  @override
  State<CustomThemeApp> createState() => _CustomThemeAppState();
}

class _CustomThemeAppState extends State<CustomThemeApp> {
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    return FlaiTheme(
      data: _isDark ? brandDark : brandLight,
      child: MaterialApp(
        theme: _isDark ? ThemeData.dark() : ThemeData.light(),
        home: ChatPage(
          isDark: _isDark,
          onToggleTheme: () => setState(() => _isDark = !_isDark),
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

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
        title: 'Branded Chat',
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
    );
  }
}`,
  },
};

server.tool(
  "get_starter_template",
  "Returns complete starter code for common FlAI patterns: basic_chat (minimal setup), multi_model (model switching), tool_calling (function calling), custom_theme (brand theming with light/dark toggle).",
  {
    template: z
      .enum(["basic_chat", "multi_model", "tool_calling", "custom_theme"])
      .describe("Template to generate: 'basic_chat', 'multi_model', 'tool_calling', or 'custom_theme'"),
  },
  async ({ template }) => {
    const tmpl = STARTER_TEMPLATES[template];
    if (!tmpl) {
      return {
        content: [
          {
            type: "text",
            text: `Error: Unknown template "${template}". Available: ${Object.keys(STARTER_TEMPLATES).join(", ")}`,
          },
        ],
        isError: true,
      };
    }

    const lines: string[] = [
      `# ${tmpl.title} Starter Template`,
      "",
      tmpl.description,
      "",
      "## Setup",
      "",
      "```bash",
      tmpl.setup,
      "```",
      "",
      "## Code",
      "",
      "```dart",
      tmpl.code,
      "```",
    ];

    return {
      content: [{ type: "text", text: lines.join("\n") }],
    };
  }
);

// ---------------------------------------------------------------------------
// Start Server
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error: unknown) => {
  console.error("FlAI MCP server failed to start:", error);
  process.exit(1);
});
