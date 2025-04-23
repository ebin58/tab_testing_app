import 'dart:convert';
import 'redisService.dart';
import 'userData.dart';

Future<void> backupUserDataToRedis(String username, Userdata userData) async {
  final redis = RedisService();
  if (!await redis.ensureConnected()) return;

  final data = {
    userData.playerID: {
      'caught': userData.caughtList
          .expand((t) => t.locations.map((loc) => {
                'id': t.id,
                'name': t.name,
                'lat': loc.latitude,
                'lon': loc.longitude,
                'timestamp': DateTime.now().toIso8601String(),
              }))
          .toList(),
      'stats': {
        'numCaught': userData.numCaught,
        'dayPlayed': userData.dayPlayed,
      }
    }
  };

  await redis.command.send_object([
    'JSON.SET',
    username,
    '.',
    jsonEncode(data),
  ]);
}
