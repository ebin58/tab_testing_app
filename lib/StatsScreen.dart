// **** For testing ****
// import 'dart:convert';
// import 'redisService.dart';
// import 'redisTerpiezInfo.dart';
// import 'terpiezLocationHelper.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'userData.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? firstLocation;
  // **** For testing ****
  // bool _loading = true;
  // late RedisService redisService;
  // late Redisterpiezinfo redisInfo;

  @override
  void initState() {
    super.initState();
    // **** For testing ****
    // redisService = RedisService();
    // redisInfo = Redisterpiezinfo(redisService);
    // getFirstTerpiezLocation();
  }
  // **** For testing ****
  // Future<void> getFirstTerpiezLocation() async {
  //   await redisService.ensureConnected();
  //   final location = await fetchFirstTerpiezWithName(redisInfo);

  //   setState(() {
  //     firstLocation = location;
  //     _loading = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              "Statistics",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
          Consumer<Userdata>(
            builder: (context, userData, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Terpiez Caught: ${userData.numCaught}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Days Active: ${userData.dayPlayed}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'User id: ${userData.playerID}',
                    style: TextStyle(fontSize: 18),
                  ),
                  // **** For testing ****
                  // SizedBox(height: 10),
                  // _loading
                  //     ? Text("Loading first Terpiez location...")
                  //     : firstLocation != null
                  //         ? Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children : [
                  //             Text(
                  //               'First Terpiez Location: (${firstLocation!['latitude']}, ${firstLocation!['longitude']})'
                  //               '\nTerpiez ID: ${firstLocation!['id']}'
                  //               '\nTerpiez Name: ${firstLocation!['name']}',
                  //               style: TextStyle(fontSize: 18),
                  //             ),
                  //             SizedBox(height: 10),
                  //             firstLocation!['image64'] != null
                  //                 ? Image.memory(
                  //                     base64Decode(firstLocation!['image64']),
                  //                     width: 150,
                  //                     height: 150,
                  //                   )
                  //                 : Text("No image available for this Terpiez."),
                  //           ],
                  //         )
                  //       : Text(
                  //           'No Terpiez location data found.',
                  //           style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                  //         ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
