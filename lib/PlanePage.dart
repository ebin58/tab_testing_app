import 'package:flutter/material.dart';

class PlanePage extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Plane"),
      ),
      body: Column(
        children: [Align(
          alignment: Alignment.topCenter,
          child: Hero(
            tag: "planePage",
            child: Icon(
            Icons.airplanemode_active,
            size: 100,
            ),
          ),
        ),
        Text("Plane")
        ]
      ),
    );
  }
}