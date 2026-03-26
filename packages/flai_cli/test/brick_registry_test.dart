import 'package:flai_cli/brick_registry.dart';
import 'package:test/test.dart';

void main() {
  group('BrickRegistry', () {
    test('contains exactly 15 components', () {
      expect(BrickRegistry.components, hasLength(15));
    });

    test('allComponents keys match their BrickInfo names', () {
      for (final entry in BrickRegistry.components.entries) {
        expect(entry.value.name, equals(entry.key));
      }
    });

    group('lookup', () {
      test('returns correct BrickInfo for a known component', () {
        final info = BrickRegistry.lookup('chat_screen');
        expect(info, isNotNull);
        expect(info!.name, equals('chat_screen'));
      });

      test('returns null for an unknown component', () {
        expect(BrickRegistry.lookup('nonexistent_widget'), isNull);
      });

      test('returns null for empty string', () {
        expect(BrickRegistry.lookup(''), isNull);
      });
    });

    group('categories', () {
      test('returns 4 categories in display order', () {
        expect(BrickRegistry.categories, hasLength(4));
        expect(BrickRegistry.categories, [
          BrickCategory.chatEssentials,
          BrickCategory.aiWidgets,
          BrickCategory.conversation,
          BrickCategory.providers,
        ]);
      });

      test('every component belongs to a known category', () {
        final validCategories = BrickRegistry.categories.toSet();
        for (final brick in BrickRegistry.components.values) {
          expect(
            validCategories,
            contains(brick.category),
            reason: '${brick.name} has unknown category "${brick.category}"',
          );
        }
      });
    });

    group('byCategory', () {
      test('Chat Essentials contains 5 components', () {
        final bricks = BrickRegistry.byCategory(BrickCategory.chatEssentials);
        expect(bricks, hasLength(5));
        final names = bricks.map((b) => b.name).toSet();
        expect(
          names,
          containsAll([
            'chat_screen',
            'message_bubble',
            'input_bar',
            'streaming_text',
            'typing_indicator',
          ]),
        );
      });

      test('AI Widgets contains 5 components', () {
        final bricks = BrickRegistry.byCategory(BrickCategory.aiWidgets);
        expect(bricks, hasLength(5));
        final names = bricks.map((b) => b.name).toSet();
        expect(
          names,
          containsAll([
            'tool_call_card',
            'code_block',
            'thinking_indicator',
            'citation_card',
            'image_preview',
          ]),
        );
      });

      test('Conversation contains 3 components', () {
        final bricks = BrickRegistry.byCategory(BrickCategory.conversation);
        expect(bricks, hasLength(3));
        final names = bricks.map((b) => b.name).toSet();
        expect(
          names,
          containsAll(['conversation_list', 'model_selector', 'token_usage']),
        );
      });

      test('Providers contains 2 components', () {
        final bricks = BrickRegistry.byCategory(BrickCategory.providers);
        expect(bricks, hasLength(2));
        final names = bricks.map((b) => b.name).toSet();
        expect(names, containsAll(['openai_provider', 'anthropic_provider']));
      });

      test('returns empty list for unknown category', () {
        expect(BrickRegistry.byCategory('Unknown'), isEmpty);
      });
    });

    group('pub dependencies', () {
      test('message_bubble depends on flutter_markdown', () {
        final info = BrickRegistry.lookup('message_bubble')!;
        expect(info.pubDependencies, contains('flutter_markdown'));
      });

      test('code_block depends on flutter_highlight', () {
        final info = BrickRegistry.lookup('code_block')!;
        expect(info.pubDependencies, contains('flutter_highlight'));
      });

      test('openai_provider depends on http', () {
        final info = BrickRegistry.lookup('openai_provider')!;
        expect(info.pubDependencies, contains('http'));
      });

      test('anthropic_provider depends on http', () {
        final info = BrickRegistry.lookup('anthropic_provider')!;
        expect(info.pubDependencies, contains('http'));
      });

      test('typing_indicator has no pub dependencies', () {
        final info = BrickRegistry.lookup('typing_indicator')!;
        expect(info.pubDependencies, isEmpty);
      });
    });

    group('component dependencies', () {
      test(
        'chat_screen depends on message_bubble, input_bar, streaming_text',
        () {
          final info = BrickRegistry.lookup('chat_screen')!;
          expect(
            info.dependencies,
            unorderedEquals(['message_bubble', 'input_bar', 'streaming_text']),
          );
        },
      );

      test('typing_indicator has no component dependencies', () {
        final info = BrickRegistry.lookup('typing_indicator')!;
        expect(info.dependencies, isEmpty);
      });

      test('input_bar has no component dependencies', () {
        final info = BrickRegistry.lookup('input_bar')!;
        expect(info.dependencies, isEmpty);
      });
    });

    group('descriptions', () {
      test('every component has a non-empty description', () {
        for (final brick in BrickRegistry.components.values) {
          expect(
            brick.description,
            isNotEmpty,
            reason: '${brick.name} has an empty description',
          );
        }
      });
    });
  });

  group('BrickCategory', () {
    test('chatEssentials value', () {
      expect(BrickCategory.chatEssentials, equals('Chat Essentials'));
    });

    test('aiWidgets value', () {
      expect(BrickCategory.aiWidgets, equals('AI Widgets'));
    });

    test('conversation value', () {
      expect(BrickCategory.conversation, equals('Conversation'));
    });

    test('providers value', () {
      expect(BrickCategory.providers, equals('Providers'));
    });
  });
}
