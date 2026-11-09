import 'package:flutter/material.dart';

void main() {
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Islamic App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Prayer Tracker Data
  Map<String, bool> prayers = {
    'Fajr (फज्र)': false,
    'Dhuhr (ज़ुहर)': false,
    'Asr (अस्र)': false,
    'Maghrib (मग़रिब)': false,
    'Isha (ईशा)': false,
  };

  @override
  Widget build(BuildContext context) {
    int completed = prayers.values.where((e) => e).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌙 My Islamic App', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.teal[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress Card
            Card(
              color: Colors.teal[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aaj ka Namaz Tracker', 
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text('Apni namazein waqt par ada karein', 
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Text('$completed/5', 
                        style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold, fontSize: 18)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Prayer List
            Expanded(
              child: ListView(
                children: prayers.keys.map((String key) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: CheckboxListTile(
                      activeColor: Colors.teal[800],
                      title: Text(key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      value: prayers[key],
                      onChanged: (bool? value) {
                        setState(() {
                          prayers[key] = value!;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
