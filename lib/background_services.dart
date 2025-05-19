import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String? lastNotifiedId;

  Timer.periodic(const Duration(seconds: 15), (timer) async {
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

      if (dist > 10 && dist <= 20 && lastNotifiedId != id) {
        lastNotifiedId = id;

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

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true, // must be true to survive app kill
      autoStart: true,
      notificationChannelId: 'terpiez_channel',
      initialNotificationTitle: 'Terpiez is running',
      initialNotificationContent: 'We’ll let you know when one is close.',
    ),
    iosConfiguration: IosConfiguration(),
  );

  service.startService();
}
