import 'package:flai_cli/commands/init_command.dart';
import 'package:test/test.dart';

void main() {
  group('InitCommand', () {
    late InitCommand command;

    setUp(() {
      command = InitCommand();
    });

    test('has correct name', () {
      expect(command.name, equals('init'));
    });

    test('has non-empty description', () {
      expect(command.description, isNotEmpty);
    });

    test('description mentions initializing FlAI', () {
      expect(command.description.toLowerCase(), contains('initialize'));
    });

    group('argument parser', () {
      test('has --output-dir option with -o abbreviation', () {
        final option = command.argParser.options['output-dir'];
        expect(option, isNotNull);
        expect(option!.abbr, equals('o'));
        expect(option.defaultsTo, equals('flai'));
      });

      test('has --theme option with -t abbreviation', () {
        final option = command.argParser.options['theme'];
        expect(option, isNotNull);
        expect(option!.abbr, equals('t'));
        expect(option.allowed, containsAll(['dark', 'light', 'ios', 'premium']));
      });
    });
  });
}
