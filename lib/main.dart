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
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const NoorDailyApp());
}

// ---------------- WARM DESERT & EMERALD LUXURY PALETTE ----------------
const Color kBg = Color(0xFF080C0B);
const Color kCard = Color(0xFF111917);
const Color kCardAlt = Color(0xFF192622);
const Color kBorder = Color(0xFF243832);
const Color kAmber = Color(0xFFF59E0B);
const Color kGold = Color(0xFFFBBF24);
const Color kMint = Color(0xFF2DD4BF);
const Color kMuted = Color(0xFF8E9E99);

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
    return '$h12:$mm $ap';
  } catch (_) {
    return raw;
  }
}

String getDateKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

class NoorDailyApp extends StatelessWidget {
  const NoorDailyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOOR',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        primaryColor: kAmber,
        cardColor: kCard,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int idx = 0;
  int kitSub = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() {
        appLang = p.getString('lang') ?? 'en';
        use12Hour = p.getBool('use12') ?? true;
      });
    });
  }

  void _nav(int i, {int sub = 0}) => setState(() { idx = i; kitSub = sub; });

  @override
  Widget build(BuildContext context) {
    // Clean 4-Tab Architecture (Qibla & AI Removed as requested!)
    final pages = [
      InteractiveHomeScreen(onNav: _nav),
      const UniqueWidgetStudioScreen(),
      const AnalyticsLedgerScreen(),
      KitabScreen(initTab: kitSub),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[idx],
      bottomNavigationBar: Container(
        height: 66,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1614).withOpacity(0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kBorder, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.65), blurRadius: 25, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navPill(0, Icons.wb_twilight_rounded, 'Today'),
            _navPill(1, Icons.auto_awesome_mosaic_rounded, 'Widgets'),
            _navPill(2, Icons.insights_rounded, 'Streak'),
            _navPill(3, Icons.menu_book_rounded, 'Kitab'),
          ],
        ),
      ),
    );
  }

  Widget _navPill(int i, IconData ic, String label) {
    bool sel = idx == i;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => idx = i); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: sel ? 18 : 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(colors: [kAmber, Color(0xFFD97706)]) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(ic, size: 20, color: sel ? Colors.black : kMuted),
            if (sel) ...[
              const SizedBox(width: 7),
              Text(label, style: const TextStyle(color: Colors.black, fontSize: 12.5, fontWeight: FontWeight.w900)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- MIHRAB ARCH & CELESTIAL RAYS PAINTER ----------------
class MihrabArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = kAmber.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Islamic Mihrab Arch Silhouette inside Hero Card
    final archPath = Path()
      ..moveTo(size.width * 0.12, size.height)
      ..lineTo(size.width * 0.12, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.12, size.height * 0.08, size.width * 0.5, size.height * 0.02)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.08, size.width * 0.88, size.height * 0.45)
      ..lineTo(size.width * 0.88, size.height);
    canvas.drawPath(archPath, p);

    // Subtle Sun/Moon Horizon Glow
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.25),
      size.width * 0.28,
      Paint()..color = kAmber.withOpacity(0.05),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------- 1. NEW ENGAGING DAILY HABIT HOMEPAGE ----------------
class InteractiveHomeScreen extends StatefulWidget {
  final Function(int, {int sub}) onNav;
  const InteractiveHomeScreen({super.key, required this.onNav});
  @override
  State<InteractiveHomeScreen> createState() => _InteractiveHomeScreenState();
}

class _InteractiveHomeScreenState extends State<InteractiveHomeScreen> {
  String loc = 'Barpaka', hijri = '1448 AH', sunrise = '05:12', sunset = '17:32';
  double lat = 26.4167, lon = 92.7333;
  int school = 0;
  bool manual = false;
  Timer? timer;
  String nextP = 'Dhuhr', countdown = '02h 14m 30s';

  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, String> times = {'Fajr': '04:15', 'Dhuhr': '12:15', 'Asr': '15:25', 'Maghrib': '16:45', 'Isha': '18:15'};
  Map<String, int> status = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

  // Interactive Daily Engagement State (On-Home Tasbih, Sunnahs, Audio)
  int tasbihCount = 0;
  int zikrIdx = 0;
  final List<Map<String, String>> azkar = const [
    {'ar': 'سُبْحَانَ اللَّهِ', 'en': 'SubhanAllah'},
    {'ar': 'الْحَمْدُ لِلَّهِ', 'en': 'Alhamdulillah'},
    {'ar': 'اللَّهُ أَكْبَرُ', 'en': 'Allahu Akbar'},
    {'ar': 'أَسْتَغْفِرُ اللَّهَ', 'en': 'Astaghfirullah'},
  ];

  Map<String, bool> habits = {
    'Morning Adhkar': false,
    'Surah Al-Mulk': false,
    'Istighfar 100x': false,
    'Sleep in Wudu': false,
  };

  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlayingSurah = false;

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    audioPlayer.onPlayerComplete.listen((_) => mounted ? setState(() => isPlayingSurah = false) : null);
  }

  @override
  void dispose() {
    timer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    DateTime? nextT;
    String found = 'Fajr';
    for (var p in prayers) {
      final pts = times[p]!.split(':');
      final dt = DateTime(now.year, now.month, now.day, int.parse(pts[0]), int.parse(pts[1]));
      if (dt.isAfter(now)) { nextT = dt; found = p; break; }
    }
    if (nextT == null) {
      final pts = times['Fajr']!.split(':');
      nextT = DateTime(now.year, now.month, now.day, int.parse(pts[0]), int.parse(pts[1])).add(const Duration(days: 1));
    }
    final d = nextT.difference(now);
    if (mounted) {
      setState(() {
        nextP = found;
        countdown = '${d.inHours.toString().padLeft(2, '0')}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m ${(d.inSeconds % 60).toString().padLeft(2, '0')}s';
      });
    }
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final tKey = getDateKey(DateTime.now());
    setState(() {
      loc = p.getString('loc') ?? 'Barpaka';
      lat = p.getDouble('lat') ?? 26.4167;
      lon = p.getDouble('lon') ?? 92.7333;
      school = p.getInt('school') ?? 0;
      manual = p.getBool('manual') ?? false;
      tasbihCount = p.getInt('home_tasbih') ?? 0;
      for (var pr in prayers) {
        status[pr] = p.getInt('st_${tKey}_$pr') ?? 0;
        if (manual) times[pr] = p.getString('mt_$pr') ?? times[pr]!;
      }
      for (var h in habits.keys.toList()) {
        habits[h] = p.getBool('hb_${tKey}_$h') ?? false;
      }
    });
    if (!manual) _fetchAPI();
    _syncWidgetPrefs();
  }

  Future<void> _syncWidgetPrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('wp_loc', '🕌 NOOR • ${loc.toUpperCase()}');
    await p.setString('wp_next_name', nextP);
    await p.setString('wp_next', formatClock(times[nextP]!));
    await p.setString(
        'wp_strip',
        'Fajr ${formatClock(times['Fajr']!).split(' ')[0]} • Dhuhr ${formatClock(times['Dhuhr']!).split(' ')[0]} • Asr ${formatClock(times['Asr']!).split(' ')[0]} • Mag ${formatClock(times['Maghrib']!).split(' ')[0]} • Isha ${formatClock(times['Isha']!).split(' ')[0]}');
  }

  Future<void> _fetchAPI() async {
    try {
      final r = await http.get(Uri.parse('https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=1&school=$school'));
      if (r.statusCode == 200) {
        final d = json.decode(r.body)['data'];
        setState(() {
          for (var pr in prayers) { times[pr] = d['timings'][pr].toString().split(' ')[0]; }
          sunrise = d['timings']['Sunrise'].toString().split(' ')[0];
          sunset = d['timings']['Sunset'].toString().split(' ')[0];
          hijri = '${d['date']['hijri']['day']} ${d['date']['hijri']['month']['en']} ${d['date']['hijri']['year']}';
        });
        _syncWidgetPrefs();
      }
    } catch (_) {}
  }

  void _editLoc() {
    final ctrl = TextEditingController(text: loc);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Set City / Village', style: TextStyle(color: kGold)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'e.g. Barpaka, Rupahi, Delhi')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAmber),
            onPressed: () async {
              String pl = ctrl.text.trim();
              Navigator.pop(ctx);
              if (pl.isNotEmpty) {
                final p = await SharedPreferences.getInstance();
                await p.setString('loc', pl);
                try {
                  final r = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?q=$pl&format=json&limit=1'), headers: {'User-Agent': 'NoorDaily/1.0'});
                  if (r.statusCode == 200) {
                    final l = json.decode(r.body) as List;
                    if (l.isNotEmpty) {
                      await p.setDouble('lat', double.parse(l[0]['lat']));
                      await p.setDouble('lon', double.parse(l[0]['lon']));
                    }
                  }
                } catch (_) {}
                _load();
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int salahDone = status.values.where((s) => s > 0 && s < 4).length;
    int habitsDone = habits.values.where((v) => v).length;
    double dailyDeenScore = ((salahDone + habitsDone) / 9.0).clamp(0.0, 1.0);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: [
          // 1. TOP BAR WITH LOCATION, HIJRI & QUICK SETTINGS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _editLoc,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kAmber, Color(0xFFD97706)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.place_rounded, size: 16, color: Colors.black),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(loc, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                            const Icon(Icons.arrow_drop_down, size: 18, color: kAmber),
                          ],
                        ),
                        Text('🌙 $hijri', style: const TextStyle(fontSize: 11, color: kGold, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _topChip(use12Hour ? '12H' : '24H', () async {
                    final p = await SharedPreferences.getInstance();
                    await p.setBool('use12', !use12Hour);
                    setState(() => use12Hour = !use12Hour);
                    _syncWidgetPrefs();
                  }),
                  const SizedBox(width: 6),
                  _topChip(school == 0 ? 'SHAFI' : 'HANAFI', () async {
                    final p = await SharedPreferences.getInstance();
                    await p.setInt('school', school == 0 ? 1 : 0);
                    _load();
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 2. THE "GLOWING MIHRAB ARCH" HERO CARD (100% UNIQUE!) 🌟
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF281A0E), Color(0xFF0E1D19), Color(0xFF09110F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kAmber.withOpacity(0.45), width: 1.5),
                boxShadow: [BoxShadow(color: kAmber.withOpacity(0.12), blurRadius: 28, offset: const Offset(0, 10))],
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: MihrabArchPainter())),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        // Top Pill inside Arch
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kAmber.withOpacity(0.5)),
                          ),
                          child: Text(
                            'UPCOMING SALAH • ${nextP.toUpperCase()}',
                            style: const TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Center Big Prayer Time & Live Countdown
                        Text(
                          formatClock(times[nextP]!),
                          style: const TextStyle(fontSize: 42, fontFamily: 'serif', fontWeight: FontWeight.w900, color: Colors.white, height: 1.05),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_outlined, size: 15, color: kMint),
                            const SizedBox(width: 5),
                            Text('Starts in $countdown', style: const TextStyle(color: kMint, fontSize: 13.5, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Suhur / Sunrise / Iftar Ribbon + Daily Deen Ring
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _archStat('🌙 SUHUR', formatClock(times['Fajr']!)),
                              Container(width: 1, height: 24, color: Colors.white12),
                              _archStat('🌅 SUNRISE', formatClock(sunrise)),
                              Container(width: 1, height: 24, color: Colors.white12),
                              _archStat('🌇 IFTAR', formatClock(times['Maghrib']!)),
                              Container(width: 1, height: 24, color: Colors.white12),
                              Column(
                                children: [
                                  const Text('🔥 TODAY', style: TextStyle(fontSize: 9.5, color: kMuted, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('${(dailyDeenScore * 100).toInt()}% Done', style: const TextStyle(fontSize: 12, color: kGold, fontWeight: FontWeight.w900)),
                                ],
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
          const SizedBox(height: 22),

          // 🌟 3. INTERACTIVE 5-SALAH CHECK-IN CARDS (REGULAR DAILY USE!) 🌟
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🕌 Daily Salah Check-In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              Text('$salahDone/5 Offered • Tap to Log / Hold Time', style: const TextStyle(fontSize: 11, color: kGold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: prayers.map((pr) {
              bool isN = pr == nextP;
              int st = status[pr] ?? 0;
              final stCols = [Colors.white24, kMint, const Color(0xFF38BDF8), kAmber, const Color(0xFFEF4444)];
              final stTags = ['Tap +', 'Jamaat', 'OnTime', 'Qaza', 'Missed'];
              final prIcons = {
                'Fajr': Icons.wb_twilight_rounded,
                'Dhuhr': Icons.wb_sunny_rounded,
                'Asr': Icons.wb_cloudy_rounded,
                'Maghrib': Icons.flare_rounded,
                'Isha': Icons.nights_stay_rounded,
              };

              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    int next = ((status[pr] ?? 0) + 1) % 5;
                    final p = await SharedPreferences.getInstance();
                    await p.setInt('st_${getDateKey(DateTime.now())}_$pr', next);
                    HapticFeedback.mediumImpact();
                    setState(() => status[pr] = next);
                  },
                  onLongPress: () async {
                    final pts = times[pr]!.split(':');
                    TimeOfDay? t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(pts[0]), minute: int.parse(pts[1])));
                    if (t != null) {
                      String t24 = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                      final p = await SharedPreferences.getInstance();
                      await p.setString('mt_$pr', t24);
                      await p.setBool('manual', true);
                      setState(() { times[pr] = t24; manual = true; });
                      _syncWidgetPrefs();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: st > 0 && st < 4
                          ? LinearGradient(colors: [stCols[st].withOpacity(0.28), kCard], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                          : (isN ? const LinearGradient(colors: [Color(0xFF291D12), kCard], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null),
                      color: (st == 0 && !isN) ? kCard : null,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: st > 0 ? stCols[st] : (isN ? kAmber : kBorder),
                        width: (st > 0 || isN) ? 1.6 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          st > 0 && st < 4 ? Icons.check_circle_rounded : prIcons[pr],
                          size: 20,
                          color: st > 0 ? stCols[st] : (isN ? kAmber : kMuted),
                        ),
                        const SizedBox(height: 8),
                        Text(pr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isN ? kGold : Colors.white)),
                        const SizedBox(height: 3),
                        Text(formatClock(times[pr]!).split(' ')[0], style: const TextStyle(fontSize: 10.5, fontFamily: 'serif', color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(color: stCols[st].withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
                          child: Text(stTags[st], style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: st == 0 ? Colors.white60 : stCols[st])),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // 🌟 4. INTERACTIVE ON-HOME TASBIH & DAILY SUNNAH ENGINE 🌟
          const Text('⚡ Daily Ibadah & Zikr Engine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),

          Row(
            children: [
              // Left: Interactive Live Tasbih Counter right on Home Screen!
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final p = await SharedPreferences.getInstance();
                    setState(() => tasbihCount++);
                    await p.setInt('home_tasbih', tasbihCount);
                  },
                  child: Container(
                    height: 165,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF142E28), kCard], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kMint.withOpacity(0.45), width: 1.4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => zikrIdx = (zikrIdx + 1) % azkar.length),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
                                child: Text('${azkar[zikrIdx]['en']} ↻', style: const TextStyle(fontSize: 10, color: kMint, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final p = await SharedPreferences.getInstance();
                                setState(() => tasbihCount = 0);
                                await p.setInt('home_tasbih', 0);
                              },
                              child: const Icon(Icons.refresh_rounded, size: 16, color: kMuted),
                            ),
                          ],
                        ),
                        Center(
                          child: Column(
                            children: [
                              Text(azkar[zikrIdx]['ar']!, style: const TextStyle(fontSize: 22, color: kGold, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('$tasbihCount', style: const TextStyle(fontSize: 34, fontFamily: 'serif', fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                        ),
                        const Center(
                          child: Text('TAP CARD TO COUNT 📿', style: TextStyle(fontSize: 9.5, color: kMint, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Right: Quick Audio Tilawat + Hadith Vault Shortcuts
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    // Quick Surah Al-Fatiha / Mulk Audio Card
                    GestureDetector(
                      onTap: () async {
                        if (isPlayingSurah) {
                          await audioPlayer.stop();
                          setState(() => isPlayingSurah = false);
                        } else {
                          setState(() => isPlayingSurah = true);
                          await audioPlayer.play(UrlSource('https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3'));
                        }
                      },
                      child: Container(
                        height: 77,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isPlayingSurah ? kAmber : kBorder),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: kAmber,
                              child: Icon(isPlayingSurah ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 24),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Quick Tilawat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  Text('Listen Mishary Alafasy', style: TextStyle(fontSize: 10.5, color: kMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    // 10 Hadith Books Vault Card
                    GestureDetector(
                      onTap: () => widget.onNav(3, sub: 1),
                      child: Container(
                        height: 77,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: kGold.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.library_books_rounded, color: kGold, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('10 Hadith Books', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  Text('Bukhari, Muslim & More', style: TextStyle(fontSize: 10.5, color: kMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 5. DAILY SUNNAH HABIT PILLS (1-TAP TOGGLE) 🌟
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: habits.keys.map((h) {
              bool done = habits[h] ?? false;
              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final p = await SharedPreferences.getInstance();
                  final tKey = getDateKey(DateTime.now());
                  await p.setBool('hb_${tKey}_$h', !done);
                  setState(() => habits[h] = !done);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: done ? kMint.withOpacity(0.18) : kCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: done ? kMint : kBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 15, color: done ? kMint : kMuted),
                      const SizedBox(width: 6),
                      Text(h, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: done ? Colors.white : Colors.white70)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 🌟 6. DAILY QURANIC VERSE SPOTLIGHT (ARABIC + HINGLISH) 🌟
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A1610), kCard]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kAmber.withOpacity(0.35)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('✨ AYAH OF THE DAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kAmber, letterSpacing: 1.2)),
                    Text('Surah Ash-Sharh • 94:5', style: TextStyle(fontSize: 11, color: kMuted)),
                  ],
                ),
                SizedBox(height: 12),
                Text('فَإِنَّ مَعَ الْعُسْرِ يُسْرًا', textAlign: TextAlign.right, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 8),
                Text('"Beshak, har mushkil ke sath aasani hai."', style: TextStyle(fontSize: 13.5, color: kMint, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topChip(String txt, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
        child: Text(txt, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kGold)),
      ),
    );
  }

  Widget _archStat(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: kMuted, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

// ---------------- 2. NEW ULTRA-COOL "TICKET & CALLIGRAPHY FRAME" WIDGET STUDIO ----------------
class UniqueWidgetStudioScreen extends StatefulWidget {
  const UniqueWidgetStudioScreen({super.key});
  @override
  State<UniqueWidgetStudioScreen> createState() => _UniqueWidgetStudioScreenState();
}

class _UniqueWidgetStudioScreenState extends State<UniqueWidgetStudioScreen> {
  int themeIdx = 0;
  int verseIdx = 0;

  final List<Map<String, dynamic>> styles = const [
    {'name': 'Desert Amber', 'c1': Color(0xFF281A0E), 'c2': Color(0xFF0A110F), 'accent': Color(0xFFF59E0B), 'sub': Color(0xFF2DD4BF)},
    {'name': 'Emerald Noir', 'c1': Color(0xFF0B2E26), 'c2': Color(0xFF06100E), 'accent': Color(0xFF2DD4BF), 'sub': Color(0xFFFBBF24)},
    {'name': 'Royal Velvet', 'c1': Color(0xFF1E1B4B), 'c2': Color(0xFF090A14), 'accent': Color(0xFF818CF8), 'sub': Color(0xFFF59E0B)},
  ];

  final List<Map<String, String>> verses = const [
    {'ref': 'SURAH ASH-SHARH • 94:5', 'ar': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا', 'hi': '"Beshak, har mushkil ke sath aasani hai."'},
    {'ref': 'SURAH AR-RA\'D • 13:28', 'ar': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', 'hi': '"Sun lo! Allah ke zikr hi se dilon ko sukoon milta hai."'},
    {'ref': 'SURAH AL-BAQARAH • 2:152', 'ar': 'فَاذْكُرُونِي أَذْكُرْكُمْ', 'hi': '"Tum mujhe yaad rakho, main tumhe yaad rakhunga."'},
    {'ref': 'SURAH AT-TALAQ • 65:3', 'ar': 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ', 'hi': '"Aur jo Allah par bharosa rakhe, Allah uske liye kaafi hai."'},
  ];

  Future<void> _syncToDevice() async {
    final p = await SharedPreferences.getInstance();
    final v = verses[verseIdx];
    await p.setString('wq_ref', '✨ ${v['ref']}');
    await p.setString('wq_arab', v['ar']!);
    await p.setString('wq_hing', v['hi']!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: kCardAlt, content: Text('✅ Synced! Long-press your Phone Wallpaper -> Widgets -> Add Noor Widgets!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = styles[themeIdx];
    final v = verses[verseIdx];
    final Color ac = st['accent'] as Color;
    final Color sb = st['sub'] as Color;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✨ NEXT-GEN WIDGET LAB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kAmber, letterSpacing: 1.4)),
                  Text('StandBy & Ticket Widgets', style: TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: List.generate(styles.length, (i) {
                  bool sel = themeIdx == i;
                  return GestureDetector(
                    onTap: () => setState(() => themeIdx = i),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: styles[i]['c1'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(color: sel ? kGold : Colors.white24, width: sel ? 2.5 : 1),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 🌟 WIDGET 1: "THE SALAH BOARDING-PASS / HORIZON TICKET" 🌟
          const Text('🕌 1. The Salah Horizon Pass (With 5-Node Progress Track)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [st['c1'] as Color, st['c2'] as Color], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: ac.withOpacity(0.55), width: 1.6),
              boxShadow: [BoxShadow(color: ac.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: sb, shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Text('NOOR SALAH PASS • 1448 AH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: ac, letterSpacing: 1)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12), border: Border.all(color: sb.withOpacity(0.4))),
                      child: Text('SUHUR 04:14 • IFTAR 04:45', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: sb)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UPCOMING PRAYER', style: TextStyle(fontSize: 9.5, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        SizedBox(height: 2),
                        Text('Dhuhr', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.05)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('12:15 PM', style: TextStyle(fontSize: 26, fontFamily: 'serif', fontWeight: FontWeight.bold, color: ac)),
                        Text('Starts in -02h 14m', style: TextStyle(fontSize: 11, color: sb, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 5-Node Connected Progress Track inside Widget!
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _widgetNode('Fajr', '04:15', true, false, ac, sb),
                      _widgetNode('Dhuhr', '12:15', false, true, ac, sb),
                      _widgetNode('Asr', '03:25', false, false, ac, sb),
                      _widgetNode('Maghrib', '04:45', false, false, ac, sb),
                      _widgetNode('Isha', '06:15', false, false, ac, sb),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 🌟 WIDGET 2: "THE FLOATING GLASS CALLIGRAPHY FRAME" (ARABIC + HINGLISH) 🌟
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📖 2. Floating Glass Verse Frame (Arabic + Hinglish)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
              GestureDetector(
                onTap: () { setState(() => verseIdx = (verseIdx + 1) % verses.length); _syncToDevice(); },
                child: Text('Switch Ayah ↻', style: TextStyle(fontSize: 12, color: ac, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [st['c1'] as Color, st['c2'] as Color], begin: Alignment.topRight, end: Alignment.bottomLeft),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: ac.withOpacity(0.55), width: 1.6),
              boxShadow: [BoxShadow(color: ac.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12), border: Border.all(color: ac.withOpacity(0.4))),
                      child: Text('✨ ${v['ref']}', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: ac, letterSpacing: 0.8)),
                    ),
                    Icon(Icons.format_quote_rounded, color: ac, size: 22),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  v['ar']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sb.withOpacity(0.35)),
                  ),
                  child: Text(
                    v['hi']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, fontFamily: 'serif', fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: sb),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAmber,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _syncToDevice,
            icon: const Icon(Icons.bolt_rounded, color: Colors.black),
            label: const Text('ACTIVATE & SYNC BOTH WIDGETS TO PHONE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _widgetNode(String name, String time, bool done, bool current, Color ac, Color sb) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: done ? sb : (current ? ac : Colors.white12),
            shape: BoxShape.circle,
          ),
          child: Icon(done ? Icons.check : (current ? Icons.Schedule : Icons.circle), size: 12, color: (done || current) ? Colors.black : Colors.white38),
        ),
        const SizedBox(height: 5),
        Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: current ? ac : Colors.white)),
        Text(time, style: const TextStyle(fontSize: 9.5, color: Colors.white60)),
      ],
    );
  }
}

// ---------------- 3. STREAK, ANALYTICS, QAZA & ZAKAT LEDGER ----------------
class AnalyticsLedgerScreen extends StatefulWidget {
  const AnalyticsLedgerScreen({super.key});
  @override
  State<AnalyticsLedgerScreen> createState() => _AnalyticsLedgerScreenState();
}

class _AnalyticsLedgerScreenState extends State<AnalyticsLedgerScreen> {
  SharedPreferences? prefs;
  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  final g = TextEditingController(), s = TextEditingController(), c = TextEditingController();
  double zakat = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) => setState(() => prefs = p));
  }

  int _st(DateTime d, String p) => prefs?.getInt('st_${getDateKey(d)}_$p') ?? 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int daysInM = DateUtils.getDaysInMonth(now.year, now.month);
    int mAda = 0, mJamaat = 0;
    for (int i = 1; i <= daysInM; i++) {
      final dt = DateTime(now.year, now.month, i);
      for (var p in prayers) {
        int s = _st(dt, p);
        if (s > 0 && s < 4) mAda++;
        if (s == 1) mJamaat++;
      }
    }
    int qTotal = prayers.fold(0, (a, p) => a + (prefs?.getInt('qb_$p') ?? 0));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          const Text('🔥 STREAK & SPIRITUAL LEDGER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kAmber, letterSpacing: 1.4)),
          const SizedBox(height: 4),
          const Text('Monthly Consistency & Qaza', style: TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _kpi('THIS MONTH ADA', '$mAda', 'of ${daysInM * 5} prayers', kMint)),
              const SizedBox(width: 10),
              Expanded(child: _kpi('IN JAMAAT', '$mJamaat', '27x Reward Prayers', kAmber)),
            ],
          ),
          const SizedBox(height: 16),

          // Monthly Heatmap Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🗓️ 30-DAY CONSISTENCY HEATMAP', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kMuted)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
                  itemCount: daysInM,
                  itemBuilder: (_, i) {
                    final dt = DateTime(now.year, now.month, i + 1);
                    int count = prayers.where((p) { int s = _st(dt, p); return s > 0 && s < 4; }).length;
                    return Container(
                      decoration: BoxDecoration(
                        color: count == 5 ? kMint.withOpacity(0.35) : (count > 0 ? kCardAlt : kBg),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: count == 5 ? kMint : kBorder),
                      ),
                      child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Qaza-e-Umri Bank
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🏦 QAZA-E-UMRI BANK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kAmber)),
                    Text('$qTotal Pending', style: const TextStyle(fontSize: 12, color: kMint, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kCardAlt),
                  onPressed: () async {
                    for (var p in prayers) { await prefs?.setInt('qb_$p', (prefs?.getInt('qb_$p') ?? 0) + 30); }
                    setState(() {});
                  },
                  child: const Text('+ Add 1 Month (30 Days) Missed Qaza', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                ...prayers.map((p) {
                  int v = prefs?.getInt('qb_$p') ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Text('$v', style: const TextStyle(color: kGold, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () async { await prefs?.setInt('qb_$p', math.max(0, v - 1)); setState(() {}); },
                            child: const Text('-1 Paid ✅', style: TextStyle(color: kMint)),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Zakat Calculator
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🧮 ZAKAT CALCULATOR (2.5%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kAmber)),
                TextField(controller: g, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gold Value (₹)')),
                TextField(controller: s, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Silver Value (₹)')),
                TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cash / Savings (₹)')),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kAmber),
                  onPressed: () => setState(() => zakat = ((double.tryParse(g.text) ?? 0) + (double.tryParse(s.text) ?? 0) + (double.tryParse(c.text) ?? 0)) * 0.025),
                  child: const Text('Calculate Zakat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text('Payable Zakat: ₹ ${zakat.toStringAsFixed(2)}', style: const TextStyle(color: kMint, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String val, String sub, Color col) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: kMuted)),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 26, fontFamily: 'serif', fontWeight: FontWeight.bold, color: col)),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }
}

// ---------------- 4. QURAN (114) & 10-BOOK HADITH VAULT ----------------
class KitabScreen extends StatefulWidget {
  final int initTab;
  const KitabScreen({super.key, this.initTab = 0});
  @override
  State<KitabScreen> createState() => _KitabScreenState();
}

class _KitabScreenState extends State<KitabScreen> {
  late int tab;
  List surahs = [];
  bool loadingQuran = true;
  String qSearch = '';

  final List<Map<String, dynamic>> hadithBooks = const [
    {'id': 'bukhari', 'title': 'Sahih\nal-Bukhari', 'count': '7589', 'sec': 97, 'col': Color(0xFF818CF8), 'ic': Icons.book_rounded},
    {'id': 'muslim', 'title': 'Sahih\nMuslim', 'count': '7563', 'sec': 56, 'col': Color(0xFF2DD4BF), 'ic': Icons.menu_book_rounded},
    {'id': 'nasai', 'title': 'Sunan\nan-Nasa\'i', 'count': '5765', 'sec': 51, 'col': Color(0xFFF59E0B), 'ic': Icons.auto_stories_rounded},
    {'id': 'abudawud', 'title': 'Sunan\nAbu Dawud', 'count': '5274', 'sec': 43, 'col': Color(0xFFEF4444), 'ic': Icons.bookmark_rounded},
    {'id': 'tirmidhi', 'title': 'Jami\'\nat-Tirmidhi', 'count': '3998', 'sec': 49, 'col': Color(0xFF38BDF8), 'ic': Icons.library_books_rounded},
    {'id': 'ibnmajah', 'title': 'Sunan\nIbn Majah', 'count': '4343', 'sec': 37, 'col': Color(0xFFC084FC), 'ic': Icons.collections_bookmark_rounded},
    {'id': 'malik', 'title': 'Muwatta\nMalik', 'count': '1858', 'sec': 61, 'col': Color(0xFF34D399), 'ic': Icons.layers_rounded},
    {'id': 'nawawi', 'title': 'An-Nawawi\'s\n40 Hadith', 'count': '42', 'sec': 1, 'col': Color(0xFFF43F5E), 'ic': Icons.star_rounded},
    {'id': 'qudsi', 'title': 'Hadith\nQudsi', 'count': '40', 'sec': 1, 'col': Color(0xFF60A5FA), 'ic': Icons.article_rounded},
    {'id': 'dehlawi', 'title': 'Shah Waliullah\n40 Hadith', 'count': '40', 'sec': 1, 'col': Color(0xFF10B981), 'ic': Icons.history_edu_rounded},
  ];

  @override
  void initState() {
    super.initState();
    tab = widget.initTab;
    http.get(Uri.parse('https://api.alquran.cloud/v1/surah')).then((r) {
      if (r.statusCode == 200 && mounted) setState(() { surahs = json.decode(r.body)['data']; loadingQuran = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final fS = surahs.where((s) => s['englishName'].toString().toLowerCase().contains(qSearch.toLowerCase()) || s['number'].toString().contains(qSearch)).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 85),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
              child: Row(
                children: [
                  _segBtn('📖 AL-QURAN (114)', 0),
                  _segBtn('📚 10 HADITH BOOKS', 1),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: tab == 0 ? _buildQuranView(fS) : _buildHadithBooksGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuranView(List fS) {
    return Column(
      children: [
        TextField(
          onChanged: (v) => setState(() => qSearch = v),
          decoration: InputDecoration(
            hintText: 'Search Surah name or number...',
            prefixIcon: const Icon(Icons.search, size: 18, color: kAmber),
            filled: true,
            fillColor: kCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: loadingQuran
              ? const Center(child: CircularProgressIndicator(color: kAmber))
              : ListView.builder(
                  itemCount: fS.length,
                  itemBuilder: (_, i) {
                    final s = fS[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                      child: ListTile(
                        leading: Text('${s['number']}', style: const TextStyle(fontFamily: 'serif', color: kAmber, fontWeight: FontWeight.bold)),
                        title: Text(s['englishName'], style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${s['englishNameTranslation']} • ${s['numberOfAyahs']} Verses', style: const TextStyle(fontSize: 11, color: kMuted)),
                        trailing: Text(s['name'], style: const TextStyle(fontSize: 18, color: kGold)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReaderPage(num: s['number'], name: s['englishName']))),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHadithBooksGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.08),
      itemCount: hadithBooks.length,
      itemBuilder: (ctx, i) {
        final b = hadithBooks[i];
        final Color c = b['col'] as Color;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HadithBookReaderPage(
                bookId: b['id'] as String,
                bookTitle: b['title'].toString().replaceAll('\n', ' '),
                maxSections: b['sec'] as int,
                accentColor: c,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.withOpacity(0.3), width: 1.2)),
              child: Stack(
                children: [
                  Positioned(top: -22, right: -22, child: Container(width: 90, height: 90, decoration: BoxDecoration(color: c.withOpacity(0.08), shape: BoxShape.circle))),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withOpacity(0.16), borderRadius: BorderRadius.circular(14)), child: Icon(b['ic'] as IconData, color: c, size: 24)),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Text(b['count'] as String, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 12))),
                          ],
                        ),
                        const Spacer(),
                        Text(b['title'] as String, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                        const SizedBox(height: 8),
                        Container(width: 32, height: 3.5, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _segBtn(String lb, int i) {
    bool sel = tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: sel ? kCardAlt : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(lb, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: sel ? kGold : kMuted))),
        ),
      ),
    );
  }
}

class HadithBookReaderPage extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final int maxSections;
  final Color accentColor;
  const HadithBookReaderPage({super.key, required this.bookId, required this.bookTitle, required this.maxSections, required this.accentColor});
  @override
  State<HadithBookReaderPage> createState() => _HadithBookReaderPageState();
}

class _HadithBookReaderPageState extends State<HadithBookReaderPage> {
  int section = 1;
  String hLang = 'eng';
  List transHadiths = [], arabHadiths = [];
  bool loading = true;
  String search = '';

  @override
  void initState() { super.initState(); _loadChapter(); }

  Future<void> _loadChapter() async {
    setState(() => loading = true);
    try {
      bool single = widget.maxSections == 1;
      String tUrl = single ? 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$hLang-${widget.bookId}.json' : 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$hLang-${widget.bookId}/sections/$section.json';
      String aUrl = single ? 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-${widget.bookId}.json' : 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-${widget.bookId}/sections/$section.json';
      final res = await Future.wait([http.get(Uri.parse(tUrl)), http.get(Uri.parse(aUrl))]);
      if (res[0].statusCode == 200 && mounted) {
        final td = json.decode(res[0].body);
        final ad = res[1].statusCode == 200 ? json.decode(res[1].body) : null;
        setState(() { transHadiths = td['hadiths'] ?? []; arabHadiths = ad != null ? (ad['hadiths'] ?? []) : []; loading = false; });
      } else if (mounted) {
        if (hLang == 'urd') { hLang = 'eng'; _loadChapter(); return; }
        setState(() => loading = false);
      }
    } catch (_) { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = transHadiths.where((h) => (h['text']?.toString().toLowerCase() ?? '').contains(search.toLowerCase()) || (h['hadithnumber']?.toString() ?? '').contains(search)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle, style: const TextStyle(fontFamily: 'serif', fontSize: 17)),
        backgroundColor: kBg,
        actions: [
          TextButton(onPressed: () { setState(() => hLang = hLang == 'eng' ? 'urd' : 'eng'); _loadChapter(); }, child: Text(hLang == 'eng' ? 'اردو' : 'EN', style: const TextStyle(color: kGold, fontWeight: FontWeight.bold))),
        ],
      ),
      body: Column(
        children: [
          if (widget.maxSections > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: kCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left, color: kGold), onPressed: section > 1 ? () { setState(() => section--); _loadChapter(); } : null),
                  Text('Chapter $section / ${widget.maxSections}', style: const TextStyle(fontWeight: FontWeight.bold, color: kGold)),
                  IconButton(icon: const Icon(Icons.chevron_right, color: kGold), onPressed: section < widget.maxSections ? () { setState(() => section++); _loadChapter(); } : null),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(hintText: 'Search Hadith # or keyword...', prefixIcon: Icon(Icons.search, size: 18, color: widget.accentColor), filled: true, fillColor: kCard, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: widget.accentColor))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final h = filtered[i];
                      final String txt = h['text']?.toString() ?? '';
                      if (txt.isEmpty) return const SizedBox.shrink();
                      String arab = i < arabHadiths.length ? (arabHadiths[i]['text']?.toString() ?? '') : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('${widget.bookTitle} • #${h['hadithnumber']}', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.w800, fontSize: 11)),
                            if (arab.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(arab, textAlign: TextAlign.right, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, height: 1.6)),
                              const Divider(color: kBorder, height: 20),
                            ] else const SizedBox(height: 8),
                            Text(txt, style: const TextStyle(fontSize: 14, fontFamily: 'serif', color: Colors.white70, height: 1.5)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SurahReaderPage extends StatefulWidget {
  final int num;
  final String name;
  const SurahReaderPage({super.key, required this.num, required this.name});
  @override
  State<SurahReaderPage> createState() => _SurahReaderPageState();
}

class _SurahReaderPageState extends State<SurahReaderPage> {
  List ar = [], tr = [];
  bool loading = true;
  final player = AudioPlayer();
  int? playingIdx;

  @override
  void initState() {
    super.initState();
    http.get(Uri.parse('https://api.alquran.cloud/v1/surah/${widget.num}/editions/ar.alafasy,en.asad')).then((r) {
      if (r.statusCode == 200 && mounted) {
        final d = json.decode(r.body)['data'];
        setState(() { ar = d[0]['ayahs']; tr = d[1]['ayahs']; loading = false; });
      }
    });
  }

  @override
  void dispose() { player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name, style: const TextStyle(fontFamily: 'serif')), backgroundColor: kBg),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kAmber))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ar.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: playingIdx == i ? kAmber : kBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('VERSE ${ar[i]['numberInSurah']}', style: const TextStyle(fontSize: 10, color: kAmber, fontWeight: FontWeight.w800)),
                        IconButton(
                          icon: Icon(playingIdx == i ? Icons.stop_circle_outlined : Icons.play_circle_outline, color: kMint),
                          onPressed: () {
                            if (playingIdx == i) { player.stop(); setState(() => playingIdx = null); }
                            else { setState(() => playingIdx = i); player.play(UrlSource(ar[i]['audio'])); }
                          },
                        ),
                      ],
                    ),
                    Text(ar[i]['text'], textAlign: TextAlign.right, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.7)),
                    const SizedBox(height: 10),
                    Text(tr[i]['text'], style: const TextStyle(fontSize: 13.5, fontFamily: 'serif', color: Colors.white70, height: 1.4)),
                  ],
                ),
              ),
            ),
    );
  }
}
