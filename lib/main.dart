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
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const NoorProfessionalApp());
}

// ---------------- ARCHITECTURAL DESIGN TOKENS ----------------
const Color kBg = Color(0xFF060D0B);
const Color kCard = Color(0xFF0E1B17);
const Color kCardAlt = Color(0xFF132520);
const Color kBorder = Color(0xFF1E352F);
const Color kGold = Color(0xFFD6B36A);
const Color kMint = Color(0xFF2DD4BF);
const Color kMuted = Color(0xFF8A9E97);

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

class NoorProfessionalApp extends StatelessWidget {
  const NoorProfessionalApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOOR',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        primaryColor: kGold,
        cardColor: kCard,
        dividerColor: kBorder,
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
    final pages = [
      HomeScreen(onNav: _nav, onRefresh: () => setState(() {})),
      const WidgetAtelierScreen(),
      const AnalyticsScreen(),
      KitabScreen(initTab: kitSub),
      const QiblaInstrumentScreen(),
      const ScholarAiScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[idx],
      bottomNavigationBar: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1411).withOpacity(0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kBorder, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.grid_view_rounded, 'Home'),
            _navItem(1, Icons.layers_outlined, 'Widgets'),
            _navItem(2, Icons.pie_chart_outline_rounded, 'Tracker'),
            _navItem(3, Icons.menu_book_rounded, 'Kitab'),
            _navItem(4, Icons.explore_outlined, 'Qibla'),
            _navItem(5, Icons.chat_bubble_outline_rounded, 'Scholar'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData ic, String label) {
    bool sel = idx == i;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => idx = i); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: sel ? 12 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? kCardAlt : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: sel ? Border.all(color: kGold.withOpacity(0.35)) : null,
        ),
        child: Row(
          children: [
            Icon(ic, size: 19, color: sel ? kGold : kMuted),
            if (sel) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

class TopoWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = kMint.withOpacity(0.06)..style = PaintingStyle.stroke..strokeWidth = 1.1;
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.15), size.width * 0.42, p);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.15), size.width * 0.28, p);
    final path = Path()..moveTo(0, size.height * 0.78)..quadraticBezierTo(size.width * 0.45, size.height * 0.58, size.width, size.height * 0.85);
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------- 1. PROFESSIONAL ARCHITECTURAL HOME SCREEN ----------------
class HomeScreen extends StatefulWidget {
  final Function(int, {int sub}) onNav;
  final VoidCallback onRefresh;
  const HomeScreen({super.key, required this.onNav, required this.onRefresh});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String loc = 'Barpaka', hijri = '1448 AH';
  double lat = 26.4167, lon = 92.7333;
  int school = 0;
  bool manual = false;
  Timer? timer;
  String currP = 'Fajr', nextP = 'Dhuhr', nextAfterP = 'Asr', countdown = '-04:18:22';

  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, String> times = {'Fajr': '04:15', 'Dhuhr': '12:15', 'Asr': '15:25', 'Maghrib': '16:45', 'Isha': '18:15'};
  Map<String, int> status = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  void _tick() {
    final now = DateTime.now();
    DateTime? nextT;
    int nextIdx = 0;
    for (int i = 0; i < prayers.length; i++) {
      final pts = times[prayers[i]]!.split(':');
      final dt = DateTime(now.year, now.month, now.day, int.parse(pts[0]), int.parse(pts[1]));
      if (dt.isAfter(now)) { nextT = dt; nextIdx = i; break; }
    }
    if (nextT == null) {
      final pts = times['Fajr']!.split(':');
      nextT = DateTime(now.year, now.month, now.day, int.parse(pts[0]), int.parse(pts[1])).add(const Duration(days: 1));
      nextIdx = 0;
    }
    final d = nextT.difference(now);
    if (mounted) {
      setState(() {
        nextP = prayers[nextIdx];
        currP = prayers[(nextIdx - 1 + 5) % 5];
        nextAfterP = prayers[(nextIdx + 1) % 5];
        countdown = '-${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
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
      for (var pr in prayers) {
        status[pr] = p.getInt('st_${tKey}_$pr') ?? 0;
        if (manual) times[pr] = p.getString('mt_$pr') ?? times[pr]!;
      }
    });
    if (!manual) _fetchAPI();
  }

  Future<void> _fetchAPI() async {
    try {
      final r = await http.get(Uri.parse('https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=1&school=$school'));
      if (r.statusCode == 200) {
        final d = json.decode(r.body)['data'];
        setState(() {
          for (var pr in prayers) { times[pr] = d['timings'][pr].toString().split(' ')[0]; }
          hijri = '${d['date']['hijri']['day']} ${d['date']['hijri']['month']['en']} ${d['date']['hijri']['year']}';
        });
      }
    } catch (_) {}
  }

  void _editLoc() {
    final ctrl = TextEditingController(text: loc);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Location Settings', style: TextStyle(fontFamily: 'serif', color: Colors.white)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Enter City / Town')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: kMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kGold),
            onPressed: () async {
              String pl = ctrl.text.trim();
              Navigator.pop(ctx);
              if (pl.isNotEmpty) {
                final p = await SharedPreferences.getInstance();
                await p.setString('loc', pl);
                try {
                  final r = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?q=$pl&format=json&limit=1'), headers: {'User-Agent': 'NoorPro/1.0'});
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
            child: const Text('Update', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int completed = status.values.where((s) => s > 0 && s < 4).length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _editLoc,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                      child: const Icon(Icons.location_on_outlined, size: 15, color: kGold),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                        Text(hijri, style: const TextStyle(fontSize: 11, color: kMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _pillBtn(use12Hour ? '12H' : '24H', () async {
                    final p = await SharedPreferences.getInstance();
                    await p.setBool('use12', !use12Hour);
                    setState(() => use12Hour = !use12Hour);
                  }),
                  const SizedBox(width: 6),
                  _pillBtn(school == 0 ? 'SHAFI' : 'HANAFI', () async {
                    final p = await SharedPreferences.getInstance();
                    await p.setInt('school', school == 0 ? 1 : 0);
                    _load();
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // SIGNATURE EDITORIAL DUAL-PANE HERO CARD
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              height: 205,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0E2923), Color(0xFF071512)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: kBorder, width: 1.2),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: TopoWavePainter())),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 54,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('NOOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.8, color: Colors.white70)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: kGold.withOpacity(0.3))),
                                    child: Text('${currP.toUpperCase()} • CURRENT', style: const TextStyle(fontSize: 8.5, color: kGold, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Text('NEXT PRAYER', style: TextStyle(fontSize: 9.5, color: kMuted, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                              const SizedBox(height: 2),
                              Text(nextP, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                              Text(formatClock(times[nextP]!), style: const TextStyle(fontSize: 24, fontFamily: 'serif', fontWeight: FontWeight.bold, color: Colors.white)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: kCardAlt.withOpacity(0.85), borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        CircleAvatar(radius: 3.5, backgroundColor: kGold),
                                        SizedBox(width: 6),
                                        Text('REMAINING', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white70)),
                                      ],
                                    ),
                                    Text(countdown, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kMint)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), color: Colors.white12),
                        Expanded(
                          flex: 46,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _miniTimelineItem(Icons.wb_twilight_rounded, currP, 'CURRENT', formatClock(times[currP]!), false),
                              _miniTimelineItem(Icons.wb_sunny_outlined, nextP, 'NEXT PRAYER', formatClock(times[nextP]!), true),
                              _miniTimelineItem(Icons.nights_stay_outlined, nextAfterP, '', formatClock(times[nextAfterP]!), false),
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
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SALAH SCHEDULE & TRACKER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 1.2)),
              Text('$completed OF 5 COMPLETED • HOLD TIME TO EDIT', style: const TextStyle(fontSize: 10, color: kGold, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: prayers.map((pr) {
              bool isN = pr == nextP;
              int st = status[pr] ?? 0;
              final stColors = [kMuted, kMint, const Color(0xFF38BDF8), kGold, const Color(0xFFEF4444)];
              final stLabels = ['LOG', 'JAMAAT', 'ON TIME', 'QAZA', 'MISSED'];

              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    int next = ((status[pr] ?? 0) + 1) % 5;
                    final p = await SharedPreferences.getInstance();
                    await p.setInt('st_${getDateKey(DateTime.now())}_$pr', next);
                    HapticFeedback.lightImpact();
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
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isN ? kCardAlt : kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: st > 0 ? stColors[st].withOpacity(0.7) : (isN ? kGold.withOpacity(0.6) : kBorder), width: 1.2),
                    ),
                    child: Column(
                      children: [
                        Text(pr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isN ? kGold : Colors.white)),
                        const SizedBox(height: 4),
                        Text(formatClock(times[pr]!).split(' ')[0], style: const TextStyle(fontSize: 11, fontFamily: 'serif', color: Colors.white70)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: stColors[st].withOpacity(0.14), borderRadius: BorderRadius.circular(6)),
                          child: Text(stLabels[st], style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: stColors[st])),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          const Text('MODULES & INSTRUMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 1.2)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _bentoCard('Al-Quran & Audio', '114 Surahs • Multi-Lang', Icons.menu_book_rounded, kMint, () => widget.onNav(3, sub: 0))),
              const SizedBox(width: 10),
              Expanded(child: _bentoCard('10 Hadith Books', '36,000+ Authentic Hadiths', Icons.library_books_outlined, kGold, () => widget.onNav(3, sub: 1))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _bentoCard('Widget Atelier', 'Dual-Pane Home Widgets', Icons.layers_outlined, kGold, () => widget.onNav(1))),
              const SizedBox(width: 10),
              Expanded(child: _bentoCard('Qibla Instrument', 'Live Gyroscope Compass', Icons.explore_outlined, kMint, () => widget.onNav(4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillBtn(String txt, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
        child: Text(txt, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kGold)),
      ),
    );
  }

  Widget _miniTimelineItem(IconData ic, String name, String tag, String time, bool active) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: active ? 10 : 4, vertical: active ? 9 : 4),
      decoration: active ? BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: kMint.withOpacity(0.3))) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(ic, size: 14, color: active ? kMint : kMuted),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (tag.isNotEmpty) Text(tag, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: active ? kMint : kMuted)),
                ],
              ),
            ],
          ),
          Text(time, style: TextStyle(fontSize: 10.5, fontFamily: 'serif', fontWeight: FontWeight.bold, color: active ? kMint : Colors.white70)),
        ],
      ),
    );
  }

  Widget _bentoCard(String title, String sub, IconData ic, Color col, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(ic, size: 20, color: col),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 3),
            Text(sub, style: const TextStyle(fontSize: 11, color: kMuted)),
          ],
        ),
      ),
    );
  }
}

// ---------------- 2. WIDGET ATELIER ----------------
class WidgetAtelierScreen extends StatefulWidget {
  const WidgetAtelierScreen({super.key});
  @override
  State<WidgetAtelierScreen> createState() => _WidgetAtelierScreenState();
}

class _WidgetAtelierScreenState extends State<WidgetAtelierScreen> {
  int vIdx = 0;
  final verses = const [
    {'ref': 'SURAH ASH-SHARH • 94:5', 'ar': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا', 'hi': '"Beshak, har mushkil ke sath aasani hai."'},
    {'ref': 'SURAH AR-RA\'D • 13:28', 'ar': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', 'hi': '"Sun lo! Allah ke zikr hi se dilon ko sukoon milta hai."'},
    {'ref': 'SURAH AL-BAQARAH • 2:152', 'ar': 'فَاذْكُرُونِي أَذْكُرْكُمْ', 'hi': '"Tum mujhe yaad rakho, main tumhe yaad rakhunga."'},
  ];

  Future<void> _sync() async {
    final p = await SharedPreferences.getInstance();
    final v = verses[vIdx];
    await p.setString('wq_ref', v['ref']!);
    await p.setString('wq_arab', v['ar']!);
    await p.setString('wq_hing', v['hi']!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: kCardAlt, content: Text('Widgets synced to Android Home Screen')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = verses[vIdx];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        children: [
          const Text('WIDGET ATELIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kGold, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text('Home Screen Instruments', style: TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          const Text('1. DUAL-PANE SALAH HORIZON WIDGET', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0E2923), Color(0xFF071512)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(8)), child: const Text('FAJR • CURRENT', style: TextStyle(fontSize: 8.5, color: kGold, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 10),
                      const Text('NEXT PRAYER', style: TextStyle(fontSize: 9, color: kMuted)),
                      const Text('Dhuhr', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('12:15 PM', style: TextStyle(fontSize: 22, fontFamily: 'serif', color: Colors.white)),
                      const SizedBox(height: 10),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(12)), child: const Text('● REMAINING   -04:18:00', style: TextStyle(fontSize: 10, color: kMint, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                Container(width: 1, height: 115, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 12)),
                const Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fajr          04:15 AM', style: TextStyle(fontSize: 11, color: kMuted)),
                      SizedBox(height: 10),
                      Text('Dhuhr       12:15 PM', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kMint)),
                      SizedBox(height: 10),
                      Text('Asr           03:25 PM', style: TextStyle(fontSize: 11, color: kMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. QURANIC MANUSCRIPT WIDGET', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kMuted)),
              GestureDetector(onTap: () => setState(() => vIdx = (vIdx + 1) % verses.length), child: const Text('Cycle Verse ↻', style: TextStyle(fontSize: 11, color: kGold, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0E2923), Color(0xFF071512)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(v['ref']!, style: const TextStyle(fontSize: 9.5, color: kGold, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(v['ar']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Text(v['hi']!, style: const TextStyle(fontSize: 13, fontFamily: 'serif', color: kMint, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kGold, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _sync,
            child: const Text('SYNC WIDGETS TO DEVICE HOME SCREEN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ---------------- 3. ANALYTICS & QAZA LEDGER SCREEN ----------------
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  SharedPreferences? prefs;
  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

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
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        children: [
          const Text('PERFORMANCE LEDGER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kGold, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text('Salah Consistency & Qaza', style: TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(child: _kpi('MONTHLY OFFERED', '$mAda', 'of ${daysInM * 5} prayers', kMint)),
              const SizedBox(width: 10),
              Expanded(child: _kpi('IN CONGREGATION', '$mJamaat', 'Jamaat prayers', kGold)),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('QAZA-E-UMRI LEDGER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kGold)),
                    Text('$qTotal Remaining', style: const TextStyle(fontSize: 12, color: kMint, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: kBorder)),
                  onPressed: () async {
                    for (var p in prayers) { await prefs?.setInt('qb_$p', (prefs?.getInt('qb_$p') ?? 0) + 30); }
                    setState(() {});
                  },
                  child: const Text('+ Add 30 Days Missed Qaza', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                ...prayers.map((p) {
                  int v = prefs?.getInt('qb_$p') ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          Text('$v', style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, color: kGold)),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () async { await prefs?.setInt('qb_$p', math.max(0, v - 1)); setState(() {}); },
                            child: const Text('Log -1 Completed', style: TextStyle(color: kMint, fontSize: 12)),
                          ),
                        ],
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

// ---------------- 4. QURAN & 10-BOOK HADITH VAULT (SCREENSHOT GRID!) ----------------
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

  // 10 Authentic Hadith Books matching User's Screenshot!
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
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
              child: Row(
                children: [
                  _segBtn('AL-QURAN (114)', 0),
                  _segBtn('HADITH VAULT (10 BOOKS)', 1),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: tab == 0 ? _buildQuranView(fS) : _buildHadithBooksGrid(),
            ),
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
            prefixIcon: const Icon(Icons.search, size: 18, color: kGold),
            filled: true,
            fillColor: kCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: loadingQuran
              ? const Center(child: CircularProgressIndicator(color: kGold))
              : ListView.builder(
                  itemCount: fS.length,
                  itemBuilder: (_, i) {
                    final s = fS[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                      child: ListTile(
                        leading: Text('${s['number']}', style: const TextStyle(fontFamily: 'serif', color: kGold, fontWeight: FontWeight.bold)),
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

  // Screenshot-Style 2-Column 10-Book Hadith Grid (In Luxury Dark Theme)
  Widget _buildHadithBooksGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
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
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: c.withOpacity(0.28), width: 1.2),
              ),
              child: Stack(
                children: [
                  // Top-Right Soft Decorative Circle (Like Screenshot)
                  Positioned(
                    top: -22,
                    right: -22,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(color: c.withOpacity(0.08), shape: BoxShape.circle),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Rounded Book Icon Box
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: c.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(b['ic'] as IconData, color: c, size: 24),
                            ),
                            // Hadith Count Badge (7589, 7563, etc.)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                b['count'] as String,
                                style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          b['title'] as String,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        // Bottom Accent Bar (Like Screenshot)
                        Container(
                          width: 32,
                          height: 3.5,
                          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
                        ),
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
          decoration: BoxDecoration(color: sel ? kCardAlt : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(lb, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: sel ? kGold : kMuted))),
        ),
      ),
    );
  }
}

// ---------------- FULL HADITH BOOK READER PAGE (ALL CHAPTERS + ARABIC + EN/URDU) ----------------
class HadithBookReaderPage extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final int maxSections;
  final Color accentColor;

  const HadithBookReaderPage({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.maxSections,
    required this.accentColor,
  });

  @override
  State<HadithBookReaderPage> createState() => _HadithBookReaderPageState();
}

class _HadithBookReaderPageState extends State<HadithBookReaderPage> {
  int section = 1;
  String hLang = 'eng'; // 'eng' or 'urd'
  List transHadiths = [];
  List arabHadiths = [];
  bool loading = true;
  String search = '';

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    setState(() => loading = true);
    try {
      bool isSingleFile = widget.maxSections == 1;
      String tUrl = isSingleFile
          ? 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$hLang-${widget.bookId}.json'
          : 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$hLang-${widget.bookId}/sections/$section.json';

      String aUrl = isSingleFile
          ? 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-${widget.bookId}.json'
          : 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-${widget.bookId}/sections/$section.json';

      final res = await Future.wait([http.get(Uri.parse(tUrl)), http.get(Uri.parse(aUrl))]);
      if (res[0].statusCode == 200 && mounted) {
        final td = json.decode(res[0].body);
        final ad = res[1].statusCode == 200 ? json.decode(res[1].body) : null;
        setState(() {
          transHadiths = td['hadiths'] ?? [];
          arabHadiths = ad != null ? (ad['hadiths'] ?? []) : [];
          loading = false;
        });
      } else if (mounted) {
        // Fallback to English if Urdu isn't available for 40-hadith collections
        if (hLang == 'urd') {
          hLang = 'eng';
          _loadChapter();
          return;
        }
        setState(() => loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = transHadiths.where((h) {
      final t = h['text']?.toString().toLowerCase() ?? '';
      final n = h['hadithnumber']?.toString() ?? '';
      return t.contains(search.toLowerCase()) || n.contains(search);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle, style: const TextStyle(fontFamily: 'serif', fontSize: 17)),
        backgroundColor: kBg,
        actions: [
          TextButton(
            onPressed: () { setState(() => hLang = hLang == 'eng' ? 'urd' : 'eng'); _loadChapter(); },
            child: Text(hLang == 'eng' ? 'اردو' : 'EN', style: const TextStyle(color: kGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chapter Selector Bar (For Multi-Chapter Books like Bukhari 1..97)
          if (widget.maxSections > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: kCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: kGold),
                    onPressed: section > 1 ? () { setState(() => section--); _loadChapter(); } : null,
                  ),
                  DropdownButton<int>(
                    value: section,
                    dropdownColor: kCard,
                    underline: const SizedBox(),
                    items: List.generate(widget.maxSections, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('Chapter / Book ${i + 1} of ${widget.maxSections}', style: const TextStyle(fontWeight: FontWeight.bold, color: kGold, fontSize: 13)),
                    )),
                    onChanged: (v) { if (v != null) { setState(() => section = v); _loadChapter(); } },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: kGold),
                    onPressed: section < widget.maxSections ? () { setState(() => section++); _loadChapter(); } : null,
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: 'Search inside ${widget.bookTitle} (# or word)...',
                prefixIcon: Icon(Icons.search, size: 18, color: widget.accentColor),
                filled: true,
                fillColor: kCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
              ),
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
                      String arab = '';
                      if (i < arabHadiths.length) arab = arabHadiths[i]['text']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: widget.accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${widget.bookTitle} • #${h['hadithnumber']}', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.w800, fontSize: 11)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16, color: kMuted),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: '$arab\n\n$txt\n(${widget.bookTitle} #${h['hadithnumber']})'));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hadith copied')));
                                  },
                                ),
                              ],
                            ),
                            if (arab.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(arab, textAlign: TextAlign.right, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, height: 1.7)),
                              const Divider(color: kBorder, height: 22),
                            ] else
                              const SizedBox(height: 10),
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
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ar.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: playingIdx == i ? kGold : kBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('VERSE ${ar[i]['numberInSurah']}', style: const TextStyle(fontSize: 10, color: kGold, fontWeight: FontWeight.w800)),
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

// ---------------- 5. PRECISION ARCHITECTURAL QIBLA INSTRUMENT ----------------
class PrecisionCompassPainter extends CustomPainter {
  final bool aligned;
  PrecisionCompassPainter(this.aligned);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final p = Paint()..style = PaintingStyle.stroke;

    for (int d = 0; d < 360; d += 3) {
      bool maj = d % 30 == 0;
      p.color = maj ? kGold : Colors.white24;
      p.strokeWidth = maj ? 2.0 : 1.0;
      double len = maj ? 14.0 : 6.0;
      double rad = d * math.pi / 180.0;
      canvas.drawLine(
        Offset(c.dx + (r - 4) * math.cos(rad), c.dy + (r - 4) * math.sin(rad)),
        Offset(c.dx + (r - 4 - len) * math.cos(rad), c.dy + (r - 4 - len) * math.sin(rad)),
        p,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class QiblaInstrumentScreen extends StatefulWidget {
  const QiblaInstrumentScreen({super.key});
  @override
  State<QiblaInstrumentScreen> createState() => _QiblaInstrumentScreenState();
}

class _QiblaInstrumentScreenState extends State<QiblaInstrumentScreen> {
  double heading = 0.0, qibla = 277.2;
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    try {
      sub = magnetometerEventStream().listen((e) {
        double deg = (math.atan2(-e.y, e.x) * 180.0 / math.pi + 360.0) % 360.0;
        double diff = deg - heading;
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;
        if (mounted) setState(() => heading = (heading + diff * 0.18 + 360.0) % 360.0);
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() { sub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    double diff = (qibla - heading + 360.0) % 360.0;
    bool aligned = diff < 7.0 || diff > 353.0;
    if (aligned) HapticFeedback.selectionClick();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 95),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const Text('QIBLA INSTRUMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kGold, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(aligned ? 'Aligned with Makkah' : 'Rotate Device to Align', style: TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold, color: aligned ? kMint : Colors.white)),
              ],
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: kCard, border: Border.all(color: aligned ? kMint : kBorder, width: 2)),
                ),
                Transform.rotate(
                  angle: -heading * (math.pi / 180.0),
                  child: SizedBox(width: 250, height: 250, child: CustomPaint(painter: PrecisionCompassPainter(aligned))),
                ),
                Transform.rotate(
                  angle: (qibla - heading) * (math.pi / 180.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation_rounded, size: 34, color: aligned ? kMint : kGold),
                      Container(width: 2, height: 85, color: aligned ? kMint : kGold),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
                Container(width: 14, height: 14, decoration: BoxDecoration(color: kGold, shape: BoxShape.circle, border: Border.all(color: kBg, width: 3))),
              ],
            ),
            Row(
              children: [
                Expanded(child: _readout('HEADING', '${heading.toStringAsFixed(0)}°')),
                const SizedBox(width: 12),
                Expanded(child: _readout('QIBLA BEARING', '${qibla.toStringAsFixed(1)}°')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _readout(String l, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(children: [Text(l, style: const TextStyle(fontSize: 9.5, color: kMuted, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(v, style: const TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold, color: Colors.white))]),
    );
  }
}

// ---------------- 6. SCHOLAR AI & ZAKAT INSTRUMENT ----------------
class ScholarAiScreen extends StatefulWidget {
  const ScholarAiScreen({super.key});
  @override
  State<ScholarAiScreen> createState() => _ScholarAiScreenState();
}

class _ScholarAiScreenState extends State<ScholarAiScreen> {
  final ctrl = TextEditingController();
  final msgs = [{'sender': 'bot', 'text': 'Assalamu Alaikum. Ask any question regarding Salah, Fiqh, Zakat, or Quranic guidance.'}];

  void _ask(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => msgs.add({'sender': 'user', 'text': q}));
    ctrl.clear();
    String rep = 'In Islamic jurisprudence, actions are judged by intentions (Sahih Bukhari #1). Ensure obligatory prayers and Zakat (2.5% on qualifying wealth held for a lunar year) are fulfilled on time.';
    try {
      final r = await http.get(Uri.parse('https://text.pollinations.ai/${Uri.encodeComponent("Answer concisely and respectfully as a Sunni Islamic scholar: $q")}')).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200 && r.body.isNotEmpty) rep = r.body.trim();
    } catch (_) {}
    if (mounted) setState(() => msgs.add({'sender': 'bot', 'text': rep}));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FIQH & GUIDANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kGold, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            const Text('Scholarly AI Assistant', style: TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  bool u = msgs[i]['sender'] == 'user';
                  return Align(
                    alignment: u ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: u ? kCardAlt : kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: u ? kMint.withOpacity(0.35) : kBorder),
                      ),
                      child: Text(msgs[i]['text']!, style: const TextStyle(fontSize: 13.5, height: 1.45)),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    onSubmitted: _ask,
                    decoration: InputDecoration(
                      hintText: 'Ask a Fiqh or Islamic question...',
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBorder)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(14)),
                  child: IconButton(icon: const Icon(Icons.arrow_upward_rounded, color: Colors.black), onPressed: () => _ask(ctrl.text)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
