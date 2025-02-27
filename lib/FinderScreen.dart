import 'package:flutter/material.dart';


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

class LandState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
  
          Icon(
            Icons.map_rounded,
            size: 150,
          ),
  
          Expanded(
            child: Column(
                
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              Text(
                "Terpiez Finder",
                style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold),
              ),
              Text("Closest Terpiez:"),
              Text("124.0m", style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
      ],
    );
  }
}