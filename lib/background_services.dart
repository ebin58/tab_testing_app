import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// add this import to be able to create your channel
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'redisService.dart';
import 'notifications.dart';
import 'redisTerpiezInfo.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Terpiez running in background",
      content: "We'll notify you when you're near a Terpiez.",
    );
  }

  // String? lastNotifiedId;

  // timer for time between notifications
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (!(await Geolocator.isLocationServiceEnabled())) return;

    Position pos = await Geolocator.getCurrentPosition();

    final prefs = await SharedPreferences.getInstance();
    final caught = prefs.getStringList('caughtTerpiez') ?? [];

    final redisHelper = Redisterpiezinfo(RedisService());
    final all = await redisHelper.getTerpiezLocations();

    for (final t in all) {
      final id = t['id'];
      if (caught.contains(id)) continue;

      final lat = t['latitude'];
      final lon = t['longitude'];
      if (lat == null || lon == null) continue;

      final dist =
          Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lon);

      if (dist > 10 && dist <= 20) {
        // lastNotifiedId = id;

        final info = await redisHelper.getTerpiezInfo(id);
        final name = info['name'] ?? "Nearby Terpiez";

        await showNearbyTerpiezNotification(name);
        break;
      }
    }
  });
}

// sets up and starts background service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // create Android notification channel for your background service
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'terpiez_channel',
      'Terpiez Background Notifications', // visible to users in Settings
      description:
          'Alerts you when near an uncaught Terpiez', // shown in Settings
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('boop'));
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true, // must be true to survive app kill
      autoStart: true,
      notificationChannelId: 'terpiez_channel',
      foregroundServiceNotificationId:
          888, // ensure startForeground() immediately
      initialNotificationTitle:
          'Terpiez is running', // initial notification title
      initialNotificationContent:
          'We’ll let you know when one is close.', // initial content
    ),
    iosConfiguration: IosConfiguration(),
  );

  service.startService();
}
