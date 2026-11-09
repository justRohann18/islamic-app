import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noor - Islamic Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF061014),
        primaryColor: const Color(0xFF10B981),
        cardColor: const Color(0xFF10242D),
        fontFamily: 'Roboto',
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DashboardScreen(),
      const PrayerAnalyticsScreen(),
      const QuranScreen(),
      const TasbeehScreen(),
      const DuasScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E3A44), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF09171E),
          selectedItemColor: const Color(0xFFFFD700),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'Prayer'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Tracker'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: 'Quran'),
            BottomNavigationBarItem(icon: Icon(Icons.touch_app), label: 'Tasbeeh'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Duas'),
          ],
        ),
      ),
    );
  }
}

String getDateKey(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

// ---------------- CARTOON MOSQUE ILLUSTRATION PAINTER ----------------
class CartoonMosquePainter extends CustomPainter {
  final bool isDayTime;
  CartoonMosquePainter({required this.isDayTime});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (!isDayTime) {
      // Cartoon Glowing Stars
      paint.color = Colors.white.withOpacity(0.7);
      final stars = [
        Offset(size.width * 0.12, size.height * 0.18),
        Offset(size.width * 0.28, size.height * 0.10),
        Offset(size.width * 0.48, size.height * 0.22),
        Offset(size.width * 0.65, size.height * 0.12),
        Offset(size.width * 0.88, size.height * 0.25),
        Offset(size.width * 0.75, size.height * 0.35),
      ];
      for (var s in stars) {
        canvas.drawCircle(s, 2.2, paint);
      }

      // Cartoon Crescent Moon
      paint.color = const Color(0xFFFFE066);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.24), 22, paint);
      paint.color = const Color(0xFF1A1245); // Cutout to make crescent
      canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.21), 20, paint);
    } else {
      // Cartoon Glowing Sun with Soft Halos
      paint.color = const Color(0xFFFFD700).withOpacity(0.2);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.26), 38, paint);
      paint.color = const Color(0xFFFFD700).withOpacity(0.4);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.26), 28, paint);
      paint.color = const Color(0xFFFFEA79);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.26), 20, paint);
    }

    // Back Rolling Cartoon Hills
    paint.color = isDayTime ? const Color(0xFF0A4D44).withOpacity(0.55) : const Color(0xFF121C36).withOpacity(0.7);
    final hill1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.54, size.width * 0.62, size.height * 0.76)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.88, size.width, size.height * 0.68)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill1, paint);

    // Front Darker Cartoon Hills
    paint.color = isDayTime ? const Color(0xFF06322D).withOpacity(0.85) : const Color(0xFF091224).withOpacity(0.92);
    final hill2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.84)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.94, size.width * 0.72, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.90, size.height * 0.66, size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill2, paint);

    // Cartoon Mosque Silhouette (Right Side)
    final mosqueColor = isDayTime ? const Color(0xFF04221F) : const Color(0xFF050A14);
    paint.color = mosqueColor;

    double mx = size.width * 0.74;
    double my = size.height * 0.78;

    // Main Mosque Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mx, my + 12), width: 78, height: 34), const Radius.circular(6)),
      paint,
    );

    // Main Center Golden/Dark Dome
    paint.color = const Color(0xFFFFD700).withOpacity(0.85);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(mx, my - 4), width: 48, height: 44),
      3.14159,
      3.14159,
      true,
      pain
