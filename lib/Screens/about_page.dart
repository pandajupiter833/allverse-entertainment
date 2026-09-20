import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text(
          "About",
          style: TextStyle(color: Color(0xFF4A2A00)),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Cinema App",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Cinema App is an IMDb-style entertainment browser built with Flutter.\n"
              "It helps users discover Movies, TV Series, Anime, and Games in one place.\n\n"
              "The app fetches real-time data from public APIs and displays details like posters, ratings, genres, and descriptions.\n"
              "Users can search titles, save items to Favorites and Watch Later, and share opinions by posting comments.\n\n"
              "For accounts, the app uses Firebase Authentication, and comments are stored in Cloud Firestore so they remain available across logins.\n"
              "Favorites and Watch Later are saved locally on the device for fast access and a smooth user experience.",
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 18),
            Text(
              "Version: 1.0.0",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
