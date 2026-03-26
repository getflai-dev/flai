import 'package:flutter/material.dart';
import '../flai/flai.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/mock_message_bubble.dart';
import '../widgets/mock_code_block.dart';
import '../widgets/mock_typing_indicator.dart';

class ComponentGalleryScreen extends StatelessWidget {
  final String currentTheme;
  final ValueChanged<String> onThemeChanged;

  const ComponentGalleryScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + theme.spacing.md,
              left: theme.spacing.md,
              right: theme.spacing.md,
              bottom: theme.spacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colors.card,
              border: Border(bottom: BorderSide(color: theme.colors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Component Gallery',
                  style: theme.typography.headingLarge(
                    color: theme.colors.foreground,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  'All FlAI components with live theme switching',
                  style: theme.typography.bodyBase(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                SizedBox(height: theme.spacing.md),
                ThemeSwitcher(
                  currentTheme: currentTheme,
                  onThemeChanged: onThemeChanged,
                ),
              ],
            ),
          ),
        ),

        // Sections
        SliverPadding(
          padding: EdgeInsets.all(theme.spacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionHeader(title: 'Message Bubbles', theme: theme),
              _buildMessageBubbles(theme),
              SizedBox(height: theme.spacing.xl),

              _SectionHeader(title: 'Typing Indicator', theme: theme),
              const MockTypingIndicator(),
              SizedBox(height: theme.spacing.xl),

              _SectionHeader(title: 'Code Block', theme: theme),
              const MockCodeBlock(
                language: 'dart',
                code: '''import 'package:flai/flai.dart';

void main() {
  runApp(
    FlaiTheme(
      data: FlaiThemeData.dark(),
      child: const MyApp(),
    ),
  );
}''',
              ),
              SizedBox(height: theme.spacing.xl),

              _SectionHeader(title: 'Tool Call Card', theme: theme),
              _buildToolCallCard(theme),
              SizedBox(height: theme.spacing.xl),

              _SectionHeader(title: 'Thinking Indicator', theme: theme),
              _buildThinkingMessage(theme),
              SizedBox(height: theme.spacing.xl),

              _SectionHeader(title: 'Citation Card', theme: theme),
              _buildCitationMessage(theme),
              SizedBox(height: theme.spacing.xl),

              _SectionHeader(title: 'Model Selector', theme: theme),
              _buildModelSelector(theme),
              SizedBox(height: theme.spacing.xl),

              _SectionHeader(title: 'Token Usage', theme: theme),
              _buildTokenUsage(theme),
              SizedBox(height: theme.spacing.xl),

              _SectionHeader(title: 'Conversation List', theme: theme),
              _buildConversationList(theme),
              SizedBox(height: theme.spacing.xxl),

              _SectionHeader(title: 'Color Palette', theme: theme),
              _buildColorPalette(theme),
              SizedBox(height: theme.spacing.xxl),

              _SectionHeader(title: 'Typography', theme: theme),
              _buildTypographyShowcase(theme),
              SizedBox(height: theme.spacing.xxl + theme.spacing.xl),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubbles(FlaiThemeData theme) {
    final now = DateTime.now();
    return Column(
      children: [
        MockMessageBubble(
          message: Message(
            id: 'g1',
            role: MessageRole.user,
            content: 'What is the meaning of life?',
            timestamp: now,
          ),
        ),
        MockMessageBubble(
          message: Message(
            id: 'g2',
            role: MessageRole.assistant,
            content:
                'That\'s a profound question! The meaning of life varies by perspective — philosophers, scientists, and spiritual traditions each offer unique answers.',
            timestamp: now,
          ),
        ),
        MockMessageBubble(
          message: Message(
            id: 'g3',
            role: MessageRole.system,
            content: 'You are a helpful AI assistant.',
            timestamp: now,
          ),
        ),
      ],
    );
  }

  Widget _buildToolCallCard(FlaiThemeData theme) {
    final now = DateTime.now();
    return MockMessageBubble(
      message: Message(
        id: 'tc',
        role: MessageRole.assistant,
        content: 'I found the weather information for you.',
        timestamp: now,
        toolCalls: const [
          ToolCall(
            id: 'tc1',
            name: 'get_weather',
            arguments: '{"city": "San Francisco"}',
            result: '{"temp": 18, "condition": "sunny"}',
            isComplete: true,
          ),
          ToolCall(
            id: 'tc2',
            name: 'search_restaurants',
            arguments: '{"query": "lunch near me"}',
            isComplete: false,
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingMessage(FlaiThemeData theme) {
    final now = DateTime.now();
    return MockMessageBubble(
      message: Message(
        id: 'th',
        role: MessageRole.assistant,
        content:
            'Based on my analysis, I recommend using a microservices architecture for this project.',
        timestamp: now,
        thinkingContent:
            'The user is asking about architecture choices. Let me consider the trade-offs between monolithic and microservices approaches. Given the scale requirements mentioned earlier, microservices would provide better scalability and independent deployment...',
      ),
    );
  }

  Widget _buildCitationMessage(FlaiThemeData theme) {
    final now = DateTime.now();
    return MockMessageBubble(
      message: Message(
        id: 'ci',
        role: MessageRole.assistant,
        content:
            'According to recent research, Flutter is now used by over 1 million apps on the Play Store.',
        timestamp: now,
        citations: const [
          Citation(
            title: 'Flutter Growth Report 2025',
            url: 'https://flutter.dev/report',
            snippet: 'Flutter adoption has grown 45% year-over-year...',
          ),
          Citation(
            title: 'Google I/O Flutter Update',
            url: 'https://io.google/flutter',
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector(FlaiThemeData theme) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.sm),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Model',
            style: theme.typography.bodySmall(
              color: theme.colors.mutedForeground,
            ),
          ),
          SizedBox(height: theme.spacing.sm),
          _ModelOption(
            name: 'Claude 3.5 Sonnet',
            description: 'Best for most tasks',
            isSelected: true,
            theme: theme,
          ),
          _ModelOption(
            name: 'GPT-4o',
            description: 'Fast and capable',
            isSelected: false,
            theme: theme,
          ),
          _ModelOption(
            name: 'Claude 3 Opus',
            description: 'Most capable, slower',
            isSelected: false,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildTokenUsage(FlaiThemeData theme) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TokenStat(label: 'Input', value: '1,245', theme: theme),
          ),
          Container(width: 1, height: 40, color: theme.colors.border),
          Expanded(
            child: _TokenStat(label: 'Output', value: '832', theme: theme),
          ),
          Container(width: 1, height: 40, color: theme.colors.border),
          Expanded(
            child: _TokenStat(label: 'Cost', value: '\$0.003', theme: theme),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(FlaiThemeData theme) {
    final conversations = [
      ('REST API in Dart', '2 min ago', 'You: How do I add middleware?'),
      ('Flutter state management', '1 hour ago', 'Riverpod is recommended...'),
      ('Database design', 'Yesterday', 'For your schema, I suggest...'),
      ('Deploy to Cloud Run', '2 days ago', 'You: What about scaling?'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        children: conversations.asMap().entries.map((entry) {
          final i = entry.key;
          final (title, time, preview) = entry.value;
          return Container(
            padding: EdgeInsets.all(theme.spacing.sm + 2),
            decoration: BoxDecoration(
              border: i < conversations.length - 1
                  ? Border(bottom: BorderSide(color: theme.colors.border))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: theme.colors.mutedForeground,
                ),
                SizedBox(width: theme.spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.typography.bodyBase(
                          color: theme.colors.foreground,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        preview,
                        style: theme.typography.bodySmall(
                          color: theme.colors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: theme.typography.bodySmall(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorPalette(FlaiThemeData theme) {
    final colors = [
      ('background', theme.colors.background),
      ('foreground', theme.colors.foreground),
      ('primary', theme.colors.primary),
      ('secondary', theme.colors.secondary),
      ('muted', theme.colors.muted),
      ('accent', theme.colors.accent),
      ('destructive', theme.colors.destructive),
      ('border', theme.colors.border),
      ('userBubble', theme.colors.userBubble),
      ('assistantBubble', theme.colors.assistantBubble),
    ];

    return Wrap(
      spacing: theme.spacing.sm,
      runSpacing: theme.spacing.sm,
      children: colors.map((c) {
        final (name, color) = c;
        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(theme.radius.md),
                border: Border.all(color: theme.colors.border),
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              name,
              style: theme.typography.bodySmall(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTypographyShowcase(FlaiThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heading Large',
          style: theme.typography.headingLarge(color: theme.colors.foreground),
        ),
        SizedBox(height: theme.spacing.sm),
        Text(
          'Heading',
          style: theme.typography.heading(color: theme.colors.foreground),
        ),
        SizedBox(height: theme.spacing.sm),
        Text(
          'Body Large — The quick brown fox jumps over the lazy dog.',
          style: theme.typography.bodyLarge(color: theme.colors.foreground),
        ),
        SizedBox(height: theme.spacing.sm),
        Text(
          'Body Base — The quick brown fox jumps over the lazy dog.',
          style: theme.typography.bodyBase(color: theme.colors.foreground),
        ),
        SizedBox(height: theme.spacing.sm),
        Text(
          'Body Small — The quick brown fox jumps over the lazy dog.',
          style: theme.typography.bodySmall(
            color: theme.colors.mutedForeground,
          ),
        ),
        SizedBox(height: theme.spacing.sm),
        Text(
          'const hello = "world"; // Monospace',
          style: theme.typography.mono(color: theme.colors.foreground),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final FlaiThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.sm),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: theme.spacing.sm),
          Text(
            title,
            style: theme.typography.heading(color: theme.colors.foreground),
          ),
        ],
      ),
    );
  }
}

class _ModelOption extends StatelessWidget {
  final String name;
  final String description;
  final bool isSelected;
  final FlaiThemeData theme;

  const _ModelOption({
    required this.name,
    required this.description,
    required this.isSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: theme.spacing.xs),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: theme.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(
          color: isSelected ? theme.colors.primary : theme.colors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected
                ? theme.colors.primary
                : theme.colors.mutedForeground,
          ),
          SizedBox(width: theme.spacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.typography.bodyBase(
                  color: theme.colors.foreground,
                ),
              ),
              Text(
                description,
                style: theme.typography.bodySmall(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TokenStat extends StatelessWidget {
  final String label;
  final String value;
  final FlaiThemeData theme;

  const _TokenStat({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: theme.typography.heading(color: theme.colors.foreground),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: theme.typography.bodySmall(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
