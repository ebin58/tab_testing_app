import 'redisService.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

// Class to get all terpiez info from redis server

class Redisterpiezinfo {
  final RedisService _redisService;

  Redisterpiezinfo(this._redisService);

  Future<List<Map<String, dynamic>>> getTerpiezLocations() async {
    final connected = await _redisService.ensureConnected();
    if (!connected) return [];

    try {
      final response =
          await _redisService.command.send_object(['JSON.GET', 'locations']);
      final decoded = jsonDecode(response) as List<dynamic>;

      return decoded.map<Map<String, dynamic>>((loc) {
        return {
          'latitude': loc['lat'],
          'longitude': loc['lon'],
          'id': loc['id'],
        };
      }).toList();
    } catch (e) {
      // **** For testing ****
      debugPrint("Failed to fetch Terpiez locations: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getTerpiezInfo(String id) async {
    // wait for the connection

    if (!await _redisService.ensureConnected()) {
      throw Exception("Error getting terpiez details");
    }

    try {
      final response =
          await _redisService.command.send_object(['JSON.GET', 'terpiez', id]);
      var terpiezId = jsonDecode(response);
      return {
        'id': id,
        'name': terpiezId['name'] ?? 'Unknown',
        'description': terpiezId['description'] ?? 'No description provided.',
        'thumbnail': terpiezId['thumbnail'] ?? 'default_thumbnail.png',
        'image': terpiezId['image'] ?? 'default_image.png',
        'stats': terpiezId['stats'] ?? {},
      };
    } catch (e) {
      // **** For testing ****
      debugPrint("Failed to fetch Terpiez info: $e");
      return {};
    }
  }

  // Fetch a single base64-encoded image by key from Redis
  Future<Map<String, dynamic>> fetchImageDataFromRedis(String imageKey) async {
    try {
      final connected = await _redisService.ensureConnected();
      if (!connected) {
        throw Exception("Redis not connected.");
      }

      // Use dot notation to access the specific image key
      final response = await _redisService.command
          .send_object(['JSON.GET', 'images', '.$imageKey']);

      if (response == null) {
        // **** For testing ****
        debugPrint("No image found for key: $imageKey");
        return {};
      }

      final base64String = jsonDecode(response);
      if (base64String == null || base64String is! String) {
        // **** For testing ****
        debugPrint("Invalid image data format for key: $imageKey");
        return {};
      }
      // **** For testing ****
      debugPrint("Image data successfully retrieved for $imageKey");
      return {
        'imageKey': imageKey,
        'image64': base64String,
      };
    } catch (e) {
      // **** For testing ****
      debugPrint("Error fetching image for $imageKey: $e");
      return {};
    }
  }
}
