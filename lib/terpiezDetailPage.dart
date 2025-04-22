import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'userData.dart';
import 'terpiezAnimation.dart';

class TerpiezDetailPage extends StatelessWidget {
  final CaughtTerpiez terp;

  TerpiezDetailPage(this.terp);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(terp.name)),
      body: Stack(
        children: [
          // Background animation
          TerpiezBarsAnimation(),

          SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.file(File(terp.imagePath), width: 200),
                ),
                SizedBox(height: 16),
                Text(
                  terp.description,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text("Stats:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...terp.stats.entries.map((e) => Text("${e.key}: ${e.value}")),
                SizedBox(height: 20),
                Container(
                  height: 250,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: terp.locations.first,
                      zoom: 14,
                    ),
                    markers: terp.locations
                        .map((loc) => Marker(
                              markerId:
                                  MarkerId("${loc.latitude},${loc.longitude}"),
                              position: loc,
                            ))
                        .toSet(),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
