import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:redis/redis.dart';

class RedisService {
  final String _host = 'cmsc436-0101-redis.cs.umd.edu';
  final int _port = 6380;
  final _secureStorage = FlutterSecureStorage();

  RedisConnection? _connection; // stores the connection
  Command? _command;

  Command get command => _command!;

  Future<bool> connect() async {
    try {
      final username = await _secureStorage.read(key: 'redisUsername');
      final password = await _secureStorage.read(key: 'redisPassword');

      if (username == null || password == null) {
        // **** For testing ****
        // debugPrint("Missing Redis credentials.");
        return false;
      }

      _connection = RedisConnection(); // saves the connection
      _command = await _connection!
          .connect(_host, _port)
          .timeout(Duration(seconds: 1));

      await _command!
          .send_object(['AUTH', username, password])
          .timeout(Duration(seconds: 1));

      // **** For testing ****
      // debugPrint("Connected to Redis as $username");
      return true;
    } catch (e) {
      // **** For testing ****
      // debugPrint("Redis connection failed: $e");
      _connection = null;
      _command = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close(); // closes the actual connection
      _connection = null;
      _command = null;
      // **** For testing ****
      // debugPrint("Redis connection closed.");
    } catch (e) {
      // **** For testing ****
      debugPrint("Failed to close Redis connection: $e");
    }
  }

  Future<bool> ensureConnected() async {
    try {
      if (_command == null) {
        // **** For testing ****
        debugPrint("Redis not connected. Connecting...");
        // fresh connect (with 1s timeout)
        return await connect().timeout(
          Duration(seconds: 1),
          onTimeout: () => false,
        );
      } else {
        // lightweight probe
        await _command!
            .send_object(['PING'])
            .timeout(Duration(seconds: 1));
        return true;
      }
    } catch (e) {
      // **** For testing ****
      debugPrint("Redis connection lost. Reconnecting... ($e)");
      // clear old state & retry
      _connection = null;
      _command = null;
      return await connect().timeout(
        Duration(seconds: 1),
        onTimeout: () => false,
      );
    }
  }
}
