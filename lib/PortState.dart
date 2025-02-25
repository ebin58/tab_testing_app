import 'package:flutter/material.dart';

class PortState extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Text("Terpiez Finder", 
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.bold,
            )
          )
        ),
        Icon(
          Icons.map_rounded,
          size: 400
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            children: [
              Text("Closest Terpiez:"),
              Text("124.0m")
            ],
          )
        )
      ],
    );
  }
}