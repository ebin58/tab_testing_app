import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'background_services.dart';
import 'redisUserBackup.dart';
import 'userData.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'redisService.dart';
import 'redisTerpiezInfo.dart';

// at the end of _catchTerpiez the function writes back to redis and disconnects.

// This function calculates the distance in meters between two coordinates
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
// LatLng findClosestTerpiez(LatLng currentPosition) { … }

// Function to get current location
Future<LatLng?> getUserLocation() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  if (permission == LocationPermission.deniedForever) {
    openAppSettings();
    return null;
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
          final s =
              orientation == Orientation.portrait ? PortState() : LandState();
          return Padding(padding: EdgeInsets.all(10), child: s);
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

  // sensor subscription for shake detection
  StreamSubscription<AccelerometerEvent>? _accelSub;
  static const double _shakeThreshold = 10.0;

  // guard so one shake only prompts one catch and dialog popup
  bool _isCatching = false;

  // variables for terpiez from redis database
  final RedisService _redisService = RedisService();
  late Redisterpiezinfo _redisInfo;
  Map<String, dynamic>? _closestTerpiez;

  // cache all terpiez locations locally
  List<Map<String, dynamic>> _terpiezCache = [];
  // timer to back up user data every 30 seconds
  Timer? _backupTimer;

  Set<Marker> get markers {
    final Set<Marker> result = {};
    if (_closestTerpiez != null) {
      final lat = _closestTerpiez!['latitude'];
      final lon = _closestTerpiez!['longitude'];
      final id = _closestTerpiez!['id'];
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

    // cache all terpiez into memory
    _loadTerpiezCache();
    // start periodic backup to redis every 30 seconds
    _startPeriodicBackup();

    // listen for shakes when a Terpiez is in range
    _accelSub = accelerometerEventStream().listen((event) {
      if (_canCatch &&
          !_isCatching &&
          (event.x.abs() > _shakeThreshold ||
              event.y.abs() > _shakeThreshold ||
              event.z.abs() > _shakeThreshold)) {
        _isCatching = true; // prevent re‐entry
        _catchTerpiez(context).whenComplete(() {
          _isCatching = false; // re‐enable after done
        });
      }
    });

    _checkAndStartLocationUpdates(); // Checking permissions before starting the map
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _backupTimer?.cancel(); // stop the backup timer when disposing
    super.dispose();
  }

  Future<void> _checkAndStartLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      openAppSettings();
      return;
    }
    await initializeService();
    _startLocationUpdates();
  }

  // this method gets start location and continuously checks terpiez locations
  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      openAppSettings();
      return;
    }

    Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) async {
      LatLng newPosition = LatLng(position.latitude, position.longitude);

      // use our in-memory cache of terpiez
      if (_terpiezCache.isEmpty) return;
      final userData = Provider.of<Userdata>(context, listen: false);

      // filter out any already-caught terpiez
      final available = _terpiezCache.where((t) {
        final id = t['id'] as String;
        final lat = t['latitude'] as double;
        final lon = t['longitude'] as double;
        return !userData.caughtList.any((c) =>
            c.id == id &&
            c.locations.any((l) =>
                (l.latitude - lat).abs() < 0.0001 &&
                (l.longitude - lon).abs() < 0.0001));
      });

      // Find closest Terpiez from available list
      Map<String, dynamic>? closest;
      double minDist = double.infinity;
      for (var t in available) {
        final lat = t['latitude'] as double;
        final lon = t['longitude'] as double;
        final dist = haversine(
          newPosition.latitude,
          newPosition.longitude,
          lat,
          lon,
        );
        if (dist < minDist) {
          minDist = dist;
          closest = t;
        }
      }

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

  // load all terpiez locations and cache them
  Future<void> _loadTerpiezCache() async {
    final raw = await _redisInfo.getTerpiezLocations();
    final cache = <Map<String, dynamic>>[];
    for (final loc in raw) {
      final id = loc['id'] as String;
      final lat = loc['latitude'] as double;
      final lon = loc['longitude'] as double;
      final info = await _redisInfo.getTerpiezInfo(id);
      cache.add({
        'id': id,
        'latitude': lat,
        'longitude': lon,
        'name': info['name'] ?? 'Unknown',
      });
    }
    setState(() {
      _terpiezCache = cache;
    });
  }

  // start a periodic timer to back up user data to redis ever 30 seconds
  void _startPeriodicBackup() {
    _backupTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final storage = const FlutterSecureStorage();
      final username = await storage.read(key: 'redisUsername');
      if (username != null) {
        final userData = Provider.of<Userdata>(context, listen: false);
        await backupUserDataToRedis(username, userData);
      }
    });
  }

  Future<void> _catchTerpiez(BuildContext context) async {
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
    if (alreadyCaught) return;

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

    // Back up to Redis
    final storage = FlutterSecureStorage();
    final username = await storage.read(key: 'redisUsername');
    if (username != null) {
      await backupUserDataToRedis(username, userData);
      await _redisService.disconnect();
    }
    await _redisService.disconnect();

    // pop-up dialog now scrollable and safe in landscape mode
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(dialogContext).size.width * 0.6,
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.4,
                ),
                child: Image.file(
                  File(caught.thumbnailPath),
                  fit: BoxFit.cover,
                ),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget buildPortState(BuildContext context) {
    return Column(
      children: [
        Align(
            alignment: Alignment.topCenter,
            child: Text("Terpiez Finder",
                style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold))),
        Expanded(
          child: GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
                target: _currentPosition ?? LatLng(38.9869, -76.9426),
                zoom: 14.0),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
            onMapCreated: (c) => _mapController = c,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer()),
            },
          ),
        ),

        // Replace Catch button with shake indicator
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Closest Terpiez:"),
            Text(_closestDistance),
            SizedBox(height: 12),
            Icon(Icons.vibration,
                size: 48, color: _canCatch ? Colors.green : Colors.grey),
            SizedBox(height: 8),
            Text(_canCatch ? "Shake to catch" : "Move closer to a Terpiez",
                style: TextStyle(fontSize: 18)),
          ]),
        ),
      ],
    );
  }

  Widget buildLandState(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        flex: 1,
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
              target: _currentPosition ?? LatLng(38.9869, -76.9426),
              zoom: 14.0),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: markers,
          onMapCreated: (c) => _mapController = c,
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text("Terpiez Finder",
              style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold)),
          Text("Closest Terpiez:"),
          Text(_closestDistance, style: TextStyle(fontSize: 24)),
          SizedBox(height: 16),
          Icon(Icons.vibration,
              size: 36, color: _canCatch ? Colors.green : Colors.grey),
          SizedBox(height: 8),
          Text(_canCatch ? "Shake to catch" : "Move closer to a Terpiez",
              style: TextStyle(fontSize: 18)),
        ]),
      ),
    ]);
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
