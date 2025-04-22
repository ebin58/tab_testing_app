import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Userdata extends ChangeNotifier {
  String playerID = '';
  int numCaught = 0;
  int dayPlayed = 0;
  DateTime firstLogin = DateTime.now();

  List<CaughtTerpiez> caughtList = [];

  Future<void> initUserdata() async {
    final prefs = await SharedPreferences.getInstance();

    playerID = prefs.getString('playerID') ?? Uuid().v4();
    if (!prefs.containsKey('playerID')) {
      await prefs.setString('playerID', playerID);
    }

    if (prefs.containsKey('firstLogin')) {
      firstLogin = DateTime.parse(prefs.getString('firstLogin')!);
    } else {
      firstLogin = DateTime.now();
      await prefs.setString('firstLogin', firstLogin.toIso8601String());
    }

    numCaught = prefs.getInt('numCaught') ?? 0;
    dayPlayed = prefs.getInt('dayPlayed') ?? 1;

    updateDaysPlayed();
    await restoreCaughtFromLocalFiles();
  }

  void updateDaysPlayed() async {
    final now = DateTime.now();
    dayPlayed = now.difference(firstLogin).inDays;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dayPlayed', dayPlayed);

    notifyListeners();
  }

  void addCaught(CaughtTerpiez t) async {
    final existing = caughtList.indexWhere((x) => x.id == t.id);
    if (existing != -1) {
      // Add new location to existing Terpiez if not already present
      for (final loc in t.locations) {
        if (!caughtList[existing].locations.any((l) =>
            (l.latitude - loc.latitude).abs() < 0.0001 &&
            (l.longitude - loc.longitude).abs() < 0.0001)) {
          caughtList[existing].locations.add(loc);
        }
      }
    } else {
      caughtList.add(t);
      numCaught++;
    }

    await saveStats();
    await saveCaughtToFile(t);
    notifyListeners();
  }

  void incrementNumCaught() async {
    numCaught++;
    await saveStats();
    notifyListeners();
  }

  Future<void> saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('numCaught', numCaught);
    await prefs.setInt('dayPlayed', dayPlayed);
  }

  Future<void> saveCaughtToFile(CaughtTerpiez t) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/terpiez_${t.id}.json');

    await file.writeAsString(jsonEncode({
      'id': t.id,
      'name': t.name,
      'description': t.description,
      'thumbnail': t.thumbnailPath,
      'image': t.imagePath,
      'stats': t.stats,
      'locations': t.locations
          .map((loc) => {'lat': loc.latitude, 'lon': loc.longitude})
          .toList(),
    }));
  }

  Future<void> restoreCaughtFromLocalFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();

    caughtList.clear();

    for (final file in files) {
      if (file is File &&
          file.path.endsWith('.json') &&
          file.path.contains('terpiez_')) {
        try {
          final data = jsonDecode(await file.readAsString());

          caughtList.add(CaughtTerpiez(
            id: data['id'],
            name: data['name'],
            description: data['description'],
            thumbnailPath: data['thumbnail'],
            imagePath: data['image'],
            stats: Map<String, dynamic>.from(data['stats']),
            locations: List<Map<String, dynamic>>.from(data['locations'])
                .map((loc) => LatLng(loc['lat'], loc['lon']))
                .toList(),
          ));
        } catch (e) {
          debugPrint("Failed to restore from ${file.path}: $e");
        }
      }
    }

    notifyListeners();
  }
}

class CaughtTerpiez {
  final String id;
  final String name;
  final String description;
  final String thumbnailPath;
  final String imagePath;
  final Map<String, dynamic> stats;
  final List<LatLng> locations;

  CaughtTerpiez({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailPath,
    required this.imagePath,
    required this.stats,
    required this.locations,
  });
}
