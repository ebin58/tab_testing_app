import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'StatsScreen.dart';
import 'ListScreen.dart';
import 'FinderScreen.dart';
import 'userData.dart';
import 'redisLogin.dart';
import 'redisService.dart';
import 'preferences.dart';

// a global key so we can show SnackBars from anywhere
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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

  // Redis‐probe fields:
  final RedisService _redisService = RedisService();
  Timer? _probeTimer;
  bool _wasConnected = false;

  @override
  void initState() {
    super.initState();
    checkCreds();

    // start our connectivity probes immediately and every 10 seconds
    _startRedisProbes();
  }

  @override
  void dispose() {
    _probeTimer?.cancel();
    super.dispose();
  }

  Future<void> checkCreds() async {
    final storage = FlutterSecureStorage();
    String? username = await storage.read(key: 'redisUsername');
    String? password = await storage.read(key: 'redisPassword');

    setState(() {
      loadedCred = (username != null && password != null);
    });
  }

  void onLoginSuccess() {
    setState(() {
      loadedCred = true;
    });
  }

  // Kick off an immediate check, then schedule every 10 seconds
  void _startRedisProbes() {
    _checkRedis();
    _probeTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _checkRedis());
  }

  // Run ensureConnected() (1 s timeout inside RedisService) and
  // show a SnackBar on state changes.
  Future<void> _checkRedis() async {
    final ok = await _redisService.ensureConnected();
    if (ok && !_wasConnected) {
      _wasConnected = true;
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("Connection to Redis restored"),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!ok && _wasConnected) {
      _wasConnected = false;
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("Lost connection to Redis server"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tab test',
      scaffoldMessengerKey: rootScaffoldMessengerKey, // wire up the key
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: loadedCred
          ? const MyHomePage() // show full app only if credentials exist
          : RedisLoginScreen(onLoginSuccess: onLoginSuccess),
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
            title: const Text("Terpiez"),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: const TabBar(tabs: [
              Tab(icon: Icon(Icons.auto_graph), text: "Stats"),
              Tab(icon: Icon(Icons.search), text: "Finder"),
              Tab(icon: Icon(Icons.list), text: "List"),
            ]),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.deepPurple),
                  child: Text('Menu',
                      style: TextStyle(color: Colors.white, fontSize: 24)),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Preferences'),
                  onTap: () {
                    Navigator.pop(context); // close drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PreferencesScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [StatsScreen(), FinderScreen(), ListScreen()],
          ),
        ),
      ),
    );
  }
}
