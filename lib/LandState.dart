import 'package:flutter/material.dart';

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