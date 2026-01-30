import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: SettingsPage()));
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _TrainerPageState();
}

class _TrainerPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Text('Settings'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to TrainerPage
                Navigator.pop(context);
              },
              child: const Text("Back"),
            ),
          ],
        )
      ),
    );
  }
}
