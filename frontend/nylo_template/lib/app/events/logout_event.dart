import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';
import '/resources/helpers/loading.dart';

class LogoutEvent implements NyEvent {
  @override
  final listeners = {
    DefaultListener: DefaultListener(),
  };
}

class DefaultListener extends NyListener {
  @override
  handle(dynamic event) async {
    await LoadingOverlay.show(message: 'Signing out...');
    try {
      await Auth.logout();
      // Clear any locally stored app-specific keys
      try {
        await Keys.caregiverName.save(null);
        await Keys.selectedBabyId.save(null);
      } catch (_) {}

      routeToInitial();
    } finally {
      LoadingOverlay.hide();
    }
  }
}


