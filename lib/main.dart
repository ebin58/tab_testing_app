import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tab test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
            title: Text("Terpiez"),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: TabBar(tabs: [
              Tab(
                icon: Icon(Icons.auto_graph),
                text: "Stats",
              ),
              Tab(
                icon: Icon(Icons.search),
                text: "Finder",
              ),
              Tab(
                icon: Icon(Icons.list),
                text: "List",
              ),
            ])),
        body: TabBarView(children: [
          StatsScreen(),
          FinderScreen(),
          ListScreen()
        ]),
      ),
    ));
  }
}

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
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                children: [
                  Text("   Terpiez found: 23",
                  style: TextStyle(
                    fontSize: 18  
                  ),
                  ),
                  Text("Days Active: 24", 
                  style: TextStyle(
                    fontSize: 18
                  )
                  )
                ],
              )
            )
          ]
        ),
      );
  }
}

class FinderScreen extends StatelessWidget{

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation){
          final s = orientation == Orientation.portrait ? PortState() : LandState();
          return Padding(
          padding: EdgeInsets.all(10),
          child: s,
        );
        }
      )
    );
  }
}

class PortState extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Text("Terpiez Finder", 
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.bold,
            )
          )
        ),
        Icon(
          Icons.map_rounded,
          size: 400
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            children: [
              Text("Closest Terpiez:"),
              Text("124.0m")
            ],
          )
        )
      ],
    );
  }
}

class LandState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Icon(
            Icons.map_rounded,
            size: 150,
          ),

          Expanded(
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


class ListScreen extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Column(
        children: [
          Row(
          children: [
            IconButton(
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
          Text("Bug")
          ]
          ),
          Row(
            children: [
              IconButton(
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
              Text("Plane")
            ]
          )
        ],
      )
    );
  }
}


class BugPage extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Bug"),
      ),
      body: Column(
        children: [Align(
          alignment: Alignment.topCenter,
          child: Icon(
            Icons.bug_report,
            size: 100,
          ),
        ),
        Text("Bug")
        ]
      ),
    );
  }
}

class PlanePage extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Plane"),
      ),
      body: Column(
        children: [Align(
          alignment: Alignment.topCenter,
          child: Icon(
            Icons.airplanemode_active,
            size: 100,
          ),
        ),
        Text("Plane")
        ]
      ),
    );
  }
}