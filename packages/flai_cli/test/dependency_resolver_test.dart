import 'package:flai_cli/dependency_resolver.dart';
import 'package:test/test.dart';

void main() {
  late DependencyResolver resolver;

  setUp(() {
    resolver = const DependencyResolver();
  });

  group('DependencyResolver', () {
    group('resolve', () {
      test('resolves a component with no dependencies', () {
        final result = resolver.resolve('typing_indicator');
        expect(result, equals(['typing_indicator']));
      });

      test('resolves transitive dependencies for chat_screen', () {
        final result = resolver.resolve('chat_screen');
        // chat_screen depends on message_bubble, input_bar, streaming_text
        // All deps should come before chat_screen itself.
        expect(result, contains('message_bubble'));
        expect(result, contains('input_bar'));
        expect(result, contains('streaming_text'));
        expect(result, contains('chat_screen'));

        // Dependencies must appear before chat_screen in the list.
        final chatScreenIndex = result.indexOf('chat_screen');
        expect(result.indexOf('message_bubble'), lessThan(chatScreenIndex));
        expect(result.indexOf('input_bar'), lessThan(chatScreenIndex));
        expect(result.indexOf('streaming_text'), lessThan(chatScreenIndex));
      });

      test('resolves exactly 4 items for chat_screen (3 deps + itself)', () {
        final result = resolver.resolve('chat_screen');
        expect(result, hasLength(4));
      });

      test('excludes already-installed components', () {
        final result = resolver.resolve(
          'chat_screen',
          alreadyInstalled: {'message_bubble', 'input_bar'},
        );
        expect(result, isNot(contains('message_bubble')));
        expect(result, isNot(contains('input_bar')));
        expect(result, contains('streaming_text'));
        expect(result, contains('chat_screen'));
      });

      test('returns empty list when component is already installed', () {
        final result = resolver.resolve(
          'typing_indicator',
          alreadyInstalled: {'typing_indicator'},
        );
        expect(result, isEmpty);
      });

      test(
        'returns empty list when component and all deps already installed',
        () {
          final result = resolver.resolve(
            'chat_screen',
            alreadyInstalled: {
              'chat_screen',
              'message_bubble',
              'input_bar',
              'streaming_text',
            },
          );
          expect(result, isEmpty);
        },
      );

      test('throws ArgumentError for unknown component', () {
        expect(
          () => resolver.resolve('nonexistent_widget'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Unknown component'),
            ),
          ),
        );
      });

      test('does not duplicate components in the result', () {
        final result = resolver.resolve('chat_screen');
        expect(
          result.toSet().length,
          equals(result.length),
          reason: 'Result should not contain duplicate entries',
        );
      });
    });

    group('collectPubDependencies', () {
      test('collects pub dependencies from a single component', () {
        final deps = resolver.collectPubDependencies(['message_bubble']);
        expect(deps, contains('flutter_markdown'));
      });

      test('collects pub dependencies from multiple components', () {
        final deps = resolver.collectPubDependencies([
          'message_bubble',
          'code_block',
          'openai_provider',
        ]);
        expect(
          deps,
          containsAll(['flutter_markdown', 'flutter_highlight', 'http']),
        );
      });

      test('deduplicates pub dependencies', () {
        // Both providers depend on 'http'.
        final deps = resolver.collectPubDependencies([
          'openai_provider',
          'anthropic_provider',
        ]);
        final httpCount = deps.where((d) => d == 'http').length;
        expect(httpCount, equals(1));
      });

      test('returns empty list for components with no pub deps', () {
        final deps = resolver.collectPubDependencies([
          'typing_indicator',
          'input_bar',
        ]);
        expect(deps, isEmpty);
      });

      test('collects full resolved set of pub deps for chat_screen', () {
        // Resolve chat_screen, then collect pub deps from the result.
        final resolved = resolver.resolve('chat_screen');
        final deps = resolver.collectPubDependencies(resolved);
        // message_bubble requires flutter_markdown; others have no pub deps.
        expect(deps, contains('flutter_markdown'));
      });

      test('ignores unknown component names gracefully', () {
        // collectPubDependencies checks BrickRegistry.lookup which returns null
        // for unknown names; the method skips nulls.
        final deps = resolver.collectPubDependencies(['nonexistent_widget']);
        expect(deps, isEmpty);
      });

      test('returns empty list for empty input', () {
        final deps = resolver.collectPubDependencies([]);
        expect(deps, isEmpty);
      });
    });
  });
}
