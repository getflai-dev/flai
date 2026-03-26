import 'package:args/command_runner.dart';

import 'commands/add_command.dart';
import 'commands/doctor_command.dart';
import 'commands/init_command.dart';
import 'commands/list_command.dart';

/// Top-level command runner for the FlAI CLI.
class FlaiCommandRunner extends CommandRunner<int> {
  FlaiCommandRunner()
    : super(
        'flai',
        'CLI tool for installing FlAI AI chat components into Flutter projects.',
      ) {
    addCommand(InitCommand());
    addCommand(AddCommand());
    addCommand(ListCommand());
    addCommand(DoctorCommand());
  }
}
