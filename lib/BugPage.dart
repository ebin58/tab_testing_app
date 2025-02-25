import 'package:flutter/material.dart';
import 'dart:async';


class BugPage extends StatefulWidget{

    @override
    BugPageState createState()=> BugPageState();
  
  }
  
  class BugPageState extends State<BugPage> with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    List<double> _barOffsets = [-300, -250, -200, -150, -100]; // Initial positions
  
    @override
    void initState() {
      super.initState();
  
      // Start the animation when the page is opened
      _controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2),
      )..addListener(() {
          setState(() {
            for (int i = 0; i < _barOffsets.length; i++) {
              _barOffsets[i] += 5; // Move the bars across the screen
            }
          });
        });
  
      // Repeat the animation to keep bars moving
      Timer.periodic(Duration(milliseconds: 100), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          for (int i = 0; i < _barOffsets.length; i++) {
            if (_barOffsets[i] > MediaQuery.of(context).size.width) {
              _barOffsets[i] = -300.0; // Reset position when out of bounds
            } else {
              _barOffsets[i] += 20.0; // Move bars forward
            }
          }
        });
      });
  
      _controller.repeat();
    }
  
    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Bug"),
        ),
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Hero(
                tag: "bugIcon",
                child: Icon(
                  Icons.bug_report,
                  size: 100,
                ),
              ),
            ),
            Positioned.fill(
              child: Stack(
                children: List.generate(
                  _barOffsets.length,
                  (index) => AnimatedPositioned(
                    duration: Duration(milliseconds: 100),
                    left: _barOffsets[index],
                    top: 100 + index * 50,
                    child: Container(
                      width: 100,
                      height: 20,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }