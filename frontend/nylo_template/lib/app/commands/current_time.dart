import 'package:intl/intl.dart';
import 'package:nylo_framework/metro/ny_cli.dart';

void main(arguments) => _CurrentTimeCommand(arguments).run();

/// Current Time Command
///
/// Usage:
///   [From Terminal] dart run nylo_framework:main app:current_time
///   [With Metro]    metro app:current_time
class _CurrentTimeCommand extends NyCustomCommand {
  _CurrentTimeCommand(super.arguments);

  @override
  CommandBuilder builder(CommandBuilder command) {
    command.addOption('format', defaultValue: 'HH:mm:ss');
    return command;
  }

  @override
  Future<void> handle(CommandResult result) async {
    final format = result.getString("format");

    // Get the current time
    final now = DateTime.now();
    final DateFormat dateFormat = DateFormat(format);

    // Format the current time
    final formattedTime = dateFormat.format(now);
    info("The current time is " + formattedTime);
  }
}
