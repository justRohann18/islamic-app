import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:home_widget/home_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      const QiblaCompassScreen(), // NEW: 3D Cartoon Qibla Finder
      const QuranScreen(),
      const TasbeehScreen(),
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
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Qibla'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: 'Quran'),
            BottomNavigationBarItem(icon: Icon(Icons.touch_app), label: 'Tasbeeh'),
          ],
        ),
      ),
    );
  }
}

String getDateKey(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

// Prayer Status Helper (0=None, 1=Jamaat, 2=OnTime, 3=Qaza, 4=Missed)
int getPrayerStatus(SharedPreferences? prefs, DateTime date, String prayer) {
  if (prefs == null) return 0;
  String k = 'status_${getDateKey(date)}_$prayer';
  if (prefs.containsKey(k)) {
    return prefs.getInt(k) ?? 0;
  }
  // Backward compatibility
  bool old = prefs.getBool('track_${getDateKey(date)}_$prayer') ?? false;
  return old ? 1 : 0;
}

bool isPrayerOffered(int status) => status == 1 || status == 2 || status == 3;

// Sync Data to Android Home Screen Widget
Future<void> syncHomeScreenWidget({
  required String location,
  required String hijri,
  required String nextPrayer,
  required String nextTime,
  required int completedCount,
  required int jamaatCount,
}) async {
  try {
    await HomeWidget.saveWidgetData<String>('wid_loc', '🌙 $hijri • 📍 $location');
    await HomeWidget.saveWidgetData<String>('wid_next', 'Next: $nextPrayer ($nextTime)');
    await HomeWidget.saveWidgetData<String>(
        'wid_track', 'Today: $completedCount/5 Ada ($jamaatCount in Jamaat) ✅');
    await HomeWidget.updateWidget(
      name: 'PrayerWidgetProvider',
      androidName: 'PrayerWidgetProvider',
    );
  } catch (_) {}
}

// ---------------- CARTOON MOSQUE ILLUSTRATION PAINTER ----------------
class CartoonMosquePainter extends CustomPainter {
  final bool isDayTime;
  CartoonMosquePainter({required this.isDayTime});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (!isDayTime) {
      paint.color = Colors.white.withOpacity(0.7);
      final stars = [
        Offset(size.width * 0.12, size.height * 0.18),
        Offset(size.width * 0.28, size.height * 0.10),
        Offset(size.width * 0.48, size.height * 0.22),
        Offset(size.width * 0.65, size.height * 0.12),
        Offset(size.width * 0.88, size.height * 0.25),
      ];
      for (var s in stars) {
        canvas.drawCircle(s, 2.2, paint);
      }
      paint.color = const Color(0xFFFFE066);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.24), 22, paint);
      paint.color = const Color(0xFF1A1245);
      canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.21), 20, paint);
    } else {
      paint.color = const Color(0xFFFFD700).withOpacity(0.2);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.26), 38, paint);
      paint.color = const Color(0xFFFFD700).withOpacity(0.4);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.26), 28, paint);
      paint.color = const Color(0xFFFFEA79);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.26), 20, paint);
    }

    paint.color = isDayTime ? const Color(0xFF0A4D44).withOpacity(0.55) : const Color(0xFF121C36).withOpacity(0.7);
    final hill1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.54, size.width * 0.62, size.height * 0.76)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.88, size.width, size.height * 0.68)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill1, paint);

    paint.color = isDayTime ? const Color(0xFF06322D).withOpacity(0.85) : const Color(0xFF091224).withOpacity(0.92);
    final hill2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.84)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.94, size.width * 0.72, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.90, size.height * 0.66, size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill2, paint);

    final mosqueColor = isDayTime ? const Color(0xFF04221F) : const Color(0xFF050A14);
    paint.color = mosqueColor;

    double mx = size.width * 0.74;
    double my = size.height * 0.78;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mx, my + 12), width: 78, height: 34), const Radius.circular(6)),
      paint,
    );

    paint.color = const Color(0xFFFFD700).withOpacity(0.85);
    canvas.drawArc(Rect.fromCenter(center: Offset(mx, my - 4), width: 48, height: 44), 3.14159, 3.14159, true, paint);

    paint.color = mosqueColor;
    canvas.drawArc(Rect.fromCenter(center: Offset(mx - 24, my - 2), width: 22, height: 20), 3.14159, 3.14159, true, paint);
    canvas.drawArc(Rect.fromCenter(center: Offset(mx + 24, my - 2), width: 22, height: 20), 3.14159, 3.14159, true, paint);

    canvas.drawRect(Rect.fromLTWH(mx - 46, my - 52, 9, 78), paint);
    paint.color = const Color(0xFFFFD700);
    canvas.drawArc(Rect.fromLTWH(mx - 46, my - 58, 9, 12), 3.14159, 3.14159, true, paint);

    paint.color = mosqueColor;
    canvas.drawRect(Rect.fromLTWH(mx + 37, my - 52, 9, 78), paint);
    paint.color = const Color(0xFFFFD700);
    canvas.drawArc(Rect.fromLTWH(mx + 37, my - 58, 9, 12), 3.14159, 3.14159, true, paint);

    paint.color = const Color(0xFFFFD700).withOpacity(0.9);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mx - 12, my + 8), width: 6, height: 12), const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mx, my + 8), width: 8, height: 14), const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mx + 12, my + 8), width: 6, height: 12), const Radius.circular(4)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- 1. ILLUSTRATED PRAYER & 4-STATUS TRACKER SCREEN ----------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String locationName = 'Rupahi';
  double lat = 26.4167;
  double lon = 92.7333;
  String hijriDate = '1448 AH';
  String sunriseTime = '05:45';
  String sunsetTime = '17:50';
  String midnightTime = '23:45';
  bool isLoading = true;

  Timer? _countdownTimer;
  String nextPrayerName = 'Fajr';
  String countdownText = '00 : 00 : 00';
  double countdownProgress = 0.5;

  bool autoSettings = false;
  int calcMethod = 1;
  int asrSchool = 0;
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

  // Status: 0=Pending, 1=Jamaat, 2=OnTime, 3=Qaza, 4=Missed
  Map<String, int> todayStatus = {
    'Fajr': 0,
    'Dhuhr': 0,
    'Asr': 0,
    'Maghrib': 0,
    'Isha': 0,
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
    final today = DateTime.now();

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
        todayStatus[p] = getPrayerStatus(prefs, today, p);
      }
    });

    await _fetchPrayerTimes();
  }

  Future<void> _pushToWidget() async {
    int completed = todayStatus.values.where((s) => isPrayerOffered(s)).length;
    int jamaat = todayStatus.values.where((s) => s == 1).length;
    await syncHomeScreenWidget(
      location: locationName,
      hijri: hijriDate,
      nextPrayer: nextPrayerName,
      nextTime: prayerTimes[nextPrayerName] ?? '--:--',
      completedCount: completed,
      jamaatCount: jamaat,
    );
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
      final geoRes = await http.get(geoUrl, headers: {'User-Agent': 'NoorIslamicApp/5.0'});

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
          hijriDate = '${hijri['day']} ${hijri['month']['en']} ${hijri['year']}';
          isLoading = false;
        });
        _updateLiveCountdown();
        _pushToWidget();
      }
    } catch (e) {
      setState(() => isLoading = false);
      _pushToWidget();
    }
  }

  Future<void> _setPrayerStatus(String prayer, int status) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = getDateKey(DateTime.now());
    await prefs.setInt('status_${todayKey}_$prayer', status);
    await prefs.setBool('track_${todayKey}_$prayer', isPrayerOffered(status));
    setState(() {
      todayStatus[prayer] = status;
    });
    HapticFeedback.lightImpact();
    _pushToWidget();
  }

  void _showStatusPickerSheet(String prayer) {
    int current = todayStatus[prayer] ?? 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D212A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🕌 $prayer (${hindiNames[prayer]}) Status',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  Text(prayerTimes[prayer] ?? '', style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Aapne aaj yeh namaz kaise ada ki?', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 16),
              _statusOptionTile(ctx, prayer, 1, '🟢 Jamaat ke sath (Masjid/Congregation)', '27x Sawab • Best Performance', const Color(0xFF10B981), current),
              _statusOptionTile(ctx, prayer, 2, '🔵 Waqt par Akele (On Time Alone)', 'Farz Ada ho gaya', const Color(0xFF3B82F6), current),
              _statusOptionTile(ctx, prayer, 3, '🟠 Qaza / Late Ada ki', 'Waqt nikalne ke baad padhi', const Color(0xFFF59E0B), current),
              _statusOptionTile(ctx, prayer, 4, '🔴 Missed (Chhoot gayi / Qaza Baki)', 'Qaza counter mein jud jayegi', const Color(0xFFEF4444), current),
              if (current != 0)
                Center(
                  child: TextButton(
                    onPressed: () {
                      _setPrayerStatus(prayer, 0);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear / Reset Status', style: TextStyle(color: Colors.white54)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusOptionTile(BuildContext ctx, String prayer, int val, String title, String sub, Color col, int current) {
    bool selected = current == val;
    return GestureDetector(
      onTap: () {
        _setPrayerStatus(prayer, val);
        Navigator.pop(ctx);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? col.withOpacity(0.25) : const Color(0xFF142E3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? col : Colors.white12, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white60)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: col),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    switch (status) {
      case 1:
        return _pill('🟢 Jamaat', const Color(0xFF10B981));
      case 2:
        return _pill('🔵 On Time', const Color(0xFF3B82F6));
      case 3:
        return _pill('🟠 Qaza Ada', const Color(0xFFF59E0B));
      case 4:
        return _pill('🔴 Missed', const Color(0xFFEF4444));
      default:
        return _pill('Tap to Log ➕', Colors.white24);
    }
  }

  Widget _pill(String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c, width: 1.2),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
    );
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

  Widget _buildCartoonPrayerAvatar(String prayer, int status, bool isNext) {
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
      ),
      child: Icon(isPrayerOffered(status) ? Icons.check_circle_rounded : icon, color: Colors.white, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    int completed = todayStatus.values.where((s) => isPrayerOffered(s)).length;
    int jamaatCount = todayStatus.values.where((s) => s == 1).length;
    bool isDayScene = (nextPrayerName == 'Dhuhr' || nextPrayerName == 'Asr' || nextPrayerName == 'Maghrib');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
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

            // Animated Cartoon Mosque & Countdown Hero Card
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
                    Positioned.fill(
                      child: CustomPaint(painter: CartoonMosquePainter(isDayTime: isDayScene)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Agli Namaz mein baqi waqt:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
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
                          const Spacer(),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('🌅 Sunrise: $sunriseTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('🌇 Sunset: $sunsetTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text(asrSchool == 0 ? 'SHAFI' : 'HANAFI', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
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
            const SizedBox(height: 16),

            // Home Screen Widget Sync Info Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.widgets_rounded, color: Color(0xFFFFD700), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Today: $completed/5 Ada ($jamaatCount Jamaat) • Home Widget Active 📱',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _pushToWidget();
                      _showSnack('📱 Phone Home Screen Widget Updated!');
                    },
                    child: const Text('Sync', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5 Prayer Cards with 4-Status Picker
            const Text('🕌 Aaj ki Namazein (Tap to set Jamaat / Qaza)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            ...prayerNames.map((String key) {
              int status = todayStatus[key] ?? 0;
              bool isNext = (key == nextPrayerName);

              return GestureDetector(
                onTap: () => _showStatusPickerSheet(key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isNext
                        ? const LinearGradient(colors: [Color(0xFF163C35), Color(0xFF0D2329)])
                        : const LinearGradient(colors: [Color(0xFF10242D), Color(0xFF0C1C24)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isNext ? const Color(0xFFFFD700) : (isPrayerOffered(status) ? const Color(0xFF10B981) : Colors.white10),
                      width: isNext ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildCartoonPrayerAvatar(key, status, isNext),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('$key (${hindiNames[key]})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (isNext) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('NEXT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Azan: ${prayerTimes[key]}', style: TextStyle(color: isNext ? const Color(0xFFFFD700) : Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ---------------- 2. LIVE 3D CARTOON QIBLA COMPASS SCREEN ----------------
class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  double userLat = 26.4167;
  double userLon = 92.7333;
  String locationName = 'Rupahi';
  double qiblaAngle = 277.0; // Default bearing from Assam to Makkah
  double distanceKm = 5120.0;

  @override
  void initState() {
    super.initState();
    _loadLocationAndComputeQibla();
  }

  Future<void> _loadLocationAndComputeQibla() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      locationName = prefs.getString('loc_name') ?? 'Rupahi';
      userLat = prefs.getDouble('lat') ?? 26.4167;
      userLon = prefs.getDouble('lon') ?? 92.7333;
      qiblaAngle = _calculateQiblaBearing(userLat, userLon);
      distanceKm = Geolocator.distanceBetween(userLat, userLon, 21.422487, 39.826206) / 1000.0;
    });
  }

  // Exact Great-Circle Bearing Formula to Holy Kaaba (21.422487° N, 39.826206° E)
  double _calculateQiblaBearing(double lat, double lon) {
    const double kaabaLat = 21.422487 * math.pi / 180.0;
    const double kaabaLon = 39.826206 * math.pi / 180.0;
    double phi = lat * math.pi / 180.0;
    double lam = lon * math.pi / 180.0;

    double y = math.sin(kaabaLon - lam);
    double x = math.cos(phi) * math.tan(kaabaLat) - math.sin(phi) * math.cos(kaabaLon - lam);
    double bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360.0) % 360.0;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('🧭 Live Qibla Compass', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 6),
            Text('📍 $locationName se Makkah: ${distanceKm.toStringAsFixed(0)} km', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<CompassEvent>(
                stream: FlutterCompass.events,
                builder: (context, snapshot) {
                  double? heading = snapshot.data?.heading;
                  bool hasSensor = heading != null;
                  double currentHeading = heading ?? 0.0;
                  if (currentHeading < 0) currentHeading += 360.0;

                  double diff = (qiblaAngle - currentHeading + 360.0) % 360.0;
                  bool isAligned = diff < 8.0 || diff > 352.0;

                  if (isAligned && hasSensor) {
                    HapticFeedback.selectionClick();
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Alignment Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isAligned ? const Color(0xFF10B981) : const Color(0xFF16323F),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: const Color(0xFFFFD700)),
                        ),
                        child: Text(
                          isAligned
                              ? '🕋 PERFECT! Aapka Rukh Kaaba ki taraf hai!'
                              : (hasSensor ? 'Phone ko seedha rakhein aur ghumayein' : 'Sensor Mode: Qibla Angle ${qiblaAngle.toStringAsFixed(1)}° W/NW'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Rotating 3D Cartoon Compass Dial
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Glow Ring
                          Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF143340),
                                  isAligned ? const Color(0xFF064E3B) : const Color(0xFF09171E),
                                ],
                              ),
                              border: Border.all(
                                color: isAligned ? const Color(0xFF10B981) : const Color(0xFFFFD700),
                                width: isAligned ? 5 : 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isAligned ? const Color(0xFF10B981) : const Color(0xFFFFD700)).withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),

                          // Rotating N-E-S-W Dial
                          Transform.rotate(
                            angle: -currentHeading * (math.pi / 180.0),
                            child: SizedBox(
                              width: 250,
                              height: 250,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Positioned(top: 10, child: Text('N', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 20))),
                                  const Positioned(bottom: 10, child: Text('S', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18))),
                                  const Positioned(right: 12, child: Text('E', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18))),
                                  const Positioned(left: 12, child: Text('W', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18))),
                                ],
                              ),
                            ),
                          ),

                          // Rotating Golden Kaaba Pointer Needle
                          Transform.rotate(
                            angle: (qiblaAngle - currentHeading) * (math.pi / 180.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Cartoon Kaaba Icon at Tip
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFFD700), width: 2),
                                  ),
                                  child: const Text('🕋', style: TextStyle(fontSize: 22)),
                                ),
                                Container(
                                  width: 6,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFD700), Color(0xFF10B981)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 60),
                              ],
                            ),
                          ),

                          // Center Pivot Cap
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Degree Readout Cards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _infoBox('Qibla Angle', '${qiblaAngle.toStringAsFixed(1)}°'),
                          _infoBox('Phone Heading', '${currentHeading.toStringAsFixed(0)}°'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10242D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ---------------- 3. ANALYTICS TRACKER (WITH JAMAAT & QAZA STATS) ----------------
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
    int c = 0;
    for (var p in prayers) {
      if (isPrayerOffered(getPrayerStatus(_prefs, date, p))) c++;
    }
    return c;
  }

  Future<void> _cycleStatusOnDate(DateTime date, String prayer) async {
    if (_prefs == null) return;
    int current = getPrayerStatus(_prefs, date, prayer);
    int next = (current + 1) % 5; // Cycles 0 -> 1(Jamaat) -> 2(OnTime) -> 3(Qaza) -> 4(Missed) -> 0
    String key = getDateKey(date);
    await _prefs!.setInt('status_${key}_$prayer', next);
    await _prefs!.setBool('track_${key}_$prayer', isPrayerOffered(next));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    int monthlyOffered = 0;
    int monthlyJamaat = 0;
    int monthlyQazaOrMissed = 0;

    for (int d = 1; d <= daysInMonth; d++) {
      DateTime dt = DateTime(now.year, now.month, d);
      for (var p in prayers) {
        int st = getPrayerStatus(_prefs, dt, p);
        if (isPrayerOffered(st)) monthlyOffered++;
        if (st == 1) monthlyJamaat++;
        if (st == 3 || st == 4) monthlyQazaOrMissed++;
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Advanced Namaz Report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 12),

            // 3 Breakdown Cards (Total Ada, Jamaat, Qaza/Missed)
            Row(
              children: [
                Expanded(child: _miniStatCard('Total Ada', '$monthlyOffered', const Color(0xFF10B981))),
                const SizedBox(width: 8),
                Expanded(child: _miniStatCard('🟢 In Jamaat', '$monthlyJamaat', const Color(0xFFFFD700))),
                const SizedBox(width: 8),
                Expanded(child: _miniStatCard('🟠 Qaza/Miss', '$monthlyQazaOrMissed', const Color(0xFFF59E0B))),
              ],
            ),
            const SizedBox(height: 16),

            // Period Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  _buildTabButton('Weekly (7D)', 0),
                  _buildTabButton('Monthly', 1),
                  _buildTabButton('Yearly (12M)', 2),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (selectedPeriod == 0) _buildWeeklyChart(now),
            if (selectedPeriod == 1) _buildMonthlyCalendar(now, daysInMonth),
            if (selectedPeriod == 2) _buildYearlyReport(now),

            const SizedBox(height: 20),

            // Selected Date Multi-Status Editor
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
                  Text('📅 Edit Record: ${getDateKey(selectedDate)} (Tap to cycle status)',
                      style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: prayers.map((p) {
                      int st = getPrayerStatus(_prefs, selectedDate, p);
                      Color col = const Color(0xFF16323F);
                      String label = 'None';
                      if (st == 1) { col = const Color(0xFF10B981); label = 'Jamaat'; }
                      else if (st == 2) { col = const Color(0xFF3B82F6); label = 'OnTime'; }
                      else if (st == 3) { col = const Color(0xFFF59E0B); label = 'Qaza'; }
                      else if (st == 4) { col = const Color(0xFFEF4444); label = 'Missed'; }

                      return GestureDetector(
                        onTap: () => _cycleStatusOnDate(selectedDate, p),
                        child: Container(
                          width: 58,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: col,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            children: [
                              Text(p, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
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

  Widget _miniStatCard(String label, String val, Color col) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10242D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: col)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
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
          decoration: BoxDecoration(color: active ? const Color(0xFF10B981) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(title, style: TextStyle(color: active ? Colors.white : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12))),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(DateTime now) {
    final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
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
                      color: count == 5 ? const Color(0xFFFFD700) : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(weekDays[day.weekday - 1], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMonthlyCalendar(DateTime now, int daysInMonth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          DateTime d = DateTime(now.year, now.month, index + 1);
          int c = _getCountForDate(d);
          bool isSelected = getDateKey(d) == getDateKey(selectedDate);
          Color bgColor = c == 5 ? const Color(0xFF10B981) : (c >= 1 ? const Color(0xFF047857) : const Color(0xFF16323F));

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
    );
  }

  Widget _buildYearlyReport(DateTime now) {
    final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5),
        itemCount: 12,
        itemBuilder: (context, mIdx) {
          int m = mIdx + 1;
          int days = DateUtils.getDaysInMonth(now.year, m);
          int total = 0;
          for (int d = 1; d <= days; d++) {
            total += _getCountForDate(DateTime(now.year, m, d));
          }
          return Container(
            decoration: BoxDecoration(color: const Color(0xFF16323F), borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(monthNames[mIdx], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                Text('$total / ${days * 5}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------- SETTINGS, QURAN & TASBEEH SCREENS ----------------
class PrayerSettingsPage extends StatefulWidget {
  final String locationName;
  final VoidCallback onDetectGPS;

  const PrayerSettingsPage({super.key, required this.locationName, required this.onDetectGPS});

  @override
  State<PrayerSettingsPage> createState() => _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends State<PrayerSettingsPage> {
  late String locName;
  int calcMethod = 1;
  int asrSchool = 0;
  String manualCorrection = '0,0,0,0,0';

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
      calcMethod = prefs.getInt('calc_method') ?? 1;
      asrSchool = prefs.getInt('asr_school') ?? 0;
      manualCorrection = prefs.getString('manual_corr') ?? '0,0,0,0,0';
    });
  }

  Future<void> _savePref(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is int) await prefs.setInt(key, val);
    if (val is String) await prefs.setString(key, val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Settings'), backgroundColor: const Color(0xFF047857)),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          ListTile(
            tileColor: const Color(0xFF10242D),
            title: const Text('Location (Tap to Auto-Detect GPS)'),
            subtitle: Text(locName, style: const TextStyle(color: Color(0xFFFFD700))),
            trailing: const Icon(Icons.my_location, color: Color(0xFFFFD700)),
            onTap: () {
              widget.onDetectGPS();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: const Color(0xFF10242D),
            title: const Text('Asr Calculation (Tap to switch)'),
            subtitle: Text(asrSchool == 0 ? 'SHAFI' : 'HANAFI', style: const TextStyle(color: Color(0xFF10B981))),
            onTap: () {
              setState(() => asrSchool = asrSchool == 0 ? 1 : 0);
              _savePref('asr_school', asrSchool);
            },
          ),
        ],
      ),
    );
  }
}

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  final List<Map<String, String>> surahs = const [
    {
      'name': '1. Surah Al-Fatiha',
      'ayahs': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۝',
      'translation': 'Sab tareef Allah Ta\'ala ke liye hai jo tamam jahanon ka palne wala hai...'
    },
    {
      'name': '2. Ayat-ul-Kursi',
      'ayahs': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ...',
      'translation': 'Allah wo hai jiske siwa koi ma\'bood nahi, wo hamesha zinda rehne wala hai...'
    },
    {
      'name': '3. Surah Al-Ikhlas',
      'ayahs': 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ ۝',
      'translation': 'Keh dijiye ki wo Allah ek hai. Allah be-niyaz hai...'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: surahs.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(surahs[index]['name']!, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Text(surahs[index]['ayahs']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 24, color: Colors.white, height: 1.8)),
                const SizedBox(height: 10),
                Text(surahs[index]['translation']!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📿 Digital Tasbeeh', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => setState(() => count++),
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                  border: Border.all(color: const Color(0xFFFFD700), width: 4),
                ),
                child: Center(child: Text('$count', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold))),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: () => setState(() => count = 0), child: const Text('Reset')),
          ],
        ),
      ),
    );
  }
}
