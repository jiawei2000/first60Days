import 'package:flutter/widgets.dart';
import '/app/controllers/controller.dart';
import '/app/networking/notifiction_service.dart';

class NotificationController extends Controller {
  final NotificationService _notificationService = NotificationService();

  @override
  construct(BuildContext context) async {
    super.construct(context);
  }

  Future<dynamic> fetchNotifications(String userId) async {
    return await _notificationService.getAllNotificationsForUser(
      userId: userId,
    );
  }

  Future<dynamic> fetchUnreadNotifications(String userId) async {
    return await _notificationService.getUnreadNotificationsForUser(
      userId: userId,
    );
  }
}
