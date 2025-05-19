import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final ValueNotifier<int> finderTapNotifier = ValueNotifier<int>(0);

NotificationAppLaunchDetails? _launchDetails;

Future<void> initializeNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  _launchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == 'go_to_finder') {
        _NotificationRouter.intent = 'finder';
        finderTapNotifier.value += 1;
        debugPrint('notification tapped -> intent = finder');
      }
    },
  );

  if (_launchDetails?.didNotificationLaunchApp ?? false) {
    if (_launchDetails!.notificationResponse?.payload == 'go_to_finder') {
      _NotificationRouter.intent = 'finder';
      debugPrint('app cold‐launched from notification -> intent = finder');
    }
  }
}

Future<void> showNearbyTerpiezNotification(String name) async {
  final prefs = await SharedPreferences.getInstance();
  final isMuted = prefs.getBool('isMuted') ?? false;

  final androidDetails = AndroidNotificationDetails(
    'terpiez_channel',
    'Terpiez Alerts',
    importance: Importance.max,
    priority: Priority.high,
    playSound: !isMuted,
    sound: isMuted ? null : RawResourceAndroidNotificationSound('boop'),
  );

  final notifDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Almost there...',
    '$name is nearby!',
    notifDetails,
    payload: 'go_to_finder',
  );

  debugPrint('notification pushed with payload = go_to_finder');
}

class _NotificationRouter {
  static String? intent;
}

String? consumeNotificationIntent() {
  final val = _NotificationRouter.intent;
  _NotificationRouter.intent = null;
  return val;
}
