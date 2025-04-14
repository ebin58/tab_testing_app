import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Userdata extends ChangeNotifier {
  String playerID = '';
  int numCaught = 0;
  int dayPlayed = 1;
  DateTime firstLogin = DateTime.now();

  Userdata() {
    initUserdata();
  }

  Future<void> initUserdata() async {
    final prefs = await SharedPreferences.getInstance();

    // Load or create UUID
    playerID = prefs.getString('playerID') ?? Uuid().v4();
    if (!prefs.containsKey('playerID')) {
      await prefs.setString('playerID', playerID);
    }

    // Load or set firstLogin date
    if (prefs.containsKey('firstLogin')) {
      firstLogin = DateTime.parse(prefs.getString('firstLogin')!);
    } else {
      firstLogin = DateTime.now();
      await prefs.setString('firstLogin', firstLogin.toIso8601String());
    }

    updateDaysPlayed();
  }

  void updateDaysPlayed() {
    final now = DateTime.now();
    dayPlayed = now.difference(firstLogin).inDays + 1;
    notifyListeners();
  }

  void incrementNumCaught() {
    numCaught++;
    notifyListeners();
  }
}
