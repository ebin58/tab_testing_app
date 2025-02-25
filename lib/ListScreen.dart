import 'package:flutter/material.dart';
import 'BugPage.dart';
import 'PlanePage.dart';


class ListScreen extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Column(
        children: [
          Row(
          children: [
            Hero(
              tag: "bugPage",
              child: IconButton(
                icon: Icon(
              Icons.bug_report,
                size:  50
                ),
              onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => BugPage()),
                );
              } ,
            ),
          ), 
          Text("Bug")
          
          ]
          ),
          Row(
            children: [
              Hero(
                tag: "planePage",  
                child:IconButton(
                  icon: Icon(
                Icons.airplanemode_active,
                  size: 50
                ),
                onPressed: (){
                  Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => PlanePage(),
                    )
                  );
                },
                ),
              ),
              Text("Plane")
            ]
          )
        ],
      )
    );
  }
}

