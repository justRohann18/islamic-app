import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IslamicApp());
}

String appLang = 'en';
bool use12Hour = true;

String formatClock(String raw) {
  if (!raw.contains(':')) return raw;
  try {
    final p = raw.split(' ')[0].split(':');
    int h = int.parse(p[0]), m = int.parse(p[1]);
    String mm = m.toString().padLeft(2, '0');
    if (!use12Hour) return '${h.toString().padLeft(2, '0')}:$mm';
    String ap = h >= 12 ? 'PM' : 'AM';
    int h12 = h % 12 == 0 ? 12 : h % 12;
    return '${h12.toString().padLeft(2, '0')}:$mm $ap';
  } catch (_) {
    return raw;
  }
}

String getDateKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noor Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF061014),
        primaryColor: const Color(0xFF10B981),
        cardColor: const Color(0xFF10242D),
      ),
      home: const MainNav(),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int idx = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        appLang = prefs.getString('lang') ?? 'en';
        use12Hour = prefs.getBool('use12') ?? true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(onUpdate: () => setState(() {})),
      const TrackerTab(),
      const QuranHadithTab(),
      const QiblaTab(),
      const AiMuftiHubTab(),
    ];
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => setState(() => idx = i),
        backgroundColor: const Color(0xFF09171E),
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'Prayer'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Quran/Hadith'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: '3D Qibla'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_alt), label: 'AI Mufti & Hub'),
        ],
      ),
    );
  }
}

// ---------------- CARTOON MOSQUE PAINTER ----------------
class MosquePainter extends CustomPainter {
  final bool isDay;
  MosquePainter(this.isDay);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFFFFD700).withOpacity(isDay ? 0.35 : 0.9);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.25), isDay ? 26 : 18, p);
    p.color = isDay ? const Color(0xFF06322D) : const Color(0xFF091224);
    final hill = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.65, size.width, size.height * 0.8)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill, p);
    double mx = size.width * 0.75, my = size.height * 0.78;
    p.color = const Color(0xFFFFD700);
    canvas.drawArc(Rect.fromCenter(center: Offset(mx, my), width: 44, height: 40), 3.14, 3.14, true, p);
    p.color = const Color(0xFF04221F);
    canvas.drawRect(Rect.fromLTWH(mx - 38, my - 45, 7, 65), p);
    canvas.drawRect(Rect.fromLTWH(mx + 31, my - 45, 7, 65), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- 1. PRAYER & SETTINGS TAB ----------------
class HomeTab extends StatefulWidget {
  final VoidCallback onUpdate;
  const HomeTab({super.key, required this.onUpdate});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String loc = 'Rupahi', hijri = '1448 AH', sunrise = '05:45', sunset = '17:50';
  double lat = 26.4167, lon = 92.7333;
  int school = 0;
  bool manualMode = false;
  Timer? timer;
  String nextP = 'Fajr', countdown = '00:00:00';

  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, String> times = {'Fajr': '04:45', 'Dhuhr': '12:05', 'Asr': '15:30', 'Maghrib': '17:50', 'Isha': '19:10'};
  Map<String, int> status = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    DateTime? nextT;
    String found = 'Fajr';
    for (var p in prayers) {
      final parts = times[p]!.split(':');
      final dt = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      if (dt.isAfter(now)) {
        nextT = dt;
        found = p;
        break;
      }
    }
    if (nextT == null) {
      final parts = times['Fajr']!.split(':');
      nextT = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1])).add(const Duration(days: 1));
    }
    final d = nextT.difference(now);
    if (mounted) {
      setState(() {
        nextP = found;
        countdown = '${d.inHours.toString().padLeft(2, '0')} : ${(d.inMinutes % 60).toString().padLeft(2, '0')} : ${(d.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final tKey = getDateKey(DateTime.now());
    setState(() {
      loc = prefs.getString('loc') ?? 'Rupahi';
      lat = prefs.getDouble('lat') ?? 26.4167;
      lon = prefs.getDouble('lon') ?? 92.7333;
      school = prefs.getInt('school') ?? 0;
      manualMode = prefs.getBool('manual') ?? false;
      for (var p in prayers) {
        status[p] = prefs.getInt('st_${tKey}_$p') ?? 0;
        if (manualMode) times[p] = prefs.getString('mt_$p') ?? times[p]!;
      }
    });
    if (!manualMode) _fetchAPI();
  }

  Future<void> _fetchAPI() async {
    try {
      final res = await http.get(Uri.parse('https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=1&school=$school'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body)['data'];
        setState(() {
          for (var p in prayers) {
            times[p] = d['timings'][p].toString().split(' ')[0];
          }
          sunrise = d['timings']['Sunrise'].toString().split(' ')[0];
          sunset = d['timings']['Sunset'].toString().split(' ')[0];
          hijri = '${d['date']['hijri']['day']} ${d['date']['hijri']['month']['en']} ${d['date']['hijri']['year']}';
        });
      }
    } catch (_) {}
  }

  void _pickManualTime(String p) async {
    final parts = times[p]!.split(':');
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked != null) {
      String t24 = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mt_$p', t24);
      await prefs.setBool('manual', true);
      setState(() {
        times[p] = t24;
        manualMode = true;
      });
    }
  }

  void _setStatus(String p, int st) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('st_${getDateKey(DateTime.now())}_$p', st);
    setState(() => status[p] = st);
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Log ➕', '🟢 Jamaat', '🔵 On Time', '🟠 Qaza', '🔴 Missed'];
    final cols = [Colors.white24, const Color(0xFF10B981), const Color(0xFF3B82F6), const Color(0xFFF59E0B), const Color(0xFFEF4444)];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assalamu Alaikum 👋', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('🌙 $hijri', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Row(
                children: [
                  PopupMenuButton<String>(
                    color: const Color(0xFF10242D),
                    onSelected: (v) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('lang', v);
                      setState(() => appLang = v);
                      widget.onUpdate();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
                      PopupMenuItem(value: 'hi', child: Text('🇮🇳 हिंदी')),
                      PopupMenuItem(value: 'ur', child: Text('🇵🇰 اردو')),
                      PopupMenuItem(value: 'ro', child: Text('💬 Hinglish')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF16323F), borderRadius: BorderRadius.circular(12)),
                      child: Text('🌐 ${appLang.toUpperCase()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('use12', !use12Hour);
                      setState(() => use12Hour = !use12Hour);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF16323F), borderRadius: BorderRadius.circular(12)),
                      child: Text(use12Hour ? '12H (AM/PM)' : '24H', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 210,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF064E3B)]),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: MosquePainter(nextP == 'Dhuhr' || nextP == 'Asr'))),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('NEXT: $nextP (${formatClock(times[nextP]!)})', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                            GestureDetector(
                              onTap: () async {
                                final res = await http.get(Uri.parse('http://ip-api.com/json'));
                                if (res.statusCode == 200) {
                                  final d = json.decode(res.body);
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('loc', d['city'] ?? 'Rupahi');
                                  await prefs.setDouble('lat', (d['lat'] as num).toDouble());
                                  await prefs.setDouble('lon', (d['lon'] as num).toDouble());
                                  await prefs.setBool('manual', false);
                                  _load();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                                child: Text('📍 $loc (Tap Auto-GPS)', style: const TextStyle(fontSize: 11, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('- $countdown', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('🌅 Sunrise: ${formatClock(sunrise)}', style: const TextStyle(fontSize: 12)),
                            Text('🌇 Sunset: ${formatClock(sunset)}', style: const TextStyle(fontSize: 12)),
                            GestureDetector(
                              onTap: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setInt('school', school == 0 ? 1 : 0);
                                _load();
                              },
                              child: Text(school == 0 ? 'SHAFI' : 'HANAFI', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
            child: const Column(
              children: [
                Text('فَإِنَّ مَعَ الْعُسْرِ يُسْرًا', style: TextStyle(fontSize: 22, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('"For indeed, with hardship comes ease." (Quran 94:5)', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🕌 Today\'s Prayers (Tap time to edit manually)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (manualMode)
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('manual', false);
                    _load();
                  },
                  child: const Text('Reset Auto', style: TextStyle(color: Color(0xFFFFD700), fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          ...prayers.map((p) {
            int st = status[p] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: p == nextP ? const Color(0xFF153832) : const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p == nextP ? const Color(0xFFFFD700) : Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _pickManualTime(p),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Text(formatClock(times[p]!), style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                            const SizedBox(width: 5),
                            const Icon(Icons.edit, size: 13, color: Colors.white54),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<int>(
                    color: const Color(0xFF10242D),
                    onSelected: (v) => _setStatus(p, v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 1, child: Text('🟢 Jamaat (27x Reward)')),
                      PopupMenuItem(value: 2, child: Text('🔵 On Time Alone')),
                      PopupMenuItem(value: 3, child: Text('🟠 Late / Qaza')),
                      PopupMenuItem(value: 4, child: Text('🔴 Missed')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: cols[st].withOpacity(0.2), borderRadius: BorderRadius.circular(14), border: Border.all(color: cols[st])),
                      child: Text(labels[st], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ---------------- 2. UNIQUE IMAN SCORE TRACKER & QAZA BANK ----------------
class TrackerTab extends StatefulWidget {
  const TrackerTab({super.key});
  @override
  State<TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<TrackerTab> {
  SharedPreferences? prefs;
  int view = 0;
  DateTime selDate = DateTime.now();
  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) => setState(() => prefs = p));
  }

  int _st(DateTime d, String p) => prefs?.getInt('st_${getDateKey(d)}_$p') ?? 0;
  bool _offered(int s) => s == 1 || s == 2 || s == 3;
  int _dayCount(DateTime d) => prayers.where((p) => _offered(_st(d, p))).length;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int daysInM = DateUtils.getDaysInMonth(now.year, now.month);
    int mAda = 0, mJamaat = 0;
    for (int i = 1; i <= daysInM; i++) {
      final dt = DateTime(now.year, now.month, i);
      for (var p in prayers) {
        int s = _st(dt, p);
        if (_offered(s)) mAda++;
        if (s == 1) mJamaat++;
      }
    }
    double score = ((mAda / (math.max(1, now.day) * 5)) * 100).clamp(0, 100);
    int qazaTotal = prayers.fold(0, (a, p) => a + (prefs?.getInt('qb_$p') ?? 0));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F2932), Color(0xFF064E3B)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 75,
                  height: 75,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(value: score / 100, strokeWidth: 8, backgroundColor: Colors.black38, valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700))),
                      Center(child: Text('${score.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('👑 IMAN CONSISTENCY SCORE', style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$mAda Offered • $mJamaat in Jamaat', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const Text('Tap any day below to view or edit record', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => view = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: view == i ? const Color(0xFF10B981) : const Color(0xFF10242D), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(['Weekly (7D)', 'Monthly', 'Yearly'][i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (view == 0)
            Container(
              height: 150,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final d = now.subtract(Duration(days: 6 - i));
                  int c = _dayCount(d);
                  return GestureDetector(
                    onTap: () => setState(() => selDate = d),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$c/5', style: const TextStyle(fontSize: 10)),
                        const SizedBox(height: 4),
                        Container(width: 26, height: math.max(10, c * 16.0), decoration: BoxDecoration(color: c == 5 ? const Color(0xFFFFD700) : const Color(0xFF10B981), borderRadius: BorderRadius.circular(6))),
                        const SizedBox(height: 4),
                        Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  );
                }),
              ),
            ),

          if (view == 1)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemCount: daysInM,
              itemBuilder: (_, i) {
                final d = DateTime(now.year, now.month, i + 1);
                int c = _dayCount(d);
                return GestureDetector(
                  onTap: () => setState(() => selDate = d),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c == 5 ? const Color(0xFF10B981) : (c > 0 ? const Color(0xFF047857) : const Color(0xFF10242D)),
                      borderRadius: BorderRadius.circular(8),
                      border: getDateKey(d) == getDateKey(selDate) ? Border.all(color: const Color(0xFFFFD700), width: 2) : null,
                    ),
                    child: Center(child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ),
                );
              },
            ),

          if (view == 2)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.6),
              itemCount: 12,
              itemBuilder: (_, m) {
                int days = DateUtils.getDaysInMonth(now.year, m + 1);
                int tot = 0;
                for (int d = 1; d <= days; d++) {
                  tot += _dayCount(DateTime(now.year, m + 1, d));
                }
                return Container(
                  decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m], style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                      Text('$tot / ${days * 5}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 Edit Date: ${getDateKey(selDate)} (Tap to cycle status)', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: prayers.map((p) {
                    int s = _st(selDate, p);
                    final cols = [const Color(0xFF16323F), const Color(0xFF10B981), const Color(0xFF3B82F6), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
                    final tags = ['None', 'Jamaat', 'OnTime', 'Qaza', 'Missed'];
                    return GestureDetector(
                      onTap: () async {
                        await prefs?.setInt('st_${getDateKey(selDate)}_$p', (s + 1) % 5);
                        setState(() {});
                      },
                      child: Container(
                        width: 56,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: cols[s], borderRadius: BorderRadius.circular(10)),
                        child: Column(children: [Text(p, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Text(tags[s], style: const TextStyle(fontSize: 9))]),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🏦 Qaza-e-Umri Bank', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Pending: $qazaTotal', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    for (var p in prayers) {
                      await prefs?.setInt('qb_$p', (prefs?.getInt('qb_$p') ?? 0) + 30);
                    }
                    setState(() {});
                  },
                  child: const Text('+ Add 1 Month (30 Days) Missed Qaza'),
                ),
                ...prayers.map((p) {
                  int val = prefs?.getInt('qb_$p') ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$p Qaza: $val', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                          await prefs?.setInt('qb_$p', math.max(0, val - 1));
                          setState(() {});
                        },
                        child: const Text('-1 Paid ✅', style: TextStyle(color: Color(0xFF10B981))),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 3. QURAN & HADITH WITH INSTANT SEARCH BAR ----------------
class QuranHadithTab extends StatefulWidget {
  const QuranHadithTab({super.key});
  @override
  State<QuranHadithTab> createState() => _QuranHadithTabState();
}

class _QuranHadithTabState extends State<QuranHadithTab> {
  int sec = 0;
  List surahs = [];
  List hadiths = [];
  bool loadingQuran = true;
  bool loadingHadith = false;
  String book = 'bukhari';
  int chap = 1;
  String quranSearch = '';
  String hadithSearch = '';

  final List<Map<String, String>> instantHadiths = const [
    {'hadithnumber': '1', 'arab': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ', 'text': 'Sahih Bukhari #1: Actions are judged only by intentions, and every person will have only what they intended.'},
    {'hadithnumber': '5027', 'arab': 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ', 'text': 'Sahih Bukhari #5027: The best among you are those who learn the Qur\'an and teach it to others.'},
    {'hadithnumber': '223', 'arab': 'الطُّهُورُ شَطْرُ الإِيمَانِ', 'text': 'Sahih Muslim #223: Cleanliness (Wudu/Purity) is half of faith (Iman), and Alhamdulillah fills the scale.'},
    {'hadithnumber': '601', 'arab': 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ', 'text': 'Jami At-Tirmidhi: Your smiling in the face of your brother is a charity (Sadaqah) for you.'},
  ];

  @override
  void initState() {
    super.initState();
    hadiths = instantHadiths;
    _loadSurahs();
    _loadHadiths();
  }

  void _loadSurahs() async {
    setState(() => loadingQuran = true);
    try {
      final r = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
      if (r.statusCode == 200 && mounted) {
        setState(() {
          surahs = json.decode(r.body)['data'];
          loadingQuran = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadingQuran = false);
    }
  }

  void _loadHadiths() async {
    setState(() => loadingHadith = true);
    try {
      String lang = appLang == 'ur' ? 'urd' : 'eng';
      final r = await http.get(Uri.parse('https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$lang-$book/sections/$chap.json'));
      if (r.statusCode == 200 && mounted) {
        List fetched = json.decode(r.body)['hadiths'] ?? [];
        if (fetched.isNotEmpty) {
          setState(() => hadiths = fetched);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => loadingHadith = false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredSurahs = surahs.where((s) => s['englishName'].toString().toLowerCase().contains(quranSearch.toLowerCase()) || s['number'].toString().contains(quranSearch)).toList();
    final filteredHadiths = hadiths.where((h) => h['text'].toString().toLowerCase().contains(hadithSearch.toLowerCase()) || h['hadithnumber'].toString().contains(hadithSearch)).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: sec == 0 ? const Color(0xFF10B981) : const Color(0xFF10242D)),
                    onPressed: () => setState(() => sec = 0),
                    child: const Text('📖 Al-Quran (114)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: sec == 1 ? const Color(0xFF10B981) : const Color(0xFF10242D)),
                    onPressed: () => setState(() => sec = 1),
                    child: const Text('📜 Sahih Hadiths'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: sec == 0
                  ? Column(
                      children: [
                        TextField(
                          onChanged: (v) => setState(() => quranSearch = v),
                          decoration: InputDecoration(
                            hintText: '🔍 Search Surah name or number (e.g. Yaseen, 36)...',
                            filled: true,
                            fillColor: const Color(0xFF10242D),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: loadingQuran
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                              : ListView.builder(
                                  itemCount: filteredSurahs.length,
                                  itemBuilder: (ctx, i) {
                                    final s = filteredSurahs[i];
                                    return Card(
                                      color: const Color(0xFF10242D),
                                      child: ListTile(
                                        leading: CircleAvatar(backgroundColor: const Color(0xFF16323F), child: Text('${s['number']}', style: const TextStyle(color: Color(0xFFFFD700)))),
                                        title: Text(s['englishName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${s['englishNameTranslation']} • ${s['numberOfAyahs']} Ayahs'),
                                        trailing: Text(s['name'], style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18)),
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahAudioPage(num: s['number'], name: s['englishName']))),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // Book & Chapter Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DropdownButton<String>(
                              value: book,
                              dropdownColor: const Color(0xFF10242D),
                              items: const [
                                DropdownMenuItem(value: 'bukhari', child: Text('📗 Sahih Bukhari')),
                                DropdownMenuItem(value: 'muslim', child: Text('📘 Sahih Muslim')),
                                DropdownMenuItem(value: 'abudawud', child: Text('📙 Abu Dawood')),
                                DropdownMenuItem(value: 'tirmidhi', child: Text('📕 At-Tirmidhi')),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  book = v!;
                                  chap = 1;
                                });
                                _loadHadiths();
                              },
                            ),
                            Row(
                              children: [
                                if (loadingHadith) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: chap > 1 ? () { setState(() => chap--); _loadHadiths(); } : null,
                                ),
                                Text('Ch $chap', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () { setState(() => chap++); _loadHadiths(); },
                                ),
                              ],
                            ),
                          ],
                        ),
                        // 🔍 NEW HADITH SEARCH BAR
                        TextField(
                          onChanged: (v) => setState(() => hadithSearch = v),
                          decoration: InputDecoration(
                            hintText: '🔍 Search Hadith topic, word or number (e.g. prayer, 1)...',
                            filled: true,
                            fillColor: const Color(0xFF10242D),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredHadiths.length,
                            itemBuilder: (_, i) {
                              final h = filteredHadiths[i];
                              if (h['text'].toString().isEmpty) return const SizedBox.shrink();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('📜 Hadith #${h['hadithnumber']}', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.copy, size: 16, color: Color(0xFF10B981)),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: h['text'].toString()));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hadith Copied!')));
                                          },
                                        ),
                                      ],
                                    ),
                                    if (h['arab'] != null) ...[
                                      Text(h['arab']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                    ],
                                    Text(h['text'].toString(), style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF10B981))),
                                  ],
                                ),
                              );
                            },
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
}

class SurahAudioPage extends StatefulWidget {
  final int num;
  final String name;
  const SurahAudioPage({super.key, required this.num, required this.name});
  @override
  State<SurahAudioPage> createState() => _SurahAudioPageState();
}

class _SurahAudioPageState extends State<SurahAudioPage> {
  List ar = [], tr = [];
  bool loading = true;
  String ed = 'en.asad';
  final player = AudioPlayer();
  int? playingIdx;

  @override
  void initState() {
    super.initState();
    if (appLang == 'hi') ed = 'hi.hindi';
    if (appLang == 'ur') ed = 'ur.jalandhry';
    _load();
    player.onPlayerComplete.listen((_) {
      if (mounted && playingIdx != null && playingIdx! + 1 < ar.length) {
        setState(() => playingIdx = playingIdx! + 1);
        player.play(UrlSource(ar[playingIdx!]['audio']));
      } else if (mounted) {
        setState(() => playingIdx = null);
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _load() async {
    setState(() => loading = true);
    try {
      final r = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah/${widget.num}/editions/ar.alafasy,$ed'));
      if (r.statusCode == 200 && mounted) {
        final d = json.decode(r.body)['data'];
        setState(() {
          ar = d[0]['ayahs'];
          tr = d[1]['ayahs'];
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: const Color(0xFF047857),
        actions: [
          for (var e in [{'l': 'EN', 'c': 'en.asad'}, {'l': 'हिंदी', 'c': 'hi.hindi'}, {'l': 'اردو', 'c': 'ur.jalandhry'}])
            TextButton(
              onPressed: () {
                setState(() => ed = e['c']!);
                _load();
              },
              child: Text(e['l']!, style: TextStyle(color: ed == e['c'] ? const Color(0xFFFFD700) : Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF064E3B),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(playingIdx != null ? 'Playing Ayah ${playingIdx! + 1}/${ar.length}' : '🎧 Non-Stop Full Surah Audio', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: () {
                          if (playingIdx != null) {
                            player.stop();
                            setState(() => playingIdx = null);
                          } else if (ar.isNotEmpty) {
                            setState(() => playingIdx = 0);
                            player.play(UrlSource(ar[0]['audio']));
                          }
                        },
                        child: Text(playingIdx != null ? 'Stop' : '▶️ Play Surah'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: ar.length,
                    itemBuilder: (_, i) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: playingIdx == i ? const Color(0xFF153832) : const Color(0xFF10242D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ayah ${ar[i]['numberInSurah']}', style: const TextStyle(color: Color(0xFFFFD700))),
                              IconButton(
                                icon: Icon(playingIdx == i ? Icons.stop_circle : Icons.play_circle, color: const Color(0xFF10B981)),
                                onPressed: () {
                                  setState(() => playingIdx = i);
                                  player.play(UrlSource(ar[i]['audio']));
                                },
                              ),
                            ],
                          ),
                          Text(ar[i]['text'], textAlign: TextAlign.right, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(tr[i]['text'], style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------- 4. REALISTIC 3D SENSOR QIBLA COMPASS ----------------
class CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final p = Paint()..style = PaintingStyle.stroke;

    for (int deg = 0; deg < 360; deg += 5) {
      final isMajor = deg % 30 == 0;
      p.color = isMajor ? const Color(0xFFFFD700) : Colors.white30;
      p.strokeWidth = isMajor ? 2.5 : 1.0;
      double len = isMajor ? 14.0 : 7.0;
      double rad = deg * math.pi / 180.0;
      Offset p1 = Offset(center.dx + (radius - 6) * math.cos(rad), center.dy + (radius - 6) * math.sin(rad));
      Offset p2 = Offset(center.dx + (radius - 6 - len) * math.cos(rad), center.dy + (radius - 6 - len) * math.sin(rad));
      canvas.drawLine(p1, p2, p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class QiblaTab extends StatefulWidget {
  const QiblaTab({super.key});
  @override
  State<QiblaTab> createState() => _QiblaTabState();
}

class _QiblaTabState extends State<QiblaTab> {
  double heading = 0.0;
  double qiblaAngle = 277.2;
  String locName = 'Rupahi';
  bool sensorActive = false;
  StreamSubscription? _magSub;
  StreamSubscription? _accSub;
  double _ax = 0, _ay = 0, _az = 9.8;

  @override
  void initState() {
    super.initState();
    _loadLocAndQibla();
    _startRealSensors();
  }

  @override
  void dispose() {
    _magSub?.cancel();
    _accSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLocAndQibla() async {
    final prefs = await SharedPreferences.getInstance();
    double lat = prefs.getDouble('lat') ?? 26.4167;
    double lon = prefs.getDouble('lon') ?? 92.7333;
    const double kLat = 21.422487 * math.pi / 180.0, kLon = 39.826206 * math.pi / 180.0;
    double phi = lat * math.pi / 180.0, lam = lon * math.pi / 180.0;
    double y = math.sin(kLon - lam);
    double x = math.cos(phi) * math.tan(kLat) - math.sin(phi) * math.cos(kLon - lam);
    if (mounted) {
      setState(() {
        locName = prefs.getString('loc') ?? 'Rupahi';
        qiblaAngle = ((math.atan2(y, x) * 180.0 / math.pi) + 360.0) % 360.0;
      });
    }
  }

  void _startRealSensors() {
    try {
      _accSub = accelerometerEventStream().listen((e) {
        _ax = e.x;
        _ay = e.y;
        _az = e.z;
      }, onError: (_) {});

      _magSub = magnetometerEventStream().listen((e) {
        // Tilt-compensated 3D Azimuth Calculation
        double normA = math.sqrt(_ax * _ax + _ay * _ay + _az * _az);
        double ax = normA > 0 ? _ax / normA : 0;
        double ay = normA > 0 ? _ay / normA : 0;
        double az = normA > 0 ? _az / normA : 1;

        double pitch = math.asin(-ax);
        double roll = math.atan2(ay, az);

        double mx = e.x * math.cos(pitch) + e.z * math.sin(pitch);
        double my = e.x * math.sin(roll) * math.sin(pitch) + e.y * math.cos(roll) - e.z * math.sin(roll) * math.cos(pitch);

        double deg = (math.atan2(-my, mx) * 180.0 / math.pi + 360.0) % 360.0;

        // Smooth low-pass filter so compass needle moves smoothly with phone
        double diff = deg - heading;
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;
        double smooth = (heading + diff * 0.18 + 360.0) % 360.0;

        if (mounted) {
          setState(() {
            heading = smooth;
            sensorActive = true;
          });
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    double diff = (qiblaAngle - heading + 360.0) % 360.0;
    bool aligned = diff < 8.0 || diff > 352.0;
    if (aligned && sensorActive) HapticFeedback.selectionClick();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧭 Live 3D Sensor Qibla Compass', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 6),
            Text('📍 $locName • Qibla Bearing: ${qiblaAngle.toStringAsFixed(1)}° W-NW', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: aligned ? const Color(0xFF10B981) : const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700)),
              ),
              child: Text(
                aligned
                    ? '🕋 PERFECT! Phone is pointing directly at Holy Kaaba!'
                    : 'Hold phone flat in your hand & rotate your body',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 28),

            // Realistic Metallic 360° Compass Dial
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer Bezel Ring with Glow
                Container(
                  width: 285,
                  height: 285,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF153442),
                        aligned ? const Color(0xFF064E3B) : const Color(0xFF08141A),
                      ],
                    ),
                    border: Border.all(color: aligned ? const Color(0xFF10B981) : const Color(0xFFFFD700), width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: (aligned ? const Color(0xFF10B981) : const Color(0xFFFFD700)).withOpacity(0.28),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

                // Rotating 360° Degree Ticks & N-E-S-W Rose
                Transform.rotate(
                  angle: -heading * (math.pi / 180.0),
                  child: SizedBox(
                    width: 270,
                    height: 270,
                    child: CustomPaint(
                      painter: CompassDialPainter(),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(top: 18, child: Text('N', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 22))),
                          Positioned(bottom: 18, child: Text('S', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18))),
                          Positioned(right: 20, child: Text('E', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18))),
                          Positioned(left: 20, child: Text('W', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18))),
                        ],
                      ),
                    ),
                  ),
                ),

                // Rotating Golden Kaaba Laser Needle
                Transform.rotate(
                  angle: (qiblaAngle - heading) * (math.pi / 180.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFD700), width: 2),
                        ),
                        child: const Text('🕋', style: TextStyle(fontSize: 24)),
                      ),
                      Container(
                        width: 6,
                        height: 85,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFF10B981)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 65),
                    ],
                  ),
                ),

                // Center Brass Pivot Pin
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Live Digital Readout Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      const Text('Phone Heading', style: TextStyle(fontSize: 11, color: Colors.white60)),
                      Text('${heading.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      const Text('Kaaba Angle', style: TextStyle(fontSize: 11, color: Colors.white60)),
                      Text('${qiblaAngle.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 5. AI MUFTI Q&A CHATBOT + TASBEEH & ZAKAT HUB ----------------
class AiMuftiHubTab extends StatefulWidget {
  const AiMuftiHubTab({super.key});
  @override
  State<AiMuftiHubTab> createState() => _AiMuftiHubTabState();
}

class _AiMuftiHubTabState extends State<AiMuftiHubTab> {
  int subTab = 0; // 0 = AI Mufti Chatbot, 1 = Tasbeeh & Zakat Tools
  final TextEditingController msgCtrl = TextEditingController();
  bool isTyping = false;

  final List<Map<String, String>> chatMessages = [
    {
      'sender': 'bot',
      'text': 'Assalamu Alaikum! 🕌 Main aapka **Noor AI Islamic Assistant** hoon.\n\nAap mujhse Namaz, Wudu, Qaza, Zakat, Roza, Dua ya kisi bhi Deeni Masle ke baare mein English, Hindi, Urdu ya Hinglish mein sawal pooch sakte hain!'
    }
  ];

  final List<String> quickQuestions = [
    '💧 Wudu kin cheezon se tootta hai?',
    '🕌 Qaza namaz padhne ka tarika kya hai?',
    '💰 Zakat kis par farz hai (Nisab)?',
    '🤲 Pareshani aur ghabrahat ki dua?',
    '✈️ Safar mein Qasr namaz ka masla?',
  ];

  // Tasbeeh & Zakat state
  int count = 0;
  final g = TextEditingController(), s = TextEditingController(), c = TextEditingController();
  double zakat = 0;

  Future<void> _askAiQuestion(String question) async {
    if (question.trim().isEmpty) return;
    setState(() {
      chatMessages.add({'sender': 'user', 'text': question});
      isTyping = true;
    });
    msgCtrl.clear();

    String reply = '';
    try {
      // Connect to Free Live AI Cloud Endpoint with Quran & Sunnah System Prompt
      final sysPrompt = Uri.encodeComponent(
          'You are a respectful, knowledgeable Sunni Islamic Scholar and Mufti assistant inside the Noor Islamic App. Answer the user question accurately based on the Quran, Sahih Hadith, and authentic Fiqh (mentioning Hanafi/Shafii where relevant). Keep the answer clear, compassionate, and in the same language the user used (Hinglish, Hindi, Urdu, or English). Question: $question');
      final res = await http.get(Uri.parse('https://text.pollinations.ai/$sysPrompt')).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
        reply = res.body.trim();
      }
    } catch (_) {}

    // Built-in Instant Fiqh Fallback Engine if offline
    if (reply.isEmpty) {
      reply = _offlineFiqhAnswer(question);
    }

    if (mounted) {
      setState(() {
        isTyping = false;
        chatMessages.add({'sender': 'bot', 'text': reply});
      });
    }
  }

  String _offlineFiqhAnswer(String q) {
    final l = q.toLowerCase();
    if (l.contains('wudu') || l.contains('wazu') || l.contains('वुज़ू')) {
      return '💧 **Wudu ka Masla (Fiqh Guide):**\n• **Wudu ke 4 Farz hain:** (1) Poora chehra dhona, (2) Dono haath kohniyon samet dhona, (3) Chauthai sar ka masah karna, (4) Dono paon takhno samet dhona.\n• **Wudu kin cheezon se tootta hai:** Peshab/pakhana aane se, hawa kharij hone se, badan se khoon ya peep beh nikalne se (Hanafi), qai (vomiting) bhar-munh aane se, aur tek laga kar gehri neend sone se.';
    } else if (l.contains('qaza') || l.contains('missed') || l.contains('क़ज़ा')) {
      return '🕌 **Qaza Namaz ka Masla:**\n• Agar koi Farz ya Witr namaz waqt par chhoot jaye, toh uski Qaza padhna **Farz** hai.\n• **Tarika:** Niyat mein kahein ki *"Main apni chhooti hui pehli Fajr/Dhuhr ki Qaza padhta hoon."* Sunnatein qaza nahi hoti, sirf **Farz (Fajr 2, Dhuhr 4, Asr 4, Maghrib 3, Isha 4) aur Witr (3 rakat)** ki qaza padhi jati hai.\n• **Waqt:**3 Makrooh auqat (Suraj nikalte waqt, bilkul dopahar Zawal ke waqt, aur Suraj doobte waqt) ko chhod kar kisi bhi waqt Qaza padh sakte hain.';
    } else if (l.contains('zakat') || l.contains('nisab') || l.contains('ज़कात')) {
      return '💰 **Zakat aur Nisab ka Masla:**\n• Jis Musalman ke paas **7.5 Tola Sona (approx 87.48g)** ya **52.5 Tola Chandi (approx 612.36g)** ya iske barabar Cash/Bachat par **1 Hijri saal** guzar jaye, us par kul maal ka **2.5% (Chaliswan hissa)** Zakat dena Farz hai.';
    } else if (l.contains('safar') || l.contains('qasr') || l.contains('travel')) {
      return '✈️ **Safar (Qasr) Namaz ka Masla:**\n• Jab koi shaks apne sheher se **78 Kilometer (48 Miles)** ya isse door jane ke irade se nikle, toh wo **Musafir** kehlata hai.\n• Safar ke dauran 4 Rakat wali Farz namaz (**Dhuhr, Asr, Isha**) ko chota karke **2 Rakat (Qasr)** padhna zaroori hai. Fajr (2) aur Maghrib (3) poori padhi jayengi.';
    }
    return '📖 **Islamic Guidance:**\nAllah Ta\'ala Quran (Surah An-Nahl 16:43) mein farmata hai: *"Agar tum nahi jante toh Ahl-e-Ilm (Ulama) se pooch lo."*\n\n• Kisi bhi ibadat mein **Niyat** sabse ahem hai (Sahih Bukhari #1).\n• Apna internet connection on rakhein taaki main aapko har tafseeli masle ka jawab Quran aur Sahih Hadith ke hawale se de sakoon!';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Sub-tab switcher: AI Mufti Chatbot vs Tasbeeh/Zakat
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: subTab == 0 ? const Color(0xFF10B981) : const Color(0xFF10242D)),
                    onPressed: () => setState(() => subTab = 0),
                    icon: const Icon(Icons.psychology_alt, size: 18),
                    label: const Text('🤖 Ask AI Mufti'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: subTab == 1 ? const Color(0xFF10B981) : const Color(0xFF10242D)),
                    onPressed: () => setState(() => subTab = 1),
                    icon: const Icon(Icons.calculate, size: 18),
                    label: const Text('📿 Tasbeeh & Zakat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: subTab == 0 ? _buildChatbotUI() : _buildToolsUI(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatbotUI() {
    return Column(
      children: [
        // Quick Masla Chips
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quickQuestions.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _askAiQuestion(quickQuestions[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16323F),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                ),
                child: Text(quickQuestions[i], style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Chat Messages Area
        Expanded(
          child: ListView.builder(
            itemCount: chatMessages.length + (isTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == chatMessages.length) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700))),
                      SizedBox(width: 10),
                      Text('AI Mufti Quran & Hadith se jawab dhoondh raha hai...', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                );
              }
              final m = chatMessages[i];
              bool isUser = m['sender'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF047857) : const Color(0xFF10242D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isUser ? const Color(0xFF10B981) : const Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: Text(m['text']!, style: const TextStyle(fontSize: 13.5, height: 1.45, color: Colors.white)),
                ),
              );
            },
          ),
        ),

        // Input Box
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: msgCtrl,
                onSubmitted: _askAiQuestion,
                decoration: InputDecoration(
                  hintText: 'Apna Deeni Masla ya Sawal yahan likhein...',
                  filled: true,
                  fillColor: const Color(0xFF10242D),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFFFD700),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.black),
                onPressed: () => _askAiQuestion(msgCtrl.text),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolsUI() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              const Text('📿 Digital Tasbeeh', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => count++),
                child: CircleAvatar(radius: 55, backgroundColor: const Color(0xFF10B981), child: Text('$count', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              TextButton(onPressed: () => setState(() => count = 0), child: const Text('Reset')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              const Text('🧮 Smart Zakat Calculator (2.5%)', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 18)),
              TextField(controller: g, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gold Value (₹)')),
              TextField(controller: s, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Silver Value (₹)')),
              TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cash / Savings (₹)')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => setState(() => zakat = ((double.tryParse(g.text) ?? 0) + (double.tryParse(s.text) ?? 0) + (double.tryParse(c.text) ?? 0)) * 0.025),
                child: const Text('Calculate Zakat'),
              ),
              const SizedBox(height: 8),
              Text('Payable Zakat: ₹ ${zakat.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
