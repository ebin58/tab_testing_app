import 'dart:async';
import 'package:flutter/material.dart';

class PlanePage extends StatefulWidget {
  @override
  PlanePageState createState() => PlanePageState();
}

class PlanePageState extends State<PlanePage> {
  List<double> barOffsets = [100, 200, 300, 400, 500]; // Initial vertical positions
  List<bool> movingUp = [true, false, true, false, true]; // Track movement direction

  @override
  void initState() {
    super.initState();

    // Timer to move bars up and down
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        for (int i = 0; i < barOffsets.length; i++) {
          if (movingUp[i]) {
            barOffsets[i] -= 10.0; // Move up
            if (barOffsets[i] < 50) movingUp[i] = false; // Change direction at top limit
          } else {
            barOffsets[i] += 10.0; // Move down
            if (barOffsets[i] > MediaQuery.of(context).size.height - 100) movingUp[i] = true; // Change direction at bottom limit
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plane"),
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: "planePage",
                  child: Icon(
                    Icons.airplanemode_active,
                    size: 100,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Plane",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ...List.generate(
            barOffsets.length,
            (index) => AnimatedPositioned(
              duration: Duration(milliseconds: 100),
              left: 50 + index * 60, // Keep horizontal positions fixed
              top: barOffsets[index], // Move bars up and down
              child: Container(
                width: 100,
                height: 20,
                color: Color.fromARGB(255, 8, 106, 23),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text("Plane"),
          ),
        ],
      ),
    );
  }
}
