import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'scan_screen.dart';

void main() {
  runApp(SuriVionApp());
}

class SuriVionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuriVion',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SuriVion Waste Scanner"), centerTitle: true),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.recycling, size: 120, color: Colors.green),

            SizedBox(height: 20),

            Text(
              "SuriVion",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Text(
              "Offline Waste Scanner",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),

            SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanScreen()),
                );
              },
              child: Text("Scan Waste", style: TextStyle(fontSize: 20)),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              child: Text("Ask AI Assistant", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
