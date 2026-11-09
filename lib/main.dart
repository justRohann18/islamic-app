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
      const HubZakatTab(),
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
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Qibla'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Hub/Zakat'),
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
                  // Language Switch
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
                  // 12H / 24H Switch
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

          // Cartoon Mosque Hero Card
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

          // Daily Quranic Wisdom
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
          // Iman Score Hero Ring
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

          // View Switcher
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

          // Selected Date Editor
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

          // Qaza Bank
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

// ---------------- 3. LIVE 114 SURAH AUDIO QURAN & CLOUD HADITH ----------------
class QuranHadithTab extends StatefulWidget {
  const QuranHadithTab({super.key});
  @override
  State<QuranHadithTab> createState() => _QuranHadithTabState();
}

class _QuranHadithTabState extends State<QuranHadithTab> {
  int sec = 0;
  List surahs = [];
  List hadiths = [];
  String book = 'bukhari';
  int chap = 1;

  @override
  void initState() {
    super.initState();
    http.get(Uri.parse('https://api.alquran.cloud/v1/surah')).then((r) {
      if (r.statusCode == 200 && mounted) setState(() => surahs = json.decode(r.body)['data']);
    });
    _loadHadiths();
  }

  void _loadHadiths() async {
    String lang = appLang == 'ur' ? 'urd' : 'eng';
    final r = await http.get(Uri.parse('https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$lang-$book/sections/$chap.json'));
    if (r.statusCode == 200 && mounted) setState(() => hadiths = json.decode(r.body)['hadiths'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
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
                    child: const Text('📜 Live Hadith Cloud'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: sec == 0
                  ? ListView.builder(
                      itemCount: surahs.length,
                      itemBuilder: (ctx, i) {
                        final s = surahs[i];
                        return Card(
                          color: const Color(0xFF10242D),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${s['number']}')),
                            title: Text(s['englishName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${s['numberOfAyahs']} Ayahs'),
                            trailing: Text(s['name'], style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18)),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahAudioPage(num: s['number'], name: s['englishName']))),
                          ),
                        );
                      },
                    )
                  : Column(
                      children: [
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
                        Expanded(
                          child: ListView.builder(
                            itemCount: hadiths.length,
                            itemBuilder: (_, i) {
                              final h = hadiths[i];
                              if (h['text'].toString().isEmpty) return const SizedBox.shrink();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(14)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Hadith #${h['hadithnumber']}', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(h['text'].toString(), style: const TextStyle(fontSize: 14, height: 1.4)),
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
    final r = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah/${widget.num}/editions/ar.alafasy,$ed'));
    if (r.statusCode == 200 && mounted) {
      final d = json.decode(r.body)['data'];
      setState(() {
        ar = d[0]['ayahs'];
        tr = d[1]['ayahs'];
      });
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
              child: Text(e['l']!, style: TextStyle(color: ed == e['c'] ? const Color(0xFFFFD700) : Colors.white)),
            ),
        ],
      ),
      body: Column(
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

// ---------------- 4. QIBLA TAB ----------------
class QiblaTab extends StatefulWidget {
  const QiblaTab({super.key});
  @override
  State<QiblaTab> createState() => _QiblaTabState();
}

class _QiblaTabState extends State<QiblaTab> {
  double rot = 0.0;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧭 3D Qibla Finder (277° W-NW)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
          const SizedBox(height: 30),
          Transform.rotate(
            angle: (277 - rot) * (math.pi / 180),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10242D), border: Border.all(color: const Color(0xFFFFD700), width: 4)),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('🕋', style: TextStyle(fontSize: 40)), Icon(Icons.arrow_upward, size: 50, color: Color(0xFF10B981))]),
            ),
          ),
          const SizedBox(height: 25),
          Slider(activeColor: const Color(0xFFFFD700), min: 0, max: 360, value: rot, onChanged: (v) => setState(() => rot = v)),
        ],
      ),
    );
  }
}

// ---------------- 5. TASBEEH & ZAKAT TAB ----------------
class HubZakatTab extends StatefulWidget {
  const HubZakatTab({super.key});
  @override
  State<HubZakatTab> createState() => _HubZakatTabState();
}

class _HubZakatTabState extends State<HubZakatTab> {
  int count = 0;
  final g = TextEditingController(), s = TextEditingController(), c = TextEditingController();
  double zakat = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
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
      ),
    );
  }
}
