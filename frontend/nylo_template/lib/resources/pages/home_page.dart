import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

import '/app/models/baby.dart';
import '/app/controllers/home_controller.dart';
import '/app/controllers/notification_controller.dart';
import '/app/controllers/ai_controller.dart';
import '/resources/widgets/safearea_widget.dart';
import '/resources/pages/create_journal_entry_page.dart';
import '../widgets/buttons/partials/primary_button_widget.dart';
import '/resources/pages/profile_page.dart';
import '/config/keys.dart';
import '/config/weekly_messages.dart';
import '/app/notifiers/feed_notifier.dart';

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
  String? _nextFeedTime;
  bool _sendingQuestion = false;
  final TextEditingController _questionController = TextEditingController();
  final Random _random = Random();
  final NotificationController _notificationController =
      NotificationController();
  final AiController _aiController = AiController();
  List<dynamic> _notifications = [];
  bool _notificationsLoading = true;
  late final VoidCallback _nextFeedTimeListener;

  @override
  get init => () async {
        _notificationController.construct(context);
        _aiController.construct(context);
        _nextFeedTimeListener = () {
          if (!mounted) return;
          setState(() {
            _nextFeedTime = FeedNotifiers.nextFeedTime.value;
          });
        };
        FeedNotifiers.nextFeedTime.addListener(_nextFeedTimeListener);
        final babyId = await Keys.selectedBabyId.read();
        final userId = await Keys.userId.read();
        await _refreshNextFeedTime();

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

        final selectedMessage = _selectWeeklyMessage(weekNo);

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
  void activate() {
    super.activate();
    _refreshNextFeedTime();
  }

  @override
  void dispose() {
    FeedNotifiers.nextFeedTime.removeListener(_nextFeedTimeListener);
    _questionController.dispose();
    super.dispose();
  }

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
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshWeeklyMessage,
                    ),
                  ],
                ),
              ),

              // const SizedBox(height: 20),

              /// 🟢 Progress Card
              // Container(
              //   width: double.infinity,
              //   decoration: BoxDecoration(
              //     color: theme.colorScheme.surfaceContainerHighest,
              //     borderRadius: BorderRadius.circular(10),
              //     border: Border.all(
              //       color: theme.colorScheme.outlineVariant.withOpacity(0.3),
              //     ),
              //   ),
              //   padding: const EdgeInsets.all(20),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         "Progression",
              //         style: theme.textTheme.titleMedium?.copyWith(
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       const SizedBox(height: 8),
              //       Text("Week $displayWeek",
              //           style: theme.textTheme.bodyMedium),
              //       const SizedBox(height: 8),
              //       ClipRRect(
              //         borderRadius: BorderRadius.circular(20),
              //         child: LinearProgressIndicator(
              //           value: progress,
              //           minHeight: 12,
              //           color: Colors.blue,
              //           backgroundColor: Colors.grey[300],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              const SizedBox(height: 20),

              /// 🤖 Ask Baby Assistant
              Text(
                "Ask Baby Assistant",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: "Try... How has my baby been sleeping?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                minLines: 1,
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: _sendingQuestion ? "Sending..." : "Ask Assistant",
                onPressed: _sendingQuestion ? null : _sendQuestion,
              ),

              // const SizedBox(height: 20),

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
                "$babyName’s next feeding time is at",
                _nextFeedTime ?? "",
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

  Future<void> _refreshNextFeedTime() async {
    final nextFeedTime = await Keys.nextFeedTime.read();
    FeedNotifiers.nextFeedTime.value = nextFeedTime;
  }

  void _refreshWeeklyMessage() {
    final newMessage = _selectWeeklyMessage(_weekNo);
    if (newMessage != null) {
      setState(() {
        _weeklyMessage = newMessage;
      });
    }
  }

  String? _selectWeeklyMessage(int? weekNo) {
    if (weekNo == null) {
      return null;
    }
    final messages = weeklyMessages[weekNo];
    if (messages == null || messages.isEmpty) {
      return null;
    }
    return messages[_random.nextInt(messages.length)];
  }

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      showToastWarning(
        title: "Question required",
        description: "Please enter a question for the assistant.",
      );
      return;
    }

    final babyId = await Keys.selectedBabyId.read();
    if (babyId == null) {
      showToastDanger(
        title: "No baby selected",
        description: "Please select a baby first.",
      );
      return;
    }

    setState(() {
      _sendingQuestion = true;
    });

    try {
      final response = await _aiController.askAssistant(
            question: question,
            babyId: babyId,
          ) ??
          {};

      print("Response: $response");
      String message;
      if (response is Map && response['answer'] != null) {
        message = response['answer'].toString();
      } else if (response is String) {
        message = response;
      } else {
        message = "Received a response.";
      }
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Baby Assistant"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (error) {
      showToastDanger(
        title: "Assistant error",
        description: "Unable to fetch a response. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingQuestion = false;
        });
      }
    }
  }
}
