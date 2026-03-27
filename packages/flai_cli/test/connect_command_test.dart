import 'package:flai_cli/commands/connect_command.dart';
import 'package:test/test.dart';

void main() {
  group('ConnectCommand', () {
    late ConnectCommand command;

    setUp(() {
      command = ConnectCommand();
    });

    test('has correct name', () {
      expect(command.name, equals('connect'));
    });

    test('has correct description', () {
      expect(command.description, equals('Connect FlAI to a backend (hidden)'));
    });

    test('is hidden', () {
      expect(command.hidden, isTrue);
    });
  });
}
