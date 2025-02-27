import 'package:flutter/material.dart';
import 'userData.dart';
import 'package:provider/provider.dart';


class StatsScreen extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return Scaffold(
          body: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Text("Statistics", 
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  )
                )
              ),
                Consumer<Userdata>(
                  builder: (context, userData, child){
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Terpiez Caught: ${Provider.of<Userdata>(context).numCaught}",
                          style: TextStyle(
                          fontSize: 18,  
                          fontWeight: FontWeight.bold
                          ),
                        ),
                        Text('Days Active: ${userData.dayPlayed}', 
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        Text('User id: ${userData.playerID}',
                          style: TextStyle(
                            fontSize: 18
                          ),
                        )
                      ],
                    );
                  }
                )
            ]
          ),
        );
    }
  }