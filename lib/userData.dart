import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';


class Userdata extends ChangeNotifier{
  
  String playerID = Uuid().v4();
  int numCaught = 0;
  int dayPlayed =1; // default to initial use
  DateTime firstLogin = DateTime(2025, 02, 1);

  Userdata() {
    updateDaysPlayed(); 
  }
  

  void incrementNumCaught() {
    numCaught++;
    notifyListeners(); // Notify UI to update
  }


  void updateDaysPlayed() {
    final currDate = DateTime.now();
    dayPlayed = currDate.difference(firstLogin).inDays + 1;
    notifyListeners();
  }

}

