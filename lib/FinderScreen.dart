import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'userData.dart';

class FinderScreen extends StatelessWidget{


class FinderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          final s = orientation == Orientation.portrait ? PortState() : LandState();
          return Padding(
            padding: EdgeInsets.all(10),
            child: s,
          );
        },
      ),
    );
  }
}

class PortState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Text(
            "Terpiez Finder",
            style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Provider.of<Userdata>(context, listen: false).numCaught++;
            },
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(38.9869, -76.9426), // Sample coordinates (UMD area)
                zoom: 14.0,
              ),
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            children: [
              Text("Closest Terpiez:"),
              Text("124.0m"),
            ],
          ),
        ),
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
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {
              Provider.of<Userdata>(context, listen: false).numCaught++;
            },
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(38.9869, -76.9426),
                zoom: 14.0,
              ),
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
              },
            ),
          ),
        ),
        Expanded(
          flex: 2,
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
