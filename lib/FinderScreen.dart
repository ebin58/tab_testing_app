import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tab_testing_app/redisUserBackup.dart';
import 'userData.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'redisService.dart';
import 'redisTerpiezInfo.dart';

// at the end of _catchTerpiez the function writes back to redis and disconnects.

// This function calculates the distance in meters between two coordinate
// using the haversine formula
double haversine(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000.0; // Earth's radius in meters

  double toRadians(double degree) => degree * pi / 180.0;

  final dLat = toRadians(lat2 - lat1);
  final dLon = toRadians(lon2 - lon1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRadians(lat1)) *
          cos(toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c; // Distance in meters
}

// This is an array for Terpiez locations for testing purposes.
// final List<LatLng> terpiezLocations = [
//   LatLng(38.9858, -76.9368), // Terpiez 1
//   LatLng(38.9900, -76.9400), // Terpiez 2
//   LatLng(38.989744, -76.935943), // Terpiez 3
// ];

// For testing //
// Function to find the closest Terpiez location
// LatLng findClosestTerpiez(LatLng currentPosition) {
//   LatLng closest = terpiezLocations[0];
//   double minDistance = haversine(
//       currentPosition.latitude,
//       currentPosition.longitude,
//       closest.latitude,
//       closest.longitude);

//   for (var terpiez in terpiezLocations) {
//     double distance = haversine(
//         currentPosition.latitude,
//         currentPosition.longitude,
//         terpiez.latitude,
//         terpiez.longitude);
//     if (distance < minDistance) {
//       minDistance = distance;
//       closest = terpiez;
//     }
//   }
//   return closest;
// }

// Function to get current location
Future<LatLng?> getUserLocation() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    openAppSettings(); // Opens app settings if the user denied it forever, just in case :)
    return null;
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  return LatLng(position.latitude, position.longitude);
}

class FinderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          final s =
              orientation == Orientation.portrait ? PortState() : LandState();
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

  // variables for terpiez from redis database
  final RedisService _redisService = RedisService();
  late Redisterpiezinfo _redisInfo;
  Map<String, dynamic>? _closestTerpiez;

  Set<Marker> get markers {
    final Set<Marker> result = {};

    if (_closestTerpiez != null) {
      final lat = _closestTerpiez!['latitude'];
      final lon = _closestTerpiez!['longitude'];
      final id = _closestTerpiez!['id']; // Use real ID

      result.add(Marker(
        markerId: MarkerId(id),
        position: LatLng(lat, lon),
        infoWindow: InfoWindow(title: _closestTerpiez!['name']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _redisInfo = Redisterpiezinfo(_redisService);
    _checkAndStartLocationUpdates(); // Checking permissions before starting the map
  }

  Future<void> _checkAndStartLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      openAppSettings();
      return;
    }

    _startLocationUpdates(); // Updates location if permission is given
  }

  // this methhod gets start location and continuesly checks terpiz loctions
  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return; // Stop execution if permission is denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      openAppSettings(); // Direct user to manually enable permissions
      return;
    }

    // Start listening for location updates only if permission is granted
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) async {
      LatLng newPosition = LatLng(position.latitude, position.longitude);

      // Fetch list of terpiez from Redis
      final rawList = await _redisInfo.getTerpiezLocations();
      if (rawList.isEmpty) return;

      final List<Map<String, dynamic>> terpiezList = [];

      final userData = Provider.of<Userdata>(context, listen: false);

      for (final loc in rawList) {
        final id = loc['id'];
        final lat = loc['latitude'];
        final lon = loc['longitude'];

        final alreadyCaught = userData.caughtList.any((t) =>
            t.id == id &&
            t.locations.any((l) =>
                (l.latitude - lat).abs() < 0.0001 &&
                (l.longitude - lon).abs() < 0.0001));

        if (alreadyCaught) continue; // skip this location

        final details = await _redisInfo.getTerpiezInfo(id);
        terpiezList.add({
          ...loc,
          'name': details['name'] ?? 'Unknown',
        });
      }

      // Find closest Terpiez from Redis using the haversine function
      Map<String, dynamic>? closest;
      double minDist = double.infinity;

      for (var terp in terpiezList) {
        final lat = terp['latitude'];
        final lon = terp['longitude'];
        final dist = haversine(
          newPosition.latitude,
          newPosition.longitude,
          lat,
          lon,
        );

        if (dist < minDist) {
          minDist = dist;
          closest = terp;
        }
      }

      // Updates the UI
      setState(() {
        _currentPosition = newPosition;
        _closestTerpiez = closest;
        _closestDistance = closest != null
            ? "${minDist.toStringAsFixed(2)} meters"
            : "None nearby";
        _canCatch = closest != null && minDist <= 10;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(newPosition),
      );
    });
  }

  void _catchTerpiez(BuildContext context) async {
    if (!_canCatch || _closestTerpiez == null) return;

    final id = _closestTerpiez!['id'];
    final lat = _closestTerpiez!['latitude'];
    final lon = _closestTerpiez!['longitude'];

    final userData = Provider.of<Userdata>(context, listen: false);

    // Prevent duplicate catch at the same location
    final alreadyCaught = userData.caughtList.any((t) =>
        t.id == id &&
        t.locations.any((loc) =>
            (loc.latitude - lat).abs() < 0.0001 &&
            (loc.longitude - lon).abs() < 0.0001));

    if (alreadyCaught) {
      // **** For testing ****
      // debugPrint("This Terpiez at this location has already been caught.");
      return;
    }

    final redisInfo = Redisterpiezinfo(_redisService);

    final info = await redisInfo.getTerpiezInfo(id);
    final thumbData =
        await redisInfo.fetchImageDataFromRedis(info['thumbnail']);
    final fullData = await redisInfo.fetchImageDataFromRedis(info['image']);

    final dir = await getApplicationDocumentsDirectory();

    final thumbFile = File('${dir.path}/thumb_$id.png');
    final fullFile = File('${dir.path}/full_$id.png');

    await thumbFile.writeAsBytes(base64Decode(thumbData['image64']));
    await fullFile.writeAsBytes(base64Decode(fullData['image64']));

    final caught = CaughtTerpiez(
      id: info['id'],
      name: info['name'],
      description: info['description'],
      thumbnailPath: thumbFile.path,
      imagePath: fullFile.path,
      stats: Map<String, dynamic>.from(info['stats']),
      locations: [
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ],
    );

    userData.addCaught(caught); // Also increments numCaught

    setState(() {
      _canCatch = false;
      _closestTerpiez = null;
    });

    // **** For testing ****
    // debugPrint("Caught and added to list: ${info['name']}");

    // final jsonFile = File('${dir.path}/terpiez_${id}.json');
    // await jsonFile.writeAsString(jsonEncode({
    //   'id': caught.id,
    //   'name': caught.name,
    //   'description': caught.description,
    //   'thumbnail': caught.thumbnailPath,
    //   'image': caught.imagePath,
    //   'stats': caught.stats,
    //   'latitude': caught.locations.first.latitude,
    //   'longitude': caught.locations.first.longitude,
    // }));

    // Back up to Redis
    final storage = FlutterSecureStorage();
    final username = await storage.read(key: 'redisUsername');
    if (username != null) {
      await backupUserDataToRedis(username, userData);
      await _redisService.disconnect();
    }

    // disconnect to avoid dangling connections
    await _redisService.disconnect();

    // Showing the pop up to the user
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(
                File(caught.thumbnailPath),
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 20),
              Text(
                caught.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Nice work! You've caught ${caught.name}.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      },
    );
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
            mapType: MapType.normal,
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
              Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer()),
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
            mapType: MapType.normal,
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
              Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer()),
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
