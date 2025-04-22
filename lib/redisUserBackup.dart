import 'dart:convert';
import 'redisService.dart';
import 'userData.dart';

Future<void> backupUserDataToRedis(String username, Userdata userData) async {
  final redis = RedisService();
  if (!await redis.ensureConnected()) return;

  final data = {
    userData.playerID: {
      'caught': userData.caughtList
          .map((t) => {
                'id': t.id,
                'lat': t.locations.first.latitude,
                'lon': t.locations.first.longitude,
                'timestamp': DateTime.now().toIso8601String(),
              })
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
