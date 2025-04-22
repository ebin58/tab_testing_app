import 'package:flutter/material.dart';
import 'BugPage.dart';
import 'PlanePage.dart';
import 'package:provider/provider.dart';
import 'userData.dart';
import 'dart:io';
import 'TerpiezDetailPage.dart';

class ListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<Userdata>(context);

    return Scaffold(
      appBar: AppBar(title: Text("List")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Hero(
                  tag: "bugPage",
                  child: IconButton(
                    icon: Icon(Icons.bug_report, size: 50),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BugPage()),
                      );
                    },
                  ),
                ),
                Text("Bug"),
              ],
            ),
            Row(
              children: [
                Hero(
                  tag: "planePage",
                  child: IconButton(
                    icon: Icon(Icons.airplanemode_active, size: 50),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PlanePage()),
                      );
                    },
                  ),
                ),
                Text("Plane"),
              ],
            ),
            Divider(height: 30, thickness: 2),
            Text("Caught Terpiez",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ...userData.caughtList.map((terp) => ListTile(
                  leading: Image.file(File(terp.thumbnailPath),
                      width: 50, height: 50),
                  title: Text(terp.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TerpiezDetailPage(terp)),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }
}
