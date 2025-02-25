import 'package:flutter/material.dart';
import 'LandState.dart';
import 'PortState.dart';


class FinderScreen extends StatelessWidget{

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation){
          final s = orientation == Orientation.portrait ? PortState() : LandState();
          return Padding(
          padding: EdgeInsets.all(10),
          child: s,
        );
        }
      )
    );
  }
}