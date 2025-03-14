import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'userData.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';


// This function calculates the distance in meters between two coordinate 
// using the haversine formula
double haversine(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000.0; // Earth's radius in meters

  double toRadians(double degree) => degree * pi / 180.0;

  final dLat = toRadians(lat2 - lat1);
  final dLon = toRadians(lon2 - lon1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRadians(lat1)) * cos(toRadians(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c; // Distance in meters
}


// This is an array for Terpiez locations
final List<LatLng> terpiezLocations = [
  LatLng(38.9858, -76.9368), // Terpiez 1
  LatLng(38.9900, -76.9400), // Terpiez 2
  LatLng(38.989744, -76.935943), // Terpiez 3
];


// Function to find the closest Terpiez location
LatLng findClosestTerpiez(LatLng currentPosition) {
  LatLng closest = terpiezLocations[0];
  double minDistance = haversine(
      currentPosition.latitude,
      currentPosition.longitude,
      closest.latitude,
      closest.longitude);

  for (var terpiez in terpiezLocations) {
    double distance = haversine(
        currentPosition.latitude,
        currentPosition.longitude,
        terpiez.latitude,
        terpiez.longitude);
    if (distance < minDistance) {
      minDistance = distance;
      closest = terpiez;
    }
  }
  return closest;
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

abstract class BaseState extends StatefulWidget {}

abstract class BaseStatefulState<T extends BaseState> extends State<T> {
  LatLng? _currentPosition;
  String _closestDistance = "Calculating...";
  GoogleMapController? _mapController;
  bool _canCatch = false;

  Set<Marker> get markers => terpiezLocations.asMap().entries.map((entry) {
    int index = entry.key;
    LatLng loc = entry.value;
    return Marker(
      markerId: MarkerId("${loc.latitude},${loc.longitude}"),
      position: loc,
      infoWindow: InfoWindow(title: "Terpiez ${index + 1}"),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          (BitmapDescriptor.hueRed + (index * 30)) % 360),
    );
  }).toSet();

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      LatLng newPosition = LatLng(position.latitude, position.longitude);
      LatLng closest = findClosestTerpiez(newPosition);
      double distance = haversine(
          newPosition.latitude, newPosition.longitude,
          closest.latitude, closest.longitude);

      setState(() {
        _currentPosition = newPosition;
        _closestDistance = "${distance.toStringAsFixed(2)} meters";
        _canCatch = distance <= 10;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(newPosition),
      );
    });
  }

  void _catchTerpiez(BuildContext context) {
    if (_canCatch) {
      Provider.of<Userdata>(context, listen: false).numCaught++;
    }
  }

  Widget buildPortState(BuildContext context) {
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
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
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
              Text(_closestDistance),
              ElevatedButton(
                onPressed: _canCatch ? () => _catchTerpiez(context) : null,
                child: Text("Catch"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildLandState(BuildContext context) {
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
            markers: markers,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Terpiez Finder",
                style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold),
              ),
              Text("Closest Terpiez:"),
              Text(_closestDistance, style: TextStyle(fontSize: 24)),
              ElevatedButton(
                onPressed: _canCatch ? () => _catchTerpiez(context) : null,
                child: Text("Catch"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PortState extends BaseState {
  @override
  _PortStateState createState() => _PortStateState();
}

class LandState extends BaseState {
  @override
  _LandStateState createState() => _LandStateState();
}

class _PortStateState extends BaseStatefulState<PortState> {
  @override
  Widget build(BuildContext context) => buildPortState(context);
}

class _LandStateState extends BaseStatefulState<LandState> {
  @override
  Widget build(BuildContext context) => buildLandState(context);
}
