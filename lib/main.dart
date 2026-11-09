import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

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
      title: 'Noor Super App',
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
      const DashboardScreen(),        // 1. Cartoon Mosque + Countdown + Mood Cure + Sunnah
      const PrayerAnalyticsScreen(),  // 2. Weekly/Monthly/Yearly + Qaza Bank
      const LiveQuranScreen(),        // 3. Full 114 Surahs + MP3 Audio Player
      const QiblaCompassScreen(),     // 4. 3D Qibla Finder
      const IslamicToolsHubScreen(),  // 5. Tasbeeh + Zakat Calculator + Duas
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
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Tracker'),
            BottomNavigationBarItem(icon: Icon(Icons.headphones), label: 'Audio Quran'),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Qibla'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Hub & Zakat'),
          ],
        ),
      ),
    );
  }
}

String getDateKey(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

int getPrayerStatus(SharedPreferences? prefs, DateTime date, String prayer) {
  if (prefs == null) return 0;
  String k = 'status_${getDateKey(date)}_$prayer';
  if (prefs.containsKey(k)) return prefs.getInt(k) ?? 0;
  return (prefs.getBool('track_${getDateKey(date)}_$prayer') ?? false) ? 1 : 0;
}

bool isPrayerOffered(int status) => status == 1 || status == 2 || status == 3;

// Pure Math Distance Formula (Km)
double calcDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371.0;
  double dLat = (lat2 - lat1) * math.pi / 180.0;
  double dLon = (lon2 - lon1) * math.pi / 180.0;
  double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180.0) *
          math.cos(lat2 * math.pi / 180.0) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

// ---------------- CARTOON MOSQUE ART PAINTER ----------------
class CartoonMosquePainter extends CustomPainter {
  final bool isDayTime;
  CartoonMosquePainter({required this.isDayTime});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    if (!isDayTime) {
      paint.color = Colors.white70;
      for (var s in [
        Offset(size.width * 0.15, size.height * 0.18),
        Offset(size.width * 0.35, size.height * 0.12),
        Offset(size.width * 0.55, size.height * 0.22),
      ]) {
        canvas.drawCircle(s, 2.2, paint);
      }
      paint.color = const Color(0xFFFFE066);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.24), 20, paint);
      paint.color = const Color(0xFF1A1245);
      canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.21), 18, paint);
    } else {
      paint.color = const Color(0xFFFFD700).withOpacity(0.25);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.26), 34, paint);
      paint.color = const Color(0xFFFFEA79);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.26), 20, paint);
    }

    paint.color = isDayTime ? const Color(0xFF06322D).withOpacity(0.85) : const Color(0xFF091224).withOpacity(0.92);
    final hill = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.92, size.width * 0.72, size.height * 0.74)
      ..quadraticBezierTo(size.width * 0.90, size.height * 0.66, size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill, paint);

    final mCol = isDayTime ? const Color(0xFF04221F) : const Color(0xFF050A14);
    double mx = size.width * 0.75, my = size.height * 0.78;
    paint.color = mCol;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mx, my + 12), width: 74, height: 32), const Radius.circular(6)), paint);
    paint.color = const Color(0xFFFFD700).withOpacity(0.85);
    canvas.drawArc(Rect.fromCenter(center: Offset(mx, my - 4), width: 44, height: 40), 3.14159, 3.14159, true, paint);
    paint.color = mCol;
    canvas.drawRect(Rect.fromLTWH(mx - 44, my - 48, 8, 74), paint);
    canvas.drawRect(Rect.fromLTWH(mx + 36, my - 48, 8, 74), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- 1. HOME: PRAYER + MOOD CURE + SUNNAH HABITS ----------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String locationName = 'Rupahi';
  double lat = 26.4167, lon = 92.7333;
  String hijriDate = '1448 AH', sunriseTime = '05:45', sunsetTime = '17:50';
  bool isLoading = true;
  int asrSchool = 0;

  Timer? _countdownTimer;
  String nextPrayerName = 'Fajr', countdownText = '00 : 00 : 00';

  final List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  final Map<String, String> hindiNames = {'Fajr': 'फज्र', 'Dhuhr': 'ज़ुहर', 'Asr': 'अस्र', 'Maghrib': 'मग़रिब', 'Isha': 'ईशा'};
  Map<String, String> prayerTimes = {'Fajr': '04:45', 'Dhuhr': '12:05', 'Asr': '15:30', 'Maghrib': '17:50', 'Isha': '19:10'};
  Map<String, int> todayStatus = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

  final List<Map<String, String>> moods = [
    {
      'emoji': '😔',
      'label': 'Pareshan / Sad',
      'arabic': 'لَا تُحْزَنْ إِنَّ اللَّهَ مَعَنَا',
      'ayah': '"Gham na karo, beshak Allah humare sath hai." (Quran 9:40)',
      'dua': 'Dua: Yaa Hayyu Yaa Qayyum, birahmatika astagheeth (Aye Zinda aur Qayam rakhne wale, teri rehmat se madad mangta hoon).'
    },
    {
      'emoji': '💸',
      'label': 'Rizq / Tension',
      'arabic': 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ',
      'ayah': '"Jo Allah se darta hai, Allah uske liye rasta nikal deta hai aur wahan se Rizq deta hai jahan se guman bhi na ho." (Quran 65:2-3)',
      'dua': 'Dua: Allahumma inni as\'aluka \'ilman nafi\'an, wa rizqan tayyiban, wa \'amalan mutaqabbalan.'
    },
    {
      'emoji': '😠',
      'label': 'Gussa / Angry',
      'arabic': 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
      'ayah': 'Nabi ﷺ ne farmaya: "Jab kisi ko gussa aaye toh wo kahe: A\'udhu billahi minash-shaytanir-rajeem."',
      'dua': 'Sunnah Tip: Agar khade ho toh baith jao, aur baitho ho toh let jao, ya thanda pani se wudu kar lo!'
    },
    {
      'emoji': '🤒',
      'label': 'Bimar / Sick',
      'arabic': 'وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ',
      'ayah': '"Aur jab main bimar hota hoon toh Wahi (Allah) mujhe shifa deta hai." (Quran 26:80)',
      'dua': 'Shifa Dua: Allahumma Rabban-naas, adh-hibil-ba\'s, ishfi Antash-Shafi.'
    },
    {
      'emoji': '🥰',
      'label': 'Shukr / Happy',
      'arabic': 'لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ',
      'ayah': '"Agar tum mera Shukr ada karoge, toh main tumhe aur zyada dunga!" (Quran 14:7)',
      'dua': 'Zikr: Alhamdulillah \'ala kulli haal (Har haal mein Allah ka shukr hai).'
    },
  ];

  Map<String, bool> sunnahHabits = {
    '🦷 Miswak / Brush before Wudu': false,
    '📖 Read Ayat-ul-Kursi after Salah': false,
    '😊 Smile & Salam to Family/Friends': false,
    '🌙 Sleep in state of Wudu': false,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  DateTime? _parseTime(String t, DateTime ref) {
    if (!t.contains(':')) return null;
    try {
      final p = t.split(' ')[0].split(':');
      return DateTime(ref.year, ref.month, ref.day, int.parse(p[0]), int.parse(p[1]));
    } catch (_) {
      return null;
    }
  }

  void _updateCountdown() {
    final now = DateTime.now();
    DateTime? nextT;
    String found = 'Fajr';
    for (var p in prayerNames) {
      DateTime? pt = _parseTime(prayerTimes[p] ?? '', now);
      if (pt != null && pt.isAfter(now)) {
        nextT = pt;
        found = p;
        break;
      }
    }
    if (nextT == null) {
      DateTime? ft = _parseTime(prayerTimes['Fajr'] ?? '', now);
      if (ft != null) nextT = ft.add(const Duration(days: 1));
    }
    if (nextT != null && mounted) {
      final d = nextT.difference(now);
      setState(() {
        nextPrayerName = found;
        countdownText =
            '${d.inHours.toString().padLeft(2, '0')} : ${(d.inMinutes % 60).toString().padLeft(2, '0')} : ${(d.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final tKey = getDateKey(today);
    setState(() {
      locationName = prefs.getString('loc_name') ?? 'Rupahi';
      lat = prefs.getDouble('lat') ?? 26.4167;
      lon = prefs.getDouble('lon') ?? 92.7333;
      asrSchool = prefs.getInt('asr_school') ?? 0;
      for (var p in prayerNames) {
        todayStatus[p] = getPrayerStatus(prefs, today, p);
      }
      for (var h in sunnahHabits.keys.toList()) {
        sunnahHabits[h] = prefs.getBool('sunnah_${tKey}_$h') ?? false;
      }
    });
    await _fetchTimings();
  }

  // Zero-Crash Location Picker + Auto IP Detector
  void _openLocationPicker() {
    TextEditingController ctrl = TextEditingController(text: locationName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10242D),
        title: const Text('📍 Select Your Location', style: TextStyle(color: Color(0xFFFFD700))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => isLoading = true);
                try {
                  final res = await http.get(Uri.parse('http://ip-api.com/json'));
                  if (res.statusCode == 200) {
                    final d = json.decode(res.body);
                    String city = d['city'] ?? 'Rupahi';
                    lat = (d['lat'] as num).toDouble();
                    lon = (d['lon'] as num).toDouble();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('loc_name', city);
                    await prefs.setDouble('lat', lat);
                    await prefs.setDouble('lon', lon);
                    setState(() => locationName = city);
                    await _fetchTimings();
                  }
                } catch (_) {
                  setState(() => isLoading = false);
                }
              },
              icon: const Icon(Icons.my_location, color: Colors.white),
              label: const Text('Auto-Detect My Current Location', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 14),
            const Text('Ya apne Gaon / Sheher ka naam likhein:', style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Rupahi, Nagaon, Guwahati, Delhi',
                filled: true,
                fillColor: Color(0xFF16323F),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              String place = ctrl.text.trim();
              Navigator.pop(ctx);
              if (place.isNotEmpty) {
                setState(() => isLoading = true);
                try {
                  final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$place&format=json&limit=1');
                  final res = await http.get(url, headers: {'User-Agent': 'NoorSuperApp/7.0'});
                  if (res.statusCode == 200) {
                    final list = json.decode(res.body) as List;
                    if (list.isNotEmpty) {
                      lat = double.parse(list[0]['lat']);
                      lon = double.parse(list[0]['lon']);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('loc_name', place);
                      await prefs.setDouble('lat', lat);
                      await prefs.setDouble('lon', lon);
                      setState(() => locationName = place);
                      await _fetchTimings();
                      return;
                    }
                  }
                } catch (_) {}
                setState(() => isLoading = false);
              }
            },
            child: const Text('Search & Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchTimings() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
          'https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=1&school=$asrSchool');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        final t = data['timings'];
        final h = data['date']['hijri'];
        setState(() {
          for (var p in prayerNames) {
            prayerTimes[p] = t[p].toString().split(' ')[0];
          }
          sunriseTime = t['Sunrise'].toString().split(' ')[0];
          sunsetTime = t['Sunset'].toString().split(' ')[0];
          hijriDate = '${h['day']} ${h['month']['en']} ${h['year']}';
          isLoading = false;
        });
        _updateCountdown();
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _setPrayerStatus(String prayer, int status) async {
    final prefs = await SharedPreferences.getInstance();
    final tKey = getDateKey(DateTime.now());
    await prefs.setInt('status_${tKey}_$prayer', status);
    await prefs.setBool('track_${tKey}_$prayer', isPrayerOffered(status));
    setState(() => todayStatus[prayer] = status);
    HapticFeedback.lightImpact();
  }

  void _showMoodCureModal(Map<String, String> mood) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D212A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${mood['emoji']} ${mood['label']} - Allah ka Paigham',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const Divider(color: Colors.white12, height: 24),
            Text(mood['arabic']!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(mood['ayah']!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)),
              child: Text(mood['dua']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(String prayer) {
    int curr = todayStatus[prayer] ?? 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D212A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🕌 $prayer (${hindiNames[prayer]}) Status',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 14),
            _statusBtn(ctx, prayer, 1, '🟢 Jamaat ke sath (27x Sawab)', const Color(0xFF10B981), curr),
            _statusBtn(ctx, prayer, 2, '🔵 Waqt par Akele (On Time)', const Color(0xFF3B82F6), curr),
            _statusBtn(ctx, prayer, 3, '🟠 Qaza / Late Ada ki', const Color(0xFFF59E0B), curr),
            _statusBtn(ctx, prayer, 4, '🔴 Missed (Chhoot gayi)', const Color(0xFFEF4444), curr),
          ],
        ),
      ),
    );
  }

  Widget _statusBtn(BuildContext ctx, String p, int val, String label, Color col, int curr) {
    return GestureDetector(
      onTap: () {
        _setPrayerStatus(p, val);
        Navigator.pop(ctx);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: curr == val ? col.withOpacity(0.3) : const Color(0xFF142E3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _statusBadge(int st) {
    final labels = ['Log ➕', '🟢 Jamaat', '🔵 On Time', '🟠 Qaza', '🔴 Missed'];
    final cols = [Colors.white24, const Color(0xFF10B981), const Color(0xFF3B82F6), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: cols[st].withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: cols[st])),
      child: Text(labels[st], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDay = (nextPrayerName == 'Dhuhr' || nextPrayerName == 'Asr' || nextPrayerName == 'Maghrib');
    int sunnahDone = sunnahHabits.values.where((v) => v).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assalamu Alaikum 👋', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('🌙 $hijriDate', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openLocationPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(locationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        setState(() => asrSchool = asrSchool == 0 ? 1 : 0);
                        await prefs.setInt('asr_school', asrSchool);
                        _fetchTimings();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(color: const Color(0xFF16323F), borderRadius: BorderRadius.circular(14)),
                        child: Text(asrSchool == 0 ? 'SHAFI' : 'HANAFI',
                            style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Cartoon Mosque & Live Countdown Card
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDay
                        ? [const Color(0xFF0F766E), const Color(0xFF064E3B)]
                        : [const Color(0xFF1E1B4B), const Color(0xFF0F172A)],
                  ),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.45)),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: CartoonMosquePainter(isDayTime: isDay))),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14)),
                            child: Text('NEXT: ${nextPrayerName.toUpperCase()} (${prayerTimes[nextPrayerName]})',
                                style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          const SizedBox(height: 10),
                          const Text('Agli Namaz mein baqi waqt:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('- $countdownText',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('🌅 Sunrise: $sunriseTime', style: const TextStyle(fontSize: 12)),
                                Text('🌇 Sunset: $sunsetTime', style: const TextStyle(fontSize: 12)),
                                if (isLoading) const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
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

            // ISLAMIC MOOD CURE
            const Text('💖 Islamic Soul Care (Aaj kaisa mehsoos kar rahe ho?)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: moods.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showMoodCureModal(moods[index]),
                    child: Container(
                      width: 105,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF16323F), Color(0xFF10242D)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(moods[index]['emoji']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(moods[index]['label']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            const Text('🕌 Aaj ki Namazein (Tap to log Jamaat/Qaza)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...prayerNames.map((String key) {
              int st = todayStatus[key] ?? 0;
              bool isNext = (key == nextPrayerName);
              return GestureDetector(
                onTap: () => _showStatusPicker(key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isNext ? const Color(0xFF153832) : const Color(0xFF10242D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isNext ? const Color(0xFFFFD700) : Colors.white10, width: isNext ? 1.5 : 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$key (${hindiNames[key]})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Azan: ${prayerTimes[key]}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13)),
                        ],
                      ),
                      _statusBadge(st),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 14),

            // DAILY SUNNAH HABITS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🔥 Daily Sunnah Habits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                      Text('$sunnahDone/4 Done', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...sunnahHabits.keys.map((String h) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: const Color(0xFF10B981),
                      title: Text(h, style: const TextStyle(fontSize: 13)),
                      value: sunnahHabits[h],
                      onChanged: (val) async {
                        final prefs = await SharedPreferences.getInstance();
                        final tKey = getDateKey(DateTime.now());
                        await prefs.setBool('sunnah_${tKey}_$h', val ?? false);
                        setState(() => sunnahHabits[h] = val ?? false);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 2. ANALYTICS + QAZA-E-UMRI BANK ----------------
class PrayerAnalyticsScreen extends StatefulWidget {
  const PrayerAnalyticsScreen({super.key});

  @override
  State<PrayerAnalyticsScreen> createState() => _PrayerAnalyticsScreenState();
}

class _PrayerAnalyticsScreenState extends State<PrayerAnalyticsScreen> {
  SharedPreferences? _prefs;
  final List<String> prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, int> qazaBank = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var p in prayers) {
        qazaBank[p] = _prefs!.getInt('qazabank_$p') ?? 0;
      }
    });
  }

  Future<void> _updateQazaBank(String prayer, int delta) async {
    if (_prefs == null) return;
    int next = math.max(0, (qazaBank[prayer] ?? 0) + delta);
    await _prefs!.setInt('qazabank_$prayer', next);
    setState(() => qazaBank[prayer] = next);
  }

  Future<void> _addMonthsToQazaBank(int months) async {
    if (_prefs == null) return;
    int days = months * 30;
    for (var p in prayers) {
      int next = (qazaBank[p] ?? 0) + days;
      await _prefs!.setInt('qazabank_$p', next);
      qazaBank[p] = next;
    }
    setState(() {});
  }

  int _getCountForDate(DateTime date) {
    int c = 0;
    for (var p in prayers) {
      if (isPrayerOffered(getPrayerStatus(_prefs, date, p))) c++;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    int mAda = 0, mJamaat = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      DateTime dt = DateTime(now.year, now.month, d);
      for (var p in prayers) {
        int st = getPrayerStatus(_prefs, dt, p);
        if (isPrayerOffered(st)) mAda++;
        if (st == 1) mJamaat++;
      }
    }
    int totalQazaRemaining = qazaBank.values.fold(0, (a, b) => a + b);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Namaz Analytics & Qaza Bank',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _statBox('This Month Ada', '$mAda / ${daysInMonth * 5}', const Color(0xFF10B981))),
                const SizedBox(width: 10),
                Expanded(child: _statBox('🟢 In Jamaat', '$mJamaat Prayers', const Color(0xFFFFD700))),
              ],
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🗓️ Monthly Consistency (${now.month}/${now.year})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
                    itemCount: daysInMonth,
                    itemBuilder: (ctx, idx) {
                      int c = _getCountForDate(DateTime(now.year, now.month, idx + 1));
                      Color col = c == 5 ? const Color(0xFF10B981) : (c >= 1 ? const Color(0xFF047857) : const Color(0xFF16323F));
                      return Container(
                        decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // QAZA-E-UMRI BANK
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A2639), Color(0xFF10242D)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🏦 Qaza-e-Umri Bank',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                      Text('Pending: $totalQazaRemaining',
                          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Purani chhooti hui namazon ka hisab rakhein aur roz ada karke kam karein:',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16323F)),
                        onPressed: () => _addMonthsToQazaBank(1),
                        child: const Text('+1 Month Qaza', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16323F)),
                        onPressed: () => _addMonthsToQazaBank(12),
                        child: const Text('+1 Year Qaza', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...prayers.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$p Qaza:', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Text('${qazaBank[p]}',
                                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () => _updateQazaBank(p, -1),
                                child: const Text('-1 Paid ✅', style: TextStyle(fontSize: 11, color: Colors.white)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.white54, size: 20),
                                onPressed: () => _updateQazaBank(p, 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String val, Color col) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(16), border: Border.all(color: col.withOpacity(0.4))),
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: col)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ---------------- 3. LIVE 114 SURAH QURAN + MP3 AUDIO PLAYER ----------------
class LiveQuranScreen extends StatefulWidget {
  const LiveQuranScreen({super.key});

  @override
  State<LiveQuranScreen> createState() => _LiveQuranScreenState();
}

class _LiveQuranScreenState extends State<LiveQuranScreen> {
  List<dynamic> surahList = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAll114Surahs();
  }

  Future<void> _fetchAll114Surahs() async {
    try {
      final res = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
      if (res.statusCode == 200) {
        setState(() {
          surahList = json.decode(res.body)['data'];
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = surahList.where((s) {
      final name = s['englishName'].toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎧 Complete 114 Surah Audio Quran',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search Surah (e.g. Yaseen, Mulk, Kahf)...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                filled: true,
                fillColor: const Color(0xFF10242D),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) {
                        final s = filtered[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF16323F),
                              child: Text('${s['number']}', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                            ),
                            title: Text(s['englishName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${s['englishNameTranslation']} • ${s['numberOfAyahs']} Ayahs',
                                style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            trailing: Text(s['name'], style: const TextStyle(fontSize: 20, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SurahDetailAudioPage(
                                    surahNumber: s['number'],
                                    surahName: s['englishName'],
                                  ),
                                ),
                              );
                            },
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

class SurahDetailAudioPage extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailAudioPage({super.key, required this.surahNumber, required this.surahName});

  @override
  State<SurahDetailAudioPage> createState() => _SurahDetailAudioPageState();
}

class _SurahDetailAudioPageState extends State<SurahDetailAudioPage> {
  List<dynamic> arabicAyahs = [];
  List<dynamic> transAyahs = [];
  bool isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? playingIndex;

  @override
  void initState() {
    super.initState();
    _loadSurahContent();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playingIndex = null);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSurahContent() async {
    try {
      final url = Uri.parse(
          'https://api.alquran.cloud/v1/surah/${widget.surahNumber}/editions/ar.alafasy,en.asad');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        setState(() {
          arabicAyahs = data[0]['ayahs'];
          transAyahs = data[1]['ayahs'];
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _playAyahAudio(int index, String audioUrl) async {
    if (playingIndex == index) {
      await _audioPlayer.stop();
      setState(() => playingIndex = null);
    } else {
      setState(() => playingIndex = index);
      await _audioPlayer.play(UrlSource(audioUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Surah ${widget.surahName}'), backgroundColor: const Color(0xFF047857)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: arabicAyahs.length,
              itemBuilder: (ctx, i) {
                final ar = arabicAyahs[i];
                final tr = transAyahs[i];
                bool isPlaying = (playingIndex == i);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10242D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isPlaying ? const Color(0xFFFFD700) : Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF16323F),
                            child: Text('${ar['numberInSurah']}', style: const TextStyle(fontSize: 11, color: Color(0xFFFFD700))),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPlaying ? const Color(0xFFFFD700) : const Color(0xFF10B981),
                            ),
                            onPressed: () => _playAyahAudio(i, ar['audio']),
                            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow, color: Colors.black, size: 18),
                            label: Text(isPlaying ? 'Stop' : 'Listen Tilawat',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(ar['text'],
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 25, color: Colors.white, height: 1.8, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(tr['text'], style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- 4. 3D QIBLA DIRECTION FINDER ----------------
class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  double qiblaAngle = 277.0, distanceKm = 5120.0;
  double manualRotation = 0.0;
  String locationName = 'Rupahi';

  @override
  void initState() {
    super.initState();
    _initQibla();
  }

  Future<void> _initQibla() async {
    final prefs = await SharedPreferences.getInstance();
    double lat = prefs.getDouble('lat') ?? 26.4167;
    double lon = prefs.getDouble('lon') ?? 92.7333;
    const double kLat = 21.422487 * math.pi / 180.0;
    const double kLon = 39.826206 * math.pi / 180.0;
    double phi = lat * math.pi / 180.0, lam = lon * math.pi / 180.0;
    double y = math.sin(kLon - lam);
    double x = math.cos(phi) * math.tan(kLat) - math.sin(phi) * math.cos(kLon - lam);
    setState(() {
      locationName = prefs.getString('loc_name') ?? 'Rupahi';
      qiblaAngle = ((math.atan2(y, x) * 180.0 / math.pi) + 360.0) % 360.0;
      distanceKm = calcDistanceKm(lat, lon, 21.422487, 39.826206);
    });
  }

  @override
  Widget build(BuildContext context) {
    double diff = (qiblaAngle - manualRotation + 360.0) % 360.0;
    bool aligned = diff < 10.0 || diff > 350.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧭 3D Qibla Direction Finder',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 6),
            Text('📍 $locationName to Holy Kaaba: ${distanceKm.toStringAsFixed(0)} km',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Exact Qibla Bearing: ${qiblaAngle.toStringAsFixed(1)}° (West-Northwest)',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: aligned ? const Color(0xFF064E3B) : const Color(0xFF10242D),
                    border: Border.all(color: aligned ? const Color(0xFF10B981) : const Color(0xFFFFD700), width: 4),
                  ),
                ),
                Transform.rotate(
                  angle: -manualRotation * (math.pi / 180.0),
                  child: const SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(top: 8, child: Text('N', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 18))),
                        Positioned(bottom: 8, child: Text('S', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        Positioned(right: 8, child: Text('E', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        Positioned(left: 8, child: Text('W', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: (qiblaAngle - manualRotation) * (math.pi / 180.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🕋', style: TextStyle(fontSize: 34)),
                      Container(width: 6, height: 80, color: const Color(0xFFFFD700)),
                      const SizedBox(height: 55),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text('Slider ghuma kar North (N) ko apne samne milayein:', style: TextStyle(fontSize: 12, color: Colors.white60)),
            Slider(
              activeColor: const Color(0xFFFFD700),
              min: 0,
              max: 360,
              value: manualRotation,
              onChanged: (v) => setState(() => manualRotation = v),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 5. ISLAMIC HUB: TASBEEH + ZAKAT CALCULATOR ----------------
class IslamicToolsHubScreen extends StatefulWidget {
  const IslamicToolsHubScreen({super.key});

  @override
  State<IslamicToolsHubScreen> createState() => _IslamicToolsHubScreenState();
}

class _IslamicToolsHubScreenState extends State<IslamicToolsHubScreen> {
  int tasbeehCount = 0;
  final TextEditingController goldCtrl = TextEditingController();
  final TextEditingController silverCtrl = TextEditingController();
  final TextEditingController cashCtrl = TextEditingController();
  double calculatedZakat = 0.0;

  void _calculateZakat() {
    double g = double.tryParse(goldCtrl.text) ?? 0;
    double s = double.tryParse(silverCtrl.text) ?? 0;
    double c = double.tryParse(cashCtrl.text) ?? 0;
    setState(() {
      calculatedZakat = (g + s + c) * 0.025;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✨ Islamic Hub (Tasbeeh & Zakat)',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text('📿 Quick Digital Tasbeeh', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => tasbeehCount++);
                    },
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: const Color(0xFF10B981),
                      child: Text('$tasbeehCount', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  TextButton(onPressed: () => setState(() => tasbeehCount = 0), child: const Text('Reset Counter')),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧮 Smart Zakat Calculator (2.5%)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  const SizedBox(height: 12),
                  _zakatInput(goldCtrl, 'Gold Value (₹)'),
                  const SizedBox(height: 10),
                  _zakatInput(silverCtrl, 'Silver Value (₹)'),
                  const SizedBox(height: 10),
                  _zakatInput(cashCtrl, 'Cash / Bank Savings (₹)'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      onPressed: _calculateZakat,
                      child: const Text('Calculate Zakat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Total Payable Zakat: ₹ ${calculatedZakat.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zakatInput(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF16323F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
