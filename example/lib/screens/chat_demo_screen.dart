import 'package:flutter/material.dart';
import '../flai/flai.dart';
import '../widgets/mock_message_bubble.dart';
import '../widgets/mock_input_bar.dart';
import '../widgets/mock_typing_indicator.dart';
import '../widgets/theme_switcher.dart';

class ChatDemoScreen extends StatefulWidget {
  final String currentTheme;
  final ValueChanged<String> onThemeChanged;

  const ChatDemoScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<ChatDemoScreen> createState() => _ChatDemoScreenState();
}

class _ChatDemoScreenState extends State<ChatDemoScreen> {
  final _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadSampleConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSampleConversation() {
    final now = DateTime.now();
    _messages.addAll([
      Message(
        id: '1',
        role: MessageRole.user,
        content: 'Can you help me build a REST API in Dart?',
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
      Message(
        id: '2',
        role: MessageRole.assistant,
        content:
            'Of course! I\'d recommend using the shelf package — it\'s the most popular HTTP server framework for Dart. Let me show you a basic setup.',
        timestamp: now.subtract(const Duration(minutes: 4, seconds: 45)),
        thinkingContent:
            'The user wants to build a REST API in Dart. I should recommend shelf as it\'s the standard choice. I\'ll provide a simple example with routing.',
      ),
      Message(
        id: '3',
        role: MessageRole.assistant,
        content:
            'Here\'s a simple shelf server with a health check endpoint. You can extend this with shelf_router for more complex routing.',
        timestamp: now.subtract(const Duration(minutes: 4, seconds: 30)),
        toolCalls: [
          const ToolCall(
            id: 'tc1',
            name: 'search_docs',
            arguments: '{"query": "shelf dart http server"}',
            result: 'Found shelf package documentation',
            isComplete: true,
          ),
        ],
        citations: [
          const Citation(
            title: 'shelf | Dart Package',
            url: 'https://pub.dev/packages/shelf',
          ),
          const Citation(
            title: 'shelf_router | Dart Package',
            url: 'https://pub.dev/packages/shelf_router',
          ),
        ],
      ),
      Message(
        id: '4',
        role: MessageRole.user,
        content:
            'That looks great! How do I add middleware for authentication?',
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
      Message(
        id: '5',
        role: MessageRole.assistant,
        content:
            'You can create a middleware function that checks the Authorization header. Shelf uses a pipeline pattern where you chain middleware together before your handler.',
        timestamp: now.subtract(const Duration(minutes: 2, seconds: 45)),
      ),
    ]);
  }

  void _handleSend(String text) {
    setState(() {
      _messages.add(
        Message(
          id: 'u${_messages.length}',
          role: MessageRole.user,
          content: text,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            Message(
              id: 'a${_messages.length}',
              role: MessageRole.assistant,
              content:
                  'That\'s a great question! Let me think about the best approach for your use case. In general, I\'d suggest starting with the simplest solution that meets your requirements.',
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Column(
      children: [
        // App bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + theme.spacing.sm,
            left: theme.spacing.md,
            right: theme.spacing.md,
            bottom: theme.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colors.card,
            border: Border(bottom: BorderSide(color: theme.colors.border)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colors.primary,
                      borderRadius: BorderRadius.circular(theme.radius.full),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: theme.colors.primaryForeground,
                    ),
                  ),
                  SizedBox(width: theme.spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FlAI Chat',
                          style: theme.typography.bodyBase(
                            color: theme.colors.foreground,
                          ),
                        ),
                        Text(
                          'Claude 3.5 Sonnet',
                          style: theme.typography.bodySmall(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Token usage mock
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.spacing.sm,
                      vertical: theme.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      borderRadius: BorderRadius.circular(theme.radius.full),
                    ),
                    child: Text(
                      '1,245 tokens',
                      style: theme.typography.bodySmall(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: theme.spacing.sm),
              ThemeSwitcher(
                currentTheme: widget.currentTheme,
                onThemeChanged: widget.onThemeChanged,
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isTyping) {
                return const MockTypingIndicator();
              }
              return MockMessageBubble(message: _messages[index]);
            },
          ),
        ),

        // Input bar
        MockInputBar(onSend: _handleSend),
      ],
    );
  }
}
