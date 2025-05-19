import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'userData.dart';
import 'main.dart'; // needed to call runApp with MyApp

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preferences")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text("Clear All Data"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _confirmClearDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("This will erase your progress and start over."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // cancel means u close the popup
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // close dialog first
              await _clearAllUserData(context);
              final newUserData = Userdata();
              await newUserData.initUserdata();
              runApp(ChangeNotifierProvider.value(
                value: newUserData,
                child: const MyApp(),
              ));
            },
            child: const Text("I understand and all my data will be gone"),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllUserData(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final dir = await getApplicationDocumentsDirectory();

    final newUserId = const Uuid().v4();
    await prefs.setString('playerID', newUserId);
    await prefs.setInt('dayPlayed', 0);
    await prefs.setInt('numCaught', 0);
    await prefs.remove('firstLogin');

    final files = dir.listSync();
    for (final file in files) {
      if (file is File &&
          (file.path.endsWith('.json') || file.path.endsWith('.png'))) {
        await file.delete();
      }
    }
  }
}
