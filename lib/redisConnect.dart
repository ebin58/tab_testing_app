import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:redis/redis.dart';

Future<(RedisConnection, Command)?> connectToRedis() async {
  final storage = FlutterSecureStorage();
  final password = await storage.read(key: 'redisPassword');
  final userName = await storage.read(key: 'redisUsername');

  if (password == null) {
    // **** For testing ****
    // debugPrint("Missing Redis password.");
    return null;
  }

  try {
    final connection = RedisConnection();
    final command =
        await connection.connect('cmsc436-0101-redis.cs.umd.edu', 6380);

    await command.send_object(['AUTH', userName, password]);
    // **** For testing ****
    // debugPrint(" Connected to Redis");
    return (connection, command);
  } catch (e) {
    // **** For testing ****
    // debugPrint(" Redis connection failed: $e");
    return null;
  }
}
