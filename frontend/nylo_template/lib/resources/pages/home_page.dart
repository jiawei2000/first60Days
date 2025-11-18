import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

import '/app/models/baby.dart';
import '/app/controllers/home_controller.dart';
import '/app/controllers/notification_controller.dart';
import '/resources/widgets/safearea_widget.dart';
import '/resources/pages/create_journal_entry_page.dart';
import '../widgets/buttons/partials/primary_button_widget.dart';
import '/resources/pages/profile_page.dart';
import '/config/keys.dart';
import '/config/weekly_messages.dart';

class HomePage extends NyStatefulWidget<HomeController> {
  static RouteView path = ("/home", (_) => HomePage());

  HomePage({super.key}) : super(child: () => _HomePageState());
}

class _HomePageState extends NyPage<HomePage> {
  HomeController get controller => widget.controller;

  Baby? _baby;
  int? _weekNo;
  bool _loading = true;
  String? _weeklyMessage;
  final Random _random = Random();
  final NotificationController _notificationController =
      NotificationController();
  List<dynamic> _notifications = [];
  bool _notificationsLoading = true;

  @override
  get init => () async {
        _notificationController.construct(context);
        final babyId = await Keys.selectedBabyId.read();
        final userId = await Keys.userId.read();

        print("UserId: $userId");

        if (babyId == null) {
          NyLogger.error("No baby selected.");
          showToast(
            title: "Error",
            description: "No baby selected.",
            style: ToastNotificationStyleType.danger,
          );
          return;
        }

        final baby = await controller.fetchBabyById(babyId);
        final weekNo = await controller.fetchWeekNo(babyId);
        dynamic notificationResponse;
        if (userId != null) {
          try {
            notificationResponse =
                await _notificationController.fetchNotifications(userId);
            print("Notifications: $notificationResponse");
          } catch (error) {
            print("Error fetching notifications: $error");
          }
        }

        String? selectedMessage;
        if (weekNo != null) {
          final messages = weeklyMessages[weekNo];
          if (messages != null && messages.isNotEmpty) {
            selectedMessage = messages[_random.nextInt(messages.length)];
          }
        }

        final notifications = _parseNotifications(notificationResponse);

        setState(() {
          _baby = baby;
          _weekNo = weekNo;
          _weeklyMessage = selectedMessage;
          _loading = false;
          _notifications = notifications;
          _notificationsLoading = false;
        });
      };

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final babyName = _baby?.name ?? "Baby";
    final displayWeek = _weekNo ?? 0;
    final progress = (_weekNo != null && _weekNo! > 0 && _weekNo! <= 10)
        ? _weekNo! / 10
        : 0.0;
    final weeklyMessage =
        _weeklyMessage ?? "Error loading message. Please try again later.";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Homepage",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                routeTo(ProfilePage.path);
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundImage:
                    AssetImage('public/images/baby_icon_animated.png'),
              ),
            ),
          )
        ],
      ),
      body: SafeAreaWidget(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  babyName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// 🟣 Weekly Update Banner
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.purple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        weeklyMessage,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        // Handle dismiss
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🟢 Progress Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Progression",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Week $displayWeek",
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        color: Colors.blue,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🩵 Log Journal Entry Button (Full width)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: "Log Baby Journal Entry",
                    onPressed: () {
                      routeTo(CreateJournalEntryPage.path);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🟡 Reminders (Full width)
              _reminderTile(
                "$babyName’s next feeding time is at ",
                "10:34 AM",
              ),
              _notificationsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reminderTile(String message, String time) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.amber.withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: "$message ",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: time,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _parseNotifications(dynamic response) {
    if (response is List) {
      return response;
    }
    if (response is Map && response['data'] is List) {
      return List<dynamic>.from(response['data']);
    }
    return [];
  }

  Widget _notificationsSection(ThemeData theme) {
    if (_notificationsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (_notifications.isEmpty)
          _reminderTile("No notifications yet.", "")
        else
          ..._notifications.map(
            (notification) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _reminderTile(
                _formatNotificationMessage(notification),
                "",
              ),
            ),
          ),
      ],
    );
  }

  String _formatNotificationMessage(dynamic notification) {
    final message = notification?['message']?.toString() ?? "No message";
    return message;
  }
}
