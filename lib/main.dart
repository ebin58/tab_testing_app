import 'package:flutter/material.dart';
import 'StatsScreen.dart';
import 'ListScreen.dart';
import 'FinderScreen.dart';


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
      initialIndex: 0,
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





// class BugPage extends StatelessWidget{

//   @override
//   Widget build(BuildContext context) {
    
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Bug"), 
//       body: Column(
//         children: [
//           Align(
//             alignment: Alignment.topCenter,
//             child: Hero(
//               tag:"bugPage",
//               child: Icon(
//             Icons.bug_report,
//               size: 100,
//             ),
//           ),
//         ),
//         Text("Bug")
//         ]
//       ),
//     );
//   }
// }

