import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/widgets/loader_widget.dart';

/// Global loading overlay helper.
///
/// Usage:
///   await LoadingOverlay.show(message: 'Signing in...');
///   try { await doWork(); } finally { LoadingOverlay.hide(); }
class LoadingOverlay {
  static int _activeCount = 0;
  static bool get isShowing => _activeCount > 0;

  static Future<void> show({String? message}) async {
    _activeCount++;
    if (_activeCount > 1) return; // already visible

    final router = NyNavigator.instance.router;
    final navigatorKey = router.navigatorKey;
    final navigator = navigatorKey?.currentState;
    final context = navigator?.overlay?.context ?? navigator?.context;
    if (context == null) return;

    // Defer to ensure overlay shows after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Loading',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, __, ___) {
          return PopScope(
            canPop: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    const Loader(),
                    if (message != null && message.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  static void hide() {
    if (_activeCount == 0) return;
    _activeCount--;
    if (_activeCount > 0) return; // still pending callers

    final router = NyNavigator.instance.router;
    final navigatorKey = router.navigatorKey;
    final navigator = navigatorKey?.currentState;
    if (navigator?.canPop() == true) {
      navigator!.pop();
    }
  }

  /// Convenience wrapper to run a future while showing the overlay.
  static Future<T> run<T>(Future<T> Function() task, {String? message}) async {
    await show(message: message);
    try {
      return await task();
    } finally {
      hide();
    }
  }
}
