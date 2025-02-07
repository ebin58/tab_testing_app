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

class MyHomePage extends StatefulWidget{
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Trying to do tabs"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
          tabs: <Widget>[
            Tab(
              icon: Icon(Icons.home), 
              text: "Home Tab",
            ),
            Tab(
              icon: Icon(Icons.icecream_outlined), 
              text: "Pending",
            ),
            Tab(
              icon: Icon(Icons.home), 
              text: "Home Tab",
            ),
          ]
          )
        ),
      ),
    );
  }

}