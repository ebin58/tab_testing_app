import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RedisLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const RedisLoginScreen({super.key, required this.onLoginSuccess});

  @override
  RedisLoginScreenState createState() => RedisLoginScreenState();
}

class RedisLoginScreenState extends State<RedisLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secureStorage = FlutterSecureStorage();

  void _submitCredentials() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isNotEmpty && password.isNotEmpty) {
      await _secureStorage.write(key: 'redisUsername', value: username);
      await _secureStorage.write(key: 'redisPassword', value: password);

      widget.onLoginSuccess(); // Notify app to continue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Enter Redis Credentials", style: TextStyle(fontSize: 24)),
                SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: "Username"),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Password"),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitCredentials,
                  child: Text("Save & Continue"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
