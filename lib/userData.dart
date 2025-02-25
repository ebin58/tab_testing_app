import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';


class Userdata extends ChangeNotifier{
  
  String playerID = Uuid().v4();
  int numCaught = 0;
  int dayPlayed =0;

}

