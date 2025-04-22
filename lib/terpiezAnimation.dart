import 'dart:async';
import 'package:flutter/material.dart';

class TerpiezBarsAnimation extends StatefulWidget {
  const TerpiezBarsAnimation({Key? key}) : super(key: key);

  @override
  _TerpiezBarsAnimationState createState() => _TerpiezBarsAnimationState();
}

class _TerpiezBarsAnimationState extends State<TerpiezBarsAnimation> {
  List<double> barOffsets = [100, 200, 300, 400, 500];
  List<bool> movingUp = [true, false, true, false, true];

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        for (int i = 0; i < barOffsets.length; i++) {
          if (movingUp[i]) {
            barOffsets[i] -= 10.0;
            if (barOffsets[i] < 50) movingUp[i] = false;
          } else {
            barOffsets[i] += 10.0;
            if (barOffsets[i] > MediaQuery.of(context).size.height - 100) {
              movingUp[i] = true;
            }
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(
        barOffsets.length,
        (index) => AnimatedPositioned(
          duration: Duration(milliseconds: 100),
          left: 50 + index * 60,
          top: barOffsets[index],
          child: Container(
            width: 100,
            height: 20,
            color: Color.fromARGB(255, 8, 106, 23),
          ),
        ),
      ),
    );
  }
}
