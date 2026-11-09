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
      paint,
    );
    // Dome Spire
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(mx, my - 26), Offset(mx, my - 35), paint);

    // Side Mini Domes
    paint.color = mosqueColor;
    canvas.drawArc(Rect.fromCenter(center: Offset(mx - 24, my - 2), width: 22, height: 20), 3.14159, 3.14159, true, paint);
    canvas.drawArc(Rect.fromCenter(center: Offset(mx + 24, my - 2), width: 22, height: 20), 3.14159, 3.14159, true, paint);

    // Tall Minaret Left
    canvas.drawRect(Rect.fromLTWH(mx - 46, my - 52, 9, 78), paint);
    paint.color = const Color(0xFFFFD700);
    canvas.drawArc(Rect.fromLTWH(mx - 46, my - 58, 9, 12), 3.14159, 3.14159, true, paint);

    // Tall Minaret Right
    paint.color = mosqueColor;
    canvas.drawRect(Rect.fromLTWH(mx + 37, my - 52, 9, 78), paint);
    paint.color = const Color(0xFFFFD700);
    canvas.drawArc(Rect.fromLTWH(mx + 37, my - 58, 9, 12), 3.14159, 3.14159, true, paint);

    // Glowing Cartoon Windows inside Mosque
    paint.color = const Color(0xFFFFD700).withOpacity(0.9);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mx - 12, my + 8), width: 6, height: 12), const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mx, my + 8), width: 8, height: 14), const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mx + 12, my + 8), width: 6, height: 12), const Radius.circular(4)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- 1. ILLUSTRATED PRAYER & LIVE COUNTDOWN SCREEN ----------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String locationName = 'Rupahi';
  double lat = 26.4167;
  double lon = 92.7333;
  String hijriDate = 'Loading...';
  String sunriseTime = '05:45';
  String sunsetTime = '17:50';
  String midnightTime = '23:45';
  bool isLoading = true;

  // Live Countdown Timer variables
  Timer? _countdownTimer;
  String nextPrayerName = 'Fajr';
  String countdownText = '00 : 00 : 00';
  double countdownProgress = 0.5;

  // Settings
  bool autoSettings = false;
  int calcMethod = 1;
  int asrSchool = 0; // 0 = SHAFI, 1 = HANAFI
  String manualCorrection = '0,0,0,0,0';
  int highLatitudeRule = 1;
  bool showMidnight = false;

  final List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  final Map<String, String> hindiNames = {
    'Fajr': 'फज्र',
    'Dhuhr': 'ज़ुहर',
    'Asr': 'अस्र',
    'Maghrib': 'मग़रिब',
    'Isha': 'ईशा',
  };

  Map<String, String> prayerTimes = {
    'Fajr': '04:45',
    'Dhuhr': '12:05',
    'Asr': '15:30',
    'Maghrib': '17:50',
    'Isha': '19:10',
  };

  Map<String, bool> todayDone = {
    'Fajr': false,
    'Dhuhr': false,
    'Asr': false,
    'Maghrib': false,
    'Isha': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSettingsAndTimings();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateLiveCountdown());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  DateTime? _parseTimeToday(String timeStr, DateTime ref) {
    if (!timeStr.contains(':')) return null;
    try {
      final clean = timeStr.split(' ')[0];
      final parts = clean.split(':');
      return DateTime(ref.year, ref.month, ref.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  void _updateLiveCountdown() {
    final now = DateTime.now();
    DateTime? nextTime;
    DateTime? prevTime;
    String foundNext = 'Fajr';

    for (int i = 0; i < prayerNames.length; i++) {
      String p = prayerNames[i];
      DateTime? pt = _parseTimeToday(prayerTimes[p] ?? '', now);
      if (pt != null && pt.isAfter(now)) {
        nextTime = pt;
        foundNext = p;
        if (i > 0) {
          prevTime = _parseTimeToday(prayerTimes[prayerNames[i - 1]] ?? '', now);
        } else {
          DateTime? ishaYesterday = _parseTimeToday(prayerTimes['Isha'] ?? '', now);
          if (ishaYesterday != null) prevTime = ishaYesterday.subtract(const Duration(days: 1));
        }
        break;
      }
    }

    // If all 5 prayers passed today, next is tomorrow's Fajr
    if (nextTime == null) {
      DateTime? fajrToday = _parseTimeToday(prayerTimes['Fajr'] ?? '', now);
      if (fajrToday != null) {
        nextTime = fajrToday.add(const Duration(days: 1));
        foundNext = 'Fajr';
        prevTime = _parseTimeToday(prayerTimes['Isha'] ?? '', now);
      }
    }

    if (nextTime != null) {
      final diff = nextTime.difference(now);
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');

      double prog = 0.6;
      if (prevTime != null) {
        final totalWindow = nextTime.difference(prevTime).inSeconds;
        final elapsed = now.difference(prevTime).inSeconds;
        if (totalWindow > 0) {
          prog = (elapsed / totalWindow).clamp(0.05, 0.98);
        }
      }

      if (mounted) {
        setState(() {
          nextPrayerName = foundNext;
          countdownText = '$h : $m : $s';
          countdownProgress = prog;
        });
      }
    }
  }

  Future<void> _loadSettingsAndTimings() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = getDateKey(DateTime.now());

    setState(() {
      locationName = prefs.getString('loc_name') ?? 'Rupahi';
      lat = prefs.getDouble('lat') ?? 26.4167;
      lon = prefs.getDouble('lon') ?? 92.7333;
      autoSettings = prefs.getBool('auto_settings') ?? false;
      calcMethod = prefs.getInt('calc_method') ?? 1;
      asrSchool = prefs.getInt('asr_school') ?? 0;
      manualCorrection = prefs.getString('manual_corr') ?? '0,0,0,0,0';
      highLatitudeRule = prefs.getInt('high_lat') ?? 1;
      showMidnight = prefs.getBool('show_midnight') ?? false;

      for (var p in prayerNames) {
        todayDone[p] = prefs.getBool('track_${todayKey}_$p') ?? false;
      }
    });

    await _fetchPrayerTimes();
  }

  Future<void> _detectGPSLocation() async {
    setState(() => isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Kripya apne phone ka GPS (Location) ON karein!');
        setState(() => isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission deny kar di gayi!');
          setState(() => isLoading = false);
          return;
        }
      }

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      lat = pos.latitude;
      lon = pos.longitude;

      final geoUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=14');
      final geoRes = await http.get(geoUrl, headers: {'User-Agent': 'NoorIslamicApp/4.0'});

      String detectedPlace = 'My GPS Location';
      if (geoRes.statusCode == 200) {
        final addr = json.decode(geoRes.body)['address'];
        detectedPlace = addr['town'] ??
            addr['village'] ??
            addr['suburb'] ??
            addr['city'] ??
            addr['county'] ??
            addr['state_district'] ??
            'GPS Location';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loc_name', detectedPlace);
      await prefs.setDouble('lat', lat);
      await prefs.setDouble('lon', lon);

      setState(() => locationName = detectedPlace);
      _showSnack('📍 Location Updated: $detectedPlace');
      await _fetchPrayerTimes();
    } catch (e) {
      _showSnack('GPS Error: Khule aasman ke neeche try karein.');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchPrayerTimes() async {
    setState(() => isLoading = true);
    try {
      List<String> parts = manualCorrection.split(',');
      while (parts.length < 5) {
        parts.add('0');
      }
      String tuneParam = '0,${parts[0]},0,${parts[1]},${parts[2]},${parts[3]},0,${parts[4]},0';

      final url = Uri.parse(
          'https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=$calcMethod&school=$asrSchool&latitudeAdjustmentMethod=$highLatitudeRule&tune=$tuneParam');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final timings = data['timings'];
        final hijri = data['date']['hijri'];

        setState(() {
          for (var p in prayerNames) {
            prayerTimes[p] = timings[p].toString().split(' ')[0];
          }
          sunriseTime = timings['Sunrise'].toString().split(' ')[0];
          sunsetTime = timings['Sunset'].toString().split(' ')[0];
          midnightTime = timings['Midnight'].toString().split(' ')[0];
          hijriDate = '${hijri['day']} ${hijri['month']['en']} ${hijri['year']} AH';
          isLoading = false;
        });
        _updateLiveCountdown();
      }
    } catch (e) {
      setState(() {
        hijriDate = '1448 AH';
        isLoading = false;
      });
    }
  }

  Future<void> _toggleTodayPrayer(String prayer, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = getDateKey(DateTime.now());
    await prefs.setBool('track_${todayKey}_$prayer', val);
    setState(() {
      todayDone[prayer] = val;
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF047857)),
    );
  }

  void _openPrayerSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrayerSettingsPage(
          locationName: locationName,
          onDetectGPS: _detectGPSLocation,
        ),
      ),
    );
    _loadSettingsAndTimings();
  }

  // Cartoon Style Theme Icon for each Prayer
  Widget _buildCartoonPrayerAvatar(String prayer, bool isDone, bool isNext) {
    IconData icon = Icons.wb_twilight;
    List<Color> grad = [const Color(0xFFFF8008), const Color(0xFFFFC837)];

    if (prayer == 'Fajr') {
      icon = Icons.wb_twilight;
      grad = [const Color(0xFF6A11CB), const Color(0xFF2575FC)];
    } else if (prayer == 'Dhuhr') {
      icon = Icons.wb_sunny_rounded;
      grad = [const Color(0xFFFF8008), const Color(0xFFFFC837)];
    } else if (prayer == 'Asr') {
      icon = Icons.cloud_queue_rounded;
      grad = [const Color(0xFF11998E), const Color(0xFF38EF7D)];
    } else if (prayer == 'Maghrib') {
      icon = Icons.flare_rounded;
      grad = [const Color(0xFFFF416C), const Color(0xFFFF4B2B)];
    } else if (prayer == 'Isha') {
      icon = Icons.nights_stay_rounded;
      grad = [const Color(0xFF141E30), const Color(0xFF243B55)];
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isNext ? const Color(0xFFFFD700) : Colors.white24, width: isNext ? 2 : 1),
        boxShadow: [
          BoxShadow(color: grad[0].withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Icon(isDone ? Icons.check_circle_rounded : icon, color: Colors.white, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    int completed = todayDone.values.where((v) => v).length;
    bool isDayScene = (nextPrayerName == 'Dhuhr' || nextPrayerName == 'Asr' || nextPrayerName == 'Maghrib');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Date + GPS Pill + Settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assalamu Alaikum 👋', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('🌙 $hijriDate', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _detectGPSLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, color: Colors.white, size: 15),
                            const SizedBox(width: 5),
                            Text(locationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF16323F)),
                      onPressed: _openPrayerSettings,
                      icon: const Icon(Icons.tune, color: Color(0xFFFFD700), size: 20),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🌟 ANIMATED CARTOON MOSQUE & LIVE COUNTDOWN HERO BANNER 🌟
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Container(
                width: double.infinity,
                height: 245,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDayScene
                        ? [const Color(0xFF0F766E), const Color(0xFF047857), const Color(0xFF064E3B)]
                        : [const Color(0xFF1E1B4B), const Color(0xFF1E3A8A), const Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.45), width: 1.5),
                ),
                child: Stack(
                  children: [
                    // Cartoon Mosque & Sky Vector Art Layer
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CartoonMosquePainter(isDayTime: isDayScene),
                      ),
                    ),

                    // Foreground Live Countdown Overlay
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Next Prayer Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.notifications_active, color: Color(0xFFFFD700), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'NEXT: ${nextPrayerName.toUpperCase()} (${prayerTimes[nextPrayerName]})',
                                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Giant Ticking Countdown Clock
                          const Text('Agli Namaz mein baqi waqt:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '- $countdownText',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3))],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isLoading)
                                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700))),
                            ],
                          ),
                          const Spacer(),

                          // Progress Bar to Next Prayer
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: countdownProgress,
                              minHeight: 7,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Sunrise / Sunset / Fiqh Mini Strip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.wb_sunny, color: Color(0xFFFFD700), size: 16),
                                    const SizedBox(width: 5),
                                    Text('Sunrise: $sunriseTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.wb_twilight, color: Colors.orangeAccent, size: 16),
                                    const SizedBox(width: 5),
                                    Text('Sunset: $sunsetTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Text(
                                  asrSchool == 0 ? 'SHAFI' : 'HANAFI',
                                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Daily Tracker Mini Gamified Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                    child: Text('$completed/5', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aaj ka Namaz Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          completed == 5 ? 'MashaAllah! 5/5 Namaz Mukammal 🌟' : 'Namaz padhne ke baad neeche switch ON karein',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🕌 Aaj ke Namaz Timings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                GestureDetector(
                  onTap: _openPrayerSettings,
                  child: const Text('⚙️ Change Fiqh/Method', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5 Cartoon-Styled Prayer Cards
            ...prayerNames.map((String key) {
              bool isDone = todayDone[key] ?? false;
              bool isNext = (key == nextPrayerName);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isNext
                      ? const LinearGradient(colors: [Color(0xFF163C35), Color(0xFF0D2329)])
                      : LinearGradient(colors: [const Color(0xFF10242D), const Color(0xFF0C1C24)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isNext
                        ? const Color(0xFFFFD700)
                        : (isDone ? const Color(0xFF10B981) : Colors.white10),
                    width: isNext ? 1.8 : 1,
                  ),
                  boxShadow: isNext
                      ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Row(
                  children: [
                    _buildCartoonPrayerAvatar(key, isDone, isNext),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$key (${hindiNames[key]})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                              if (isNext) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('NEXT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Azan Waqt: ${prayerTimes[key]}',
                            style: TextStyle(
                              color: isNext ? const Color(0xFFFFD700) : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Switch(
                          activeColor: const Color(0xFFFFD700),
                          activeTrackColor: const Color(0xFF10B981),
                          value: isDone,
                          onChanged: (val) => _toggleTodayPrayer(key, val),
                        ),
                        Text(
                          isDone ? 'Ada ✅' : 'Pending',
                          style: TextStyle(fontSize: 10, color: isDone ? const Color(0xFF10B981) : Colors.white38),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),

            if (showMidnight)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16323F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.nights_stay, color: Color(0xFFFFD700)),
                        SizedBox(width: 10),
                        Text('Islamic Midnight Time', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(midnightTime, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- SCREENSHOT-STYLE VIP PRAYER SETTINGS PAGE ----------------
class PrayerSettingsPage extends StatefulWidget {
  final String locationName;
  final VoidCallback onDetectGPS;

  const PrayerSettingsPage({super.key, required this.locationName, required this.onDetectGPS});

  @override
  State<PrayerSettingsPage> createState() => _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends State<PrayerSettingsPage> {
  late String locName;
  bool autoSettings = false;
  int calcMethod = 1;
  int asrSchool = 0;
  String manualCorrection = '0,0,0,0,0';
  int highLatitudeRule = 1;
  bool showMidnight = false;

  final Map<int, Map<String, String>> methods = {
    1: {'name': 'University of Islamic Sciences, Karachi', 'deg': 'Fajr: 18.0° / Isha: 18.0°'},
    4: {'name': 'Umm Al-Qura University, Makkah', 'deg': 'Fajr: 18.5° / Isha: 90 min'},
    3: {'name': 'Muslim World League (MWL)', 'deg': 'Fajr: 18.0° / Isha: 17.0°'},
    2: {'name': 'Islamic Society of North America (ISNA)', 'deg': 'Fajr: 15.0° / Isha: 15.0°'},
    5: {'name': 'Egyptian General Authority of Survey', 'deg': 'Fajr: 19.5° / Isha: 17.5°'},
  };

  final Map<int, String> highLatRules = {
    1: 'Middle Of The Night',
    2: 'One Seventh Of The Night',
    3: 'Angle Based Method',
  };

  @override
  void initState() {
    super.initState();
    locName = widget.locationName;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      locName = prefs.getString('loc_name') ?? widget.locationName;
      autoSettings = prefs.getBool('auto_settings') ?? false;
      calcMethod = prefs.getInt('calc_method') ?? 1;
      asrSchool = prefs.getInt('asr_school') ?? 0;
      manualCorrection = prefs.getString('manual_corr') ?? '0,0,0,0,0';
      highLatitudeRule = prefs.getInt('high_lat') ?? 1;
      showMidnight = prefs.getBool('show_midnight') ?? false;
    });
  }

  Future<void> _savePref(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is bool) await prefs.setBool(key, val);
    if (val is int) await prefs.setInt(key, val);
    if (val is String) await prefs.setString(key, val);
  }

  void _editLocationDialog() {
    TextEditingController ctrl = TextEditingController(text: locName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10242D),
        title: const Text('Location Setup', style: TextStyle(color: Color(0xFFFFD700))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                Navigator.pop(ctx);
                widget.onDetectGPS();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.my_location, color: Colors.white),
              label: const Text('Auto Detect via Google/GPS', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 14),
            const Text('Ya sheher/gaon ka naam likhein:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Rupahi, Nagaon, Assam',
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              String place = ctrl.text.trim();
              if (place.isNotEmpty) {
                final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$place&format=json&limit=1');
                final res = await http.get(url, headers: {'User-Agent': 'NoorIslamicApp/4.0'});
                if (res.statusCode == 200) {
                  final list = json.decode(res.body) as List;
                  if (list.isNotEmpty) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setDouble('lat', double.parse(list[0]['lat']));
                    await prefs.setDouble('lon', double.parse(list[0]['lon']));
                  }
                }
                await _savePref('loc_name', place);
                setState(() => locName = place);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editManualCorrectionDialog() {
    TextEditingController ctrl = TextEditingController(text: manualCorrection);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10242D),
        title: const Text('Manual Correction (Minutes)', style: TextStyle(color: Color(0xFFFFD700))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Format: Fajr,Dhuhr,Asr,Maghrib,Isha\nExample: 0,2,0,-1,0', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(controller: ctrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => manualCorrection = ctrl.text.trim());
              _savePref('manual_corr', manualCorrection);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Time', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF047857), Color(0xFF0F2932)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildSettingCard(
            title: 'Location',
            subtitle: locName,
            icon: Icons.location_on,
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFFFD700)),
            onTap: _editLocationDialog,
          ),
          _buildSettingCard(
            title: 'Automatic Settings',
            subtitle: autoSettings ? 'Enabled' : 'Custom settings',
            icon: Icons.hdr_auto,
            trailing: Switch(
              activeColor: const Color(0xFFFFD700),
              activeTrackColor: const Color(0xFF10B981),
              value: autoSettings,
              onChanged: (val) {
                setState(() {
                  autoSettings = val;
                  if (val) {
                    calcMethod = 1;
                    manualCorrection = '0,0,0,0,0';
                  }
                });
                _savePref('auto_settings', val);
              },
            ),
          ),
          _buildSettingCard(
            title: 'Prayer Time Conventions',
            subtitle: '${methods[calcMethod]!['name']}\n${methods[calcMethod]!['deg']}',
            icon: Icons.public,
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF10242D),
                builder: (ctx) => ListView(
                  shrinkWrap: true,
                  children: methods.entries.map((e) {
                    return RadioListTile<int>(
                      activeColor: const Color(0xFFFFD700),
                      title: Text(e.value['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(e.value['deg']!, style: const TextStyle(color: Colors.white60)),
                      value: e.key,
                      groupValue: calcMethod,
                      onChanged: (val) {
                        setState(() => calcMethod = val!);
                        _savePref('calc_method', val!);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          _buildSettingCard(
            title: 'Manual Correction',
            subtitle: manualCorrection,
            icon: Icons.tune,
            onTap: _editManualCorrectionDialog,
          ),
          _buildSettingCard(
            title: 'Asr Time Calculation',
            subtitle: asrSchool == 0 ? 'SHAFI' : 'HANAFI',
            icon: Icons.wb_sunny_outlined,
            onTap: () {
              setState(() => asrSchool = asrSchool == 0 ? 1 : 0);
              _savePref('asr_school', asrSchool);
            },
          ),
          _buildSettingCard(
            title: 'High Latitude Adjustment',
            subtitle: highLatRules[highLatitudeRule]!,
            icon: Icons.explore,
            onTap: () {
              setState(() => highLatitudeRule = (highLatitudeRule % 3) + 1);
              _savePref('high_lat', highLatitudeRule);
            },
          ),
          _buildSettingCard(
            title: 'Daylight Saving Time',
            subtitle: 'Auto',
            icon: Icons.schedule,
          ),
          _buildSettingCard(
            title: 'Show Midnight Time',
            subtitle: showMidnight ? 'Enabled' : 'Disabled',
            icon: Icons.dark_mode,
            trailing: Switch(
              activeColor: const Color(0xFFFFD700),
              activeTrackColor: const Color(0xFF10B981),
              value: showMidnight,
              onChanged: (val) {
                setState(() => showMidnight = val);
                _savePref('show_midnight', val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10242D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF16323F),
          child: Icon(icon, color: const Color(0xFFFFD700), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.3)),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

// ---------------- 2. ANALYTICS TRACKER (WEEKLY / MONTHLY / YEARLY) ----------------
class PrayerAnalyticsScreen extends StatefulWidget {
  const PrayerAnalyticsScreen({super.key});

  @override
  State<PrayerAnalyticsScreen> createState() => _PrayerAnalyticsScreenState();
}

class _PrayerAnalyticsScreenState extends State<PrayerAnalyticsScreen> {
  int selectedPeriod = 0;
  DateTime selectedDate = DateTime.now();
  SharedPreferences? _prefs;
  final List<String> prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  int _getCountForDate(DateTime date) {
    if (_prefs == null) return 0;
    String key = getDateKey(date);
    int c = 0;
    for (var p in prayers) {
      if (_prefs!.getBool('track_${key}_$p') ?? false) c++;
    }
    return c;
  }

  bool _isPrayerDoneOnDate(DateTime date, String prayer) {
    if (_prefs == null) return false;
    return _prefs!.getBool('track_${getDateKey(date)}_$prayer') ?? false;
  }

  Future<void> _togglePrayerOnDate(DateTime date, String prayer) async {
    if (_prefs == null) return;
    String k = 'track_${getDateKey(date)}_$prayer';
    bool current = _prefs!.getBool(k) ?? false;
    await _prefs!.setBool(k, !current);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    int weeklyTotal = 0;
    for (int i = 0; i < 7; i++) {
      weeklyTotal += _getCountForDate(now.subtract(Duration(days: i)));
    }

    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    int monthlyTotal = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      monthlyTotal += _getCountForDate(DateTime(now.year, now.month, d));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Namaz Analytics & Report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 4),
            const Text('Apni Weekly, Monthly aur Yearly Namaz report dekhein', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  _buildTabButton('Weekly (7D)', 0),
                  _buildTabButton('Monthly', 1),
                  _buildTabButton('Yearly (12M)', 2),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard('This Week', '$weeklyTotal / 35', '${((weeklyTotal / 35) * 100).toInt()}% Ada', Icons.trending_up),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard('This Month', '$monthlyTotal / ${daysInMonth * 5}', '${((monthlyTotal / (daysInMonth * 5)) * 100).toInt()}% Ada', Icons.calendar_month),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selectedPeriod == 0) _buildWeeklyChart(now),
            if (selectedPeriod == 1) _buildMonthlyCalendar(now, daysInMonth),
            if (selectedPeriod == 2) _buildYearlyReport(now),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📅 Date Record: ${getDateKey(selectedDate)}', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${_getCountForDate(selectedDate)}/5 Completed', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: prayers.map((p) {
                      bool done = _isPrayerDoneOnDate(selectedDate, p);
                      return GestureDetector(
                        onTap: () => _togglePrayerOnDate(selectedDate, p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: done ? const Color(0xFF10B981) : const Color(0xFF16323F),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: done ? const Color(0xFFFFD700) : Colors.white12),
                          ),
                          child: Column(
                            children: [
                              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Colors.white : Colors.white54, size: 18),
                              const SizedBox(height: 4),
                              Text(p, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool active = selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPeriod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF10B981) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(color: active ? Colors.white : Colors.white60, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String score, String percent, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF16323F), Color(0xFF10242D)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Icon(icon, color: const Color(0xFFFFD700), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(score, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(percent, style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(DateTime now) {
    final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10242D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 Last 7 Days Performance', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                DateTime day = now.subtract(Duration(days: 6 - index));
                int count = _getCountForDate(day);
                bool isSelected = getDateKey(day) == getDateKey(selectedDate);
                double barHeight = (count / 5.0) * 100;
                if (barHeight < 8) barHeight = 8;

                return GestureDetector(
                  onTap: () => setState(() => selectedDate = day),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('$count/5', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      const SizedBox(height: 6),
                      Container(
                        width: 28,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: count == 5
                                ? [const Color(0xFFFFD700), const Color(0xFF10B981)]
                                : [const Color(0xFF10B981), const Color(0xFF047857)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weekDays[day.weekday - 1],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFFFFD700) : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar(DateTime now, int daysInMonth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10242D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🗓️ Monthly Calendar (${now.month}/${now.year})', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              DateTime d = DateTime(now.year, now.month, index + 1);
              int c = _getCountForDate(d);
              bool isSelected = getDateKey(d) == getDateKey(selectedDate);

              Color bgColor = const Color(0xFF16323F);
              if (c == 5) bgColor = const Color(0xFF10B981);
              else if (c >= 3) bgColor = const Color(0xFF047857);
              else if (c >= 1) bgColor = const Color(0xFF064E3B);

              return GestureDetector(
                onTap: () => setState(() => selectedDate = d),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? const Color(0xFFFFD700) : Colors.white12, width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('$c/5', style: const TextStyle(fontSize: 9, color: Colors.white70)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyReport(DateTime now) {
    final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10242D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏆 Yearly Overview (${now.year})', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: 12,
            itemBuilder: (context, mIdx) {
              int m = mIdx + 1;
              int days = DateUtils.getDaysInMonth(now.year, m);
              int total = 0;
              for (int d = 1; d <= days; d++) {
                total += _getCountForDate(DateTime(now.year, m, d));
              }
              int maxPossible = days * 5;
              int pct = ((total / maxPossible) * 100).toInt();

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF16323F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: m == now.month ? const Color(0xFFFFD700) : Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(monthNames[mIdx], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                    const SizedBox(height: 4),
                    Text('$total / $maxPossible', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('$pct% Ada', style: const TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------- 3. QURAN MINI READER SCREEN ----------------
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  final List<Map<String, String>> surahs = const [
    {
      'name': '1. Surah Al-Fatiha (सूरह अल-फ़ातिहा)',
      'ayahs': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۝ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ ۝',
      'translation': 'Shuru Allah ke naam se jo bada meherban nihayat reham wala hai. Sab tareef Allah Ta\'ala ke liye hai jo tamam jahanon ka palne wala hai...'
    },
    {
      'name': '2. Ayat-ul-Kursi (आयतुल कुर्सी)',
      'ayahs': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ...',
      'translation': 'Allah wo hai jiske siwa koi ma\'bood nahi, wo hamesha zinda rehne wala aur sab ko thamne wala hai...'
    },
    {
      'name': '3. Surah Al-Ikhlas (सूरह अल-इख़लास)',
      'ayahs': 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ ۝',
      'translation': 'Keh dijiye ki wo Allah ek hai. Allah be-niyaz hai. Na uski koi aulad hai aur na wo kisi ki aulad hai...'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📖 Al-Quran (Rozana Tilawat)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: surahs.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10242D),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(surahs[index]['name']!, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(color: Colors.white12, height: 24),
                        Text(surahs[index]['ayahs']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 24, color: Colors.white, height: 1.8)),
                        const SizedBox(height: 12),
                        Text(surahs[index]['translation']!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 4. TASBEEH COUNTER ----------------
class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int count = 0;
  int totalAllTime = 0;
  int target = 33;

  @override
  void initState() {
    super.initState();
    _loadTasbeeh();
  }

  Future<void> _loadTasbeeh() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      count = prefs.getInt('tasbeeh_count') ?? 0;
      totalAllTime = prefs.getInt('tasbeeh_total') ?? 0;
    });
  }

  Future<void> _increment() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      count++;
      totalAllTime++;
    });
    await prefs.setInt('tasbeeh_count', count);
    await prefs.setInt('tasbeeh_total', totalAllTime);
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => count = 0);
    await prefs.setInt('tasbeeh_count', 0);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📿 Digital Tasbeeh', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                Text('Total: $totalAllTime', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: _increment,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                  border: Border.all(color: const Color(0xFFFFD700), width: 4),
                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 25)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$count', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Target: $target', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
              label: const Text('Reset Counter'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 5. DAILY DUAS SCREEN ----------------
class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  final List<Map<String, String>> duas = const [
    {
      'title': '1. Sone se pehle ki Dua',
      'arabic': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      'meaning': 'Aye Allah! Main tere hi naam se marta (sota) hoon aur jeeta (jagta) hoon.'
    },
    {
      'title': '2. Ghar se nikalne ki Dua',
      'arabic': 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      'meaning': 'Allah ke naam ke sath, maine Allah par bharosa kiya...'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🤲 Masnoon Duayein', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: duas.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10242D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(duas[index]['title']!, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(duas[index]['arabic']!, style: const TextStyle(fontSize: 24, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        Text(duas[index]['meaning']!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
