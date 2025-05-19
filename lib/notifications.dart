import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// fire this whenever a notification with payload 'go_to_finder' is tapped
final ValueNotifier<int> finderTapNotifier = ValueNotifier<int>(0);

// holds intent for cold‐start routing
NotificationAppLaunchDetails? _launchDetails;

Future<void> initializeNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  // capture cold‐start details
  _launchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == 'go_to_finder') {
        _NotificationRouter.intent = 'finder';
        finderTapNotifier.value += 1; // trigger the listener
        debugPrint('notification tapped -> intent = finder');
      }
    },
  );

  // if the app was cold‐launched from a notification
  if (_launchDetails?.didNotificationLaunchApp ?? false) {
    if (_launchDetails!.notificationResponse?.payload == 'go_to_finder') {
      _NotificationRouter.intent = 'finder';
      debugPrint('app cold‐launched from notification -> intent = finder');
    }
  }
}

// push a Terpiez proximity alert
Future<void> showNearbyTerpiezNotification(String name) async {
  const androidDetails = AndroidNotificationDetails(
    'terpiez_channel',
    'Terpiez Alerts',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );
  const notifDetails = NotificationDetails(android: androidDetails);

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

// read+clear the cold‐start intent
String? consumeNotificationIntent() {
  final val = _NotificationRouter.intent;
  _NotificationRouter.intent = null;
  return val;
}
