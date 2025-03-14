import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'userData.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';


// Function to calculate the distance using the Haversine formula
double haversine(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000.0; // Earth's radius in meters

  // Convert degrees to radians
  double toRadians(double degree) => degree * pi / 180.0;

  // Haversine formula
  final dLat = toRadians(lat2 - lat1);
  final dLon = toRadians(lon2 - lon1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRadians(lat1)) * cos(toRadians(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c; // Distance in meters
}


// Making a few markers
Set<Marker> _createMarkers() {
  return {
    Marker(
      markerId: MarkerId("terpiez_1"),
      position: LatLng(38.9858, -76.9368),
      infoWindow: InfoWindow(title: "Terpiez 1", snippet: "Ya Found me!"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ),
    Marker(
      markerId: MarkerId("terpiez_2"),
      position: LatLng(38.9900, -76.9400),
      infoWindow: InfoWindow(title: "Terpiez 2", snippet: "Whaa!"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
  };
}

// Function to get current location
Future<LatLng> getUserLocation() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  
  return LatLng(position.latitude, position.longitude);
}


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

class PortState extends StatefulWidget {
  @override
  _PortStateState createState() => _PortStateState();
}

class _PortStateState extends State<PortState> {
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    LatLng position = await getUserLocation();
    setState(() {
      _currentPosition = position;
    });
  }

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
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? LatLng(38.9869, -76.9426),
              zoom: 14.0,
            ),
            myLocationEnabled: true,  // Shows user's current location
            myLocationButtonEnabled: true,
            markers: _createMarkers(),
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
            },
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


class LandState extends StatefulWidget {
  @override
  _LandStateState createState() => _LandStateState();
}

class _LandStateState extends State<LandState> {
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    LatLng position = await getUserLocation();
    setState(() {
      _currentPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? LatLng(38.9869, -76.9426),
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _createMarkers(),
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
            },
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
