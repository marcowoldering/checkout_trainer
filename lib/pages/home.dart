import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/dartbord.jpg'), // Path to your image
            fit: BoxFit.cover, // Makes the image cover the entire background
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7), // Semi-transparent background
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Checkout Trainer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto', // Specify a custom font if needed
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to TrainerPage
                        Navigator.pushNamed(context, '/trainer');
                      },
                      icon: Icon(Icons.sports),
                      label: Text("Start Training"),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to CheckoutsPage
                        Navigator.pushNamed(context, '/checkouts');
                      },
                      icon: Icon(Icons.view_list),
                      label: Text("Checkouts"),
                    ),
                    // SizedBox(height: 20),
                    // ElevatedButton.icon(
                    //   onPressed: () {
                    //     // Navigate to SettingsPage
                    //     Navigator.pushNamed(context, '/settings');
                    //   },
                    //   icon: Icon(Icons.settings),
                    //   label: Text("Settings"),
                    // ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
