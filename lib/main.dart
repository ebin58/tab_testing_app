import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'StatsScreen.dart';
import 'ListScreen.dart';
import 'FinderScreen.dart';
import 'userData.dart';
import 'redisLogin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userData = Userdata();
  await userData.initUserdata();

  runApp(ChangeNotifierProvider.value(
    value: userData,
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loadedCred = false;
  @override
  void initState() {
    // **** For testing ****
    // debugPrint("HELLLLLOOOOOOOO");
    super.initState();
    checkCreds();
  }

  // Checks if Redis credentials exist in secure storage
  Future<void> checkCreds() async {
    final storage = FlutterSecureStorage();
    String? username = await storage.read(key: 'redisUsername');
    String? password = await storage.read(key: 'redisPassword');

    setState(() {
      loadedCred = (username != null && password != null);
    });
  }

  // will be called after successful login input
  void onLoginSuccess() {
    setState(() {
      loadedCred = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tab test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: loadedCred
          ? const MyHomePage() // show full app only if credentials exist
          : RedisLoginScreen(
              onLoginSuccess: onLoginSuccess), // otherwise show login prompt
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
        body:
            TabBarView(children: [StatsScreen(), FinderScreen(), ListScreen()]),
      ),
    ));
  }
}
