import 'package:flutter/material.dart';


class StatsScreen extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return Scaffold(
          body: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Text("Statistics", 
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  )
                )
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  children: [
                    Text("   Terpiez found: 23",
                    style: TextStyle(
                      fontSize: 18  
                    ),
                    ),
                    Text("Days Active: 24", 
                    style: TextStyle(
                      fontSize: 18
                    )
                    )
                  ],
                )
              )
            ]
          ),
        );
    }
  }