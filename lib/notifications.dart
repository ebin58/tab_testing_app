import 'package:flutter_local_notifications/flutter_local_notifications.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// call this once during app startup
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // tag it so the app knows to jump to Finder
      if (response.payload == 'go_to_finder') {
        _NotificationRouter.intent = 'finder';
      }
    },
  );
}

// push a Terpiez proximity alert
Future<void> showNearbyTerpiezNotification(String name) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'terpiez_channel', // channel ID
    'Terpiez Alerts', // channel name
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails notifDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    'Almost there...',
    '$name is nearby!',
    notifDetails,
    payload: 'go_to_finder', // sets intent
  );
}

// this class holds intent info if a notification launched the app
class _NotificationRouter {
  static String? intent;
}

String? consumeNotificationIntent() {
  final val = _NotificationRouter.intent;
  _NotificationRouter.intent = null; 
  return val;
}
