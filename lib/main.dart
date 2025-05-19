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
import 'notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// a global key so we can show SnackBars from anywhere
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  await initializeNotifications();

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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final VoidCallback _finderListener;

  @override
  void initState() {
    super.initState();

    // start on Stats tab
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);

    // handle cold‑start intent once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (consumeNotificationIntent() == 'finder') {
        _tabController.animateTo(1);
        debugPrint('navigated to finder tab (cold start)');
      }
    });

    // react to every notification tap at runtime
    _finderListener = () {
      _tabController.animateTo(1);
      debugPrint('navigated to finder tab (runtime tap)');
    };
    finderTapNotifier.addListener(_finderListener);
  }

  @override
  void dispose() {
    finderTapNotifier.removeListener(_finderListener);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Terpiez"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.auto_graph), text: "Stats"),
              Tab(icon: Icon(Icons.search), text: "Finder"),
              Tab(icon: Icon(Icons.list), text: "List"),
            ],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.deepPurple),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Preferences'),
                onTap: () {
                  Navigator.pop(context);
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
          controller: _tabController,
          children: [
            StatsScreen(),
            FinderScreen(),
            ListScreen(),
          ],
        ),
      ),
    );
  }
}
