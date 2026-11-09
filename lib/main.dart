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
  runApp(const NoorCelestialApp());
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
    return '$h12:$mm $ap';
  } catch (_) {
    return raw;
  }
}

String getDateKey(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

class NoorCelestialApp extends StatelessWidget {
  const NoorCelestialApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noor Celestial',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B12), // Deep Obsidian Cosmos
        primaryColor: const Color(0xFFD4AF37), // Royal Metallic Gold
        cardColor: const Color(0xFF111927),
        fontFamily: 'Roboto',
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
  int quranSubTab = 0;

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

  void _go(int newIdx, {int sub = 0}) {
    setState(() {
      idx = newIdx;
      quranSubTab = sub;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CelestialHomeTab(onNavigate: _go, onUpdate: () => setState(() {})),
      const TrackerTab(),
      QuranHadithTab(initialSec: quranSubTab),
      const QiblaTab(),
      const AiMuftiHubTab(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[idx],
      // Floating Obsidian & Gold Glassmorphic Dock
      bottomNavigationBar: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF131C2E), Color(0xFF0B111D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _dockItem(0, Icons.auto_awesome_mosaic_rounded, 'Orbit'),
            _dockItem(1, Icons.donut_large_rounded, 'Iman'),
            _dockItem(2, Icons.menu_book_rounded, 'Kitab'),
            _dockItem(3, Icons.explore_rounded, 'Qibla'),
            _dockItem(4, Icons.psychology_alt_rounded, 'AI Mufti'),
          ],
        ),
      ),
    );
  }

  Widget _dockItem(int i, IconData icon, String label) {
    bool sel = idx == i;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => idx = i);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: sel ? 16 : 10, vertical: 9),
        decoration: BoxDecoration(
          gradient: sel
              ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFF59E0B)])
              : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: sel ? Colors.black : Colors.white60, size: 21),
            if (sel) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- SIGNATURE CELESTIAL SOLAR ORBIT PAINTER ----------------
class CelestialOrbitPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 across the 5 prayers
  final int activePrayerIdx;
  CelestialOrbitPainter({required this.progress, required this.activePrayerIdx});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.92);
    final rx = size.width * 0.44;
    final ry = size.height * 0.72;

    // 1. Subtle Starfield in background
    final starPaint = Paint()..color = Colors.white24;
    for (var pt in [
      Offset(size.width * 0.12, size.height * 0.2),
      Offset(size.width * 0.25, size.height * 0.1),
      Offset(size.width * 0.78, size.height * 0.15),
      Offset(size.width * 0.88, size.height * 0.28),
    ]) {
      canvas.drawCircle(pt, 1.5, starPaint);
    }

    // 2. Dashed / Glowing Horizon Track
    final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    final bgTrack = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawArc(rect, math.pi, math.pi, false, bgTrack);

    // 3. Active Golden Solar Trail
    final activeSweep = math.pi * progress.clamp(0.05, 1.0);
    final fgTrack = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFFD4AF37), Color(0xFFF59E0B)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, activeSweep, false, fgTrack);

    // 4. 5 Prayer Nodes along the Celestial Arc (Fajr, Dhuhr, Asr, Maghrib, Isha)
    for (int i = 0; i < 5; i++) {
      double frac = (i + 0.5) / 5.0;
      double angle = math.pi + (math.pi * frac);
      Offset nodePos = Offset(center.dx + rx * math.cos(angle), center.dy + ry * math.sin(angle));

      bool isPassedOrActive = i <= activePrayerIdx;
      final nodePaint = Paint()
        ..color = isPassedOrActive ? const Color(0xFFD4AF37) : const Color(0xFF1E293B);
      canvas.drawCircle(nodePos, 5.5, nodePaint);
    }

    // 5. Glowing Sun / Moon Orb at Current Time Position
    double sunAngle = math.pi + activeSweep;
    Offset sunPos = Offset(center.dx + rx * math.cos(sunAngle), center.dy + ry * math.sin(sunAngle));

    final haloPaint = Paint()..color = const Color(0xFFD4AF37).withOpacity(0.28);
    canvas.drawCircle(sunPos, 16, haloPaint);

    final corePaint = Paint()..color = const Color(0xFFFFEA79);
    canvas.drawCircle(sunPos, 8.5, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- 1. ORIGINAL "NOOR CELESTIAL" HOME TAB ----------------
class CelestialHomeTab extends StatefulWidget {
  final Function(int, {int sub}) onNavigate;
  final VoidCallback onUpdate;
  const CelestialHomeTab({super.key, required this.onNavigate, required this.onUpdate});
  @override
  State<CelestialHomeTab> createState() => _CelestialHomeTabState();
}

class _CelestialHomeTabState extends State<CelestialHomeTab> {
  String loc = 'Barpaka', hijri = '1448 AH', sunrise = '05:12', sunset = '17:32';
  double lat = 26.4167, lon = 92.7333;
  int school = 0;
  bool manualMode = false;
  Timer? timer;
  String nextP = 'Fajr', countdown = '00:34:39';
  int nextPrayerIndex = 0;
  double orbitProgress = 0.35;

  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, String> times = {
    'Fajr': '04:15',
    'Dhuhr': '12:30',
    'Asr': '14:59',
    'Maghrib': '16:32',
    'Isha': '18:24'
  };
  Map<String, int> status = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

  // Quick Home Audio Player for Surah Al-Mulk / Yaseen
  final AudioPlayer quickPlayer = AudioPlayer();
  bool isPlayingQuickAudio = false;

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    quickPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => isPlayingQuickAudio = false);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    quickPlayer.dispose();
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    DateTime? nextT;
    String found = 'Fajr';
    int foundIdx = 0;

    for (int i = 0; i < prayers.length; i++) {
      final p = prayers[i];
      final parts = times[p]!.split(':');
      final dt = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      if (dt.isAfter(now)) {
        nextT = dt;
        found = p;
        foundIdx = i;
        break;
      }
    }

    if (nextT == null) {
      final parts = times['Fajr']!.split(':');
      nextT = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1])).add(const Duration(days: 1));
      foundIdx = 0;
    }

    final d = nextT.difference(now);
    double dayMinutes = (now.hour * 60 + now.minute) / 1440.0;

    if (mounted) {
      setState(() {
        nextP = found;
        nextPrayerIndex = foundIdx;
        countdown =
            '${d.inHours.toString().padLeft(2, '0')}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m ${(d.inSeconds % 60).toString().padLeft(2, '0')}s';
        orbitProgress = dayMinutes.clamp(0.08, 0.95);
      });
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final tKey = getDateKey(DateTime.now());
    setState(() {
      loc = prefs.getString('loc') ?? 'Barpaka';
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
      final res = await http.get(
          Uri.parse('https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=1&school=$school'));
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

  void _cyclePrayerStatus(String p) async {
    final prefs = await SharedPreferences.getInstance();
    int curr = status[p] ?? 0;
    int next = (curr + 1) % 5; // 0=Pending, 1=Jamaat, 2=OnTime, 3=Qaza, 4=Missed
    await prefs.setInt('st_${getDateKey(DateTime.now())}_$p', next);
    HapticFeedback.lightImpact();
    setState(() => status[p] = next);
  }

  void _openLocationDialog() {
    final ctrl = TextEditingController(text: loc);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111927),
        title: const Text('📍 Set Location', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await http.get(Uri.parse('http://ip-api.com/json'));
                if (res.statusCode == 200) {
                  final d = json.decode(res.body);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('loc', d['city'] ?? 'Barpaka');
                  await prefs.setDouble('lat', (d['lat'] as num).toDouble());
                  await prefs.setDouble('lon', (d['lon'] as num).toDouble());
                  await prefs.setBool('manual', false);
                  _load();
                }
              },
              icon: const Icon(Icons.my_location, color: Colors.white),
              label: const Text('Auto-Detect GPS/IP Location', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'Enter Village / City (e.g. Barpaka, Rupahi)'),
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
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('loc', place);
                try {
                  final r = await http.get(
                      Uri.parse('https://nominatim.openstreetmap.org/search?q=$place&format=json&limit=1'),
                      headers: {'User-Agent': 'NoorCelestial/11.0'});
                  if (r.statusCode == 200) {
                    final list = json.decode(r.body) as List;
                    if (list.isNotEmpty) {
                      await prefs.setDouble('lat', double.parse(list[0]['lat']));
                      await prefs.setDouble('lon', double.parse(list[0]['lon']));
                    }
                  }
                } catch (_) {}
                _load();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int completedCount = status.values.where((s) => s == 1 || s == 2 || s == 3).length;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Minimalist Luxury Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.nights_stay_rounded, color: Color(0xFFD4AF37), size: 16),
                        const SizedBox(width: 6),
                        Text(hijri, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: _openLocationDialog,
                      child: Row(
                        children: [
                          Text(loc, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // 12H / 24H Pill
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('use12', !use12Hour);
                        setState(() => use12Hour = !use12Hour);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151F30),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(use12Hour ? '12H' : '24H',
                            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Shafi / Hanafi Pill
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('school', school == 0 ? 1 : 0);
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151F30),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(school == 0 ? 'SHAFI' : 'HANAFI',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🌟 2. SIGNATURE "CELESTIAL SOLAR ORBIT" DOME CARD 🌟
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.3,
                  colors: [Color(0xFF1A2942), Color(0xFF0D1422), Color(0xFF090D16)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  // Celestial Horizon Arc with Live Sun/Moon Position
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: CelestialOrbitPainter(progress: orbitProgress, activePrayerIdx: nextPrayerIndex),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                            ),
                            child: Text(
                              'UPCOMING • ${nextP.toUpperCase()} AT ${formatClock(times[nextP]!)}',
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            countdown,
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Suhur / Sunrise / Iftar Glassmorphic Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _celestialMiniStat('🌙 Suhur Ends', formatClock(times['Fajr']!)),
                        Container(width: 1, height: 22, color: Colors.white12),
                        _celestialMiniStat('🌅 Sunrise', formatClock(sunrise)),
                        Container(width: 1, height: 22, color: Colors.white12),
                        _celestialMiniStat('🌇 Iftar Time', formatClock(times['Maghrib']!)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🌟 3. UNIFIED 2-IN-1 INTERACTIVE SALAH TIMELINE & TRACKER 🌟
            // (Replaces duplicate prayer lists! Tap = Log Jamaat/Ada, Long-Press = Edit Time)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('⚡ Interactive Salah Strip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                Text(
                  '$completedCount/5 Ada • Tap to Log / Hold to Edit Time',
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: prayers.map((p) {
                bool isNext = (p == nextP);
                int st = status[p] ?? 0;
                // 0=Pending, 1=Jamaat(Green), 2=OnTime(Blue), 3=Qaza(Orange), 4=Missed(Red)
                final statusCols = [Colors.white24, const Color(0xFF10B981), const Color(0xFF38BDF8), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
                final statusLabels = ['Tap', 'Jamaat', 'OnTime', 'Qaza', 'Missed'];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _cyclePrayerStatus(p),
                    onLongPress: () => _pickManualTime(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: isNext
                            ? const LinearGradient(
                                colors: [Color(0xFF1E3246), Color(0xFF121D2B)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isNext ? null : const Color(0xFF111927),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: st > 0 ? statusCols[st] : (isNext ? const Color(0xFFD4AF37) : Colors.white10),
                          width: (isNext || st > 0) ? 1.6 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Status Badge Circle
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: st > 0 ? statusCols[st] : Colors.white10,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: st == 0
                                  ? Icon(Icons.notifications_none, size: 14, color: isNext ? const Color(0xFFD4AF37) : Colors.white54)
                                  : Icon(
                                      st == 4 ? Icons.close : Icons.check,
                                      size: 15,
                                      color: Colors.black,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: isNext ? const Color(0xFFD4AF37) : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            formatClock(times[p]!),
                            style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusCols[st].withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabels[st],
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: st == 0 ? Colors.white54 : statusCols[st]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // 🌟 4. MODERN ASYMMETRIC BENTO GRID (INSPIRING LAYOUT, NOT BORING 12 BOXES!) 🌟
            const Text('✨ Noor Smart Bento Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            const SizedBox(height: 10),

            // Bento Row 1: Wide Live Quran Audio Card + Hadith Vault Card
            Row(
              children: [
                // Wide Quran Audio Bento (Flex 3)
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => widget.onNavigate(2, sub: 0),
                    child: Container(
                      height: 118,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F3D3E), Color(0xFF111927)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.menu_book_rounded, color: Color(0xFF10B981), size: 20),
                                  SizedBox(width: 6),
                                  Text('Al-Quran (114)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              GestureDetector(
                                onTap: () async {
                                  if (isPlayingQuickAudio) {
                                    await quickPlayer.stop();
                                    setState(() => isPlayingQuickAudio = false);
                                  } else {
                                    setState(() => isPlayingQuickAudio = true);
                                    await quickPlayer.play(UrlSource('https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3'));
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: const Color(0xFFD4AF37),
                                  child: Icon(isPlayingQuickAudio ? Icons.stop : Icons.play_arrow, color: Colors.black, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const Text('Read with EN / हिंदी / اردو & Non-Stop Tilawat',
                              style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Hadith Vault Bento (Flex 2)
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => widget.onNavigate(2, sub: 1),
                    child: Container(
                      height: 118,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111927),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.library_books_rounded, color: Color(0xFFD4AF37), size: 26),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hadith Cloud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Bukhari & Muslim', style: TextStyle(fontSize: 11, color: Colors.white60)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bento Row 2: 3 Equal Interactive Tiles (3D Qibla, Iman Analytics, Zakat & Tasbih)
            Row(
              children: [
                _bentoMiniTile('🧭 3D Qibla', 'Live Sensor', const Color(0xFF38BDF8), () => widget.onNavigate(3)),
                const SizedBox(width: 10),
                _bentoMiniTile('📊 Analytics', 'Qaza Bank', const Color(0xFF10B981), () => widget.onNavigate(1)),
                const SizedBox(width: 10),
                _bentoMiniTile('🧮 Zakat 2.5%', '& Tasbih', const Color(0xFFD4AF37), () => widget.onNavigate(4)),
              ],
            ),
            const SizedBox(height: 10),

            // Bento Row 3: Ask AI Mufti Spotlight Banner
            GestureDetector(
              onTap: () => widget.onNavigate(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF111927)]),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.45)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFF312E81),
                      child: Icon(Icons.psychology_alt_rounded, color: Color(0xFFD4AF37)),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🤖 Ask AI Mufti Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          Text('Instant answers on Wudu, Qaza, Zakat & Masail', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Color(0xFFD4AF37)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 5. Daily Quranic Verse Spotlight Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF111927),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('✨ VERSE OF THE DAY', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      Text('Surah Al-Mulk • 67:13', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'وَأَسِرُّوا قَوْلَكُمْ أَوِ اجْهَرُوا بِهِ ۖ إِنَّهُ عَلِيمٌ بِذَاتِ الصُّدُورِ',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '"And conceal your speech or publicize it; indeed, He is Knowing of that within the hearts."',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _celestialMiniStat(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _bentoMiniTile(String title, String sub, Color col, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111927),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: col.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 3),
              Text(sub, style: TextStyle(fontSize: 11, color: col, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF111927),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 75,
                  height: 75,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(value: score / 100, strokeWidth: 8, backgroundColor: Colors.black38, valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37))),
                      Center(child: Text('${score.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('👑 IMAN CONSISTENCY SCORE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
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
                      decoration: BoxDecoration(color: view == i ? const Color(0xFFD4AF37) : const Color(0xFF111927), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(['Weekly (7D)', 'Monthly', 'Yearly'][i], style: TextStyle(color: view == i ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
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
              decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(18)),
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
                        Container(width: 26, height: math.max(10, c * 16.0), decoration: BoxDecoration(color: c == 5 ? const Color(0xFFD4AF37) : const Color(0xFF10B981), borderRadius: BorderRadius.circular(6))),
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
                      color: c == 5 ? const Color(0xFF10B981) : (c > 0 ? const Color(0xFF047857) : const Color(0xFF111927)),
                      borderRadius: BorderRadius.circular(8),
                      border: getDateKey(d) == getDateKey(selDate) ? Border.all(color: const Color(0xFFD4AF37), width: 2) : null,
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
                  decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m], style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                      Text('$tot / ${days * 5}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 Edit Date: ${getDateKey(selDate)} (Tap to cycle status)', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: prayers.map((p) {
                    int s = _st(selDate, p);
                    final cols = [const Color(0xFF1E293B), const Color(0xFF10B981), const Color(0xFF38BDF8), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
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
            decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🏦 Qaza-e-Umri Bank', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)),
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
  final int initialSec;
  const QuranHadithTab({super.key, this.initialSec = 0});
  @override
  State<QuranHadithTab> createState() => _QuranHadithTabState();
}

class _QuranHadithTabState extends State<QuranHadithTab> {
  late int sec;
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
    sec = widget.initialSec;
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
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 85),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: sec == 0 ? const Color(0xFFD4AF37) : const Color(0xFF111927)),
                    onPressed: () => setState(() => sec = 0),
                    child: Text('📖 Al-Quran (114)', style: TextStyle(color: sec == 0 ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: sec == 1 ? const Color(0xFFD4AF37) : const Color(0xFF111927)),
                    onPressed: () => setState(() => sec = 1),
                    child: Text('📜 Sahih Hadiths', style: TextStyle(color: sec == 1 ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
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
                            fillColor: const Color(0xFF111927),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: loadingQuran
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                              : ListView.builder(
                                  itemCount: filteredSurahs.length,
                                  itemBuilder: (ctx, i) {
                                    final s = filteredSurahs[i];
                                    return Card(
                                      color: const Color(0xFF111927),
                                      child: ListTile(
                                        leading: CircleAvatar(backgroundColor: const Color(0xFF1E293B), child: Text('${s['number']}', style: const TextStyle(color: Color(0xFFD4AF37)))),
                                        title: Text(s['englishName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${s['englishNameTranslation']} • ${s['numberOfAyahs']} Ayahs'),
                                        trailing: Text(s['name'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18)),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DropdownButton<String>(
                              value: book,
                              dropdownColor: const Color(0xFF111927),
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
                                Text('Ch $chap', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () { setState(() => chap++); _loadHadiths(); },
                                ),
                              ],
                            ),
                          ],
                        ),
                        TextField(
                          onChanged: (v) => setState(() => hadithSearch = v),
                          decoration: InputDecoration(
                            hintText: '🔍 Search Hadith topic, word or number...',
                            filled: true,
                            fillColor: const Color(0xFF111927),
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
                                decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('📜 Hadith #${h['hadithnumber']}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.copy, size: 16, color: Color(0xFFD4AF37)),
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
                                    Text(h['text'].toString(), style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white70)),
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
        backgroundColor: const Color(0xFF111927),
        actions: [
          for (var e in [{'l': 'EN', 'c': 'en.asad'}, {'l': 'हिंदी', 'c': 'hi.hindi'}, {'l': 'اردو', 'c': 'ur.jalandhry'}])
            TextButton(
              onPressed: () {
                setState(() => ed = e['c']!);
                _load();
              },
              child: Text(e['l']!, style: TextStyle(color: ed == e['c'] ? const Color(0xFFD4AF37) : Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF151F30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(playingIdx != null ? 'Playing Ayah ${playingIdx! + 1}/${ar.length}' : '🎧 Non-Stop Full Surah Audio', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
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
                        color: playingIdx == i ? const Color(0xFF1E293B) : const Color(0xFF111927),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ayah ${ar[i]['numberInSurah']}', style: const TextStyle(color: Color(0xFFD4AF37))),
                              IconButton(
                                icon: Icon(playingIdx == i ? Icons.stop_circle : Icons.play_circle, color: const Color(0xFFD4AF37)),
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
      p.color = isMajor ? const Color(0xFFD4AF37) : Colors.white30;
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
  String locName = 'Barpaka';
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
        locName = prefs.getString('loc') ?? 'Barpaka';
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
        double normA = math.sqrt(_ax * _ax + _ay * _ay + _az * _az);
        double ax = normA > 0 ? _ax / normA : 0;
        double ay = normA > 0 ? _ay / normA : 0;
        double az = normA > 0 ? _az / normA : 1;

        double pitch = math.asin(-ax);
        double roll = math.atan2(ay, az);

        double mx = e.x * math.cos(pitch) + e.z * math.sin(pitch);
        double my = e.x * math.sin(roll) * math.sin(pitch) + e.y * math.cos(roll) - e.z * math.sin(roll) * math.cos(pitch);

        double deg = (math.atan2(-my, mx) * 180.0 / math.pi + 360.0) % 360.0;
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧭 Live 3D Sensor Qibla Compass', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            const SizedBox(height: 6),
            Text('📍 $locName • Qibla Bearing: ${qiblaAngle.toStringAsFixed(1)}° W-NW', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: aligned ? const Color(0xFF10B981) : const Color(0xFF111927),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Text(
                aligned
                    ? '🕋 PERFECT! Phone is pointing directly at Holy Kaaba!'
                    : 'Hold phone flat in your hand & rotate your body',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 28),

            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF111927),
                    border: Border.all(color: aligned ? const Color(0xFF10B981) : const Color(0xFFD4AF37), width: 4),
                  ),
                ),
                Transform.rotate(
                  angle: -heading * (math.pi / 180.0),
                  child: SizedBox(
                    width: 265,
                    height: 265,
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
                          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                        ),
                        child: const Text('🕋', style: TextStyle(fontSize: 24)),
                      ),
                      Container(
                        width: 6,
                        height: 85,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 65),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
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
  int subTab = 0;
  final TextEditingController msgCtrl = TextEditingController();
  bool isTyping = false;

  final List<Map<String, String>> chatMessages = [
    {
      'sender': 'bot',
      'text': 'Assalamu Alaikum! 🕌 Main aapka **Noor AI Islamic Assistant** hoon.\n\nAap mujhse Namaz, Wudu, Qaza, Zakat, Roza, Dua ya kisi bhi Deeni Masle ke baare mein sawal pooch sakte hain!'
    }
  ];

  final List<String> quickQuestions = [
    '💧 Wudu kin cheezon se tootta hai?',
    '🕌 Qaza namaz padhne ka tarika kya hai?',
    '💰 Zakat kis par farz hai (Nisab)?',
    '🤲 Pareshani aur ghabrahat ki dua?',
    '✈️ Safar mein Qasr namaz ka masla?',
  ];

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
      final sysPrompt = Uri.encodeComponent(
          'You are a respectful Sunni Islamic Scholar and Mufti assistant. Answer based on Quran, Sahih Hadith, and Fiqh (Hanafi/Shafii). Keep answer clear in the same language. Question: $question');
      final res = await http.get(Uri.parse('https://text.pollinations.ai/$sysPrompt')).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
        reply = res.body.trim();
      }
    } catch (_) {}

    if (reply.isEmpty) {
      reply = '📖 **Fiqh Guidance:**\nHar Farz ibadat mein Niyat shart hai (Sahih Bukhari #1). Wudu ke 4 Farz hain, aur chhooti hui Farz/Witr namazon ki Qaza lazim hai. Tafseeli jawab ke liye internet on rakhein!';
    }

    if (mounted) {
      setState(() {
        isTyping = false;
        chatMessages.add({'sender': 'bot', 'text': reply});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 85),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: subTab == 0 ? const Color(0xFFD4AF37) : const Color(0xFF111927)),
                    onPressed: () => setState(() => subTab = 0),
                    icon: Icon(Icons.psychology_alt, size: 18, color: subTab == 0 ? Colors.black : Colors.white),
                    label: Text('🤖 Ask AI Mufti', style: TextStyle(color: subTab == 0 ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: subTab == 1 ? const Color(0xFFD4AF37) : const Color(0xFF111927)),
                    onPressed: () => setState(() => subTab = 1),
                    icon: Icon(Icons.calculate, size: 18, color: subTab == 1 ? Colors.black : Colors.white),
                    label: Text('📿 Tasbih & Zakat', style: TextStyle(color: subTab == 1 ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(child: subTab == 0 ? _buildChatbotUI() : _buildToolsUI()),
          ],
        ),
      ),
    );
  }

  Widget _buildChatbotUI() {
    return Column(
      children: [
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
                  color: const Color(0xFF111927),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                ),
                child: Text(quickQuestions[i], style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: chatMessages.length + (isTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == chatMessages.length) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('AI Mufti typing...', style: TextStyle(fontSize: 12, color: Colors.white70)),
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
                    color: isUser ? const Color(0xFF0F3D3E) : const Color(0xFF111927),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isUser ? const Color(0xFF10B981) : const Color(0xFFD4AF37).withOpacity(0.3)),
                  ),
                  child: Text(m['text']!, style: const TextStyle(fontSize: 13.5, height: 1.45, color: Colors.white)),
                ),
              );
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: msgCtrl,
                onSubmitted: _askAiQuestion,
                decoration: InputDecoration(
                  hintText: 'Ask any Islamic question...',
                  filled: true,
                  fillColor: const Color(0xFF111927),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFD4AF37),
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
          decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              const Text('📿 Digital Tasbih', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => count++),
                child: CircleAvatar(radius: 55, backgroundColor: const Color(0xFFD4AF37), child: Text('$count', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black))),
              ),
              TextButton(onPressed: () => setState(() => count = 0), child: const Text('Reset')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              const Text('🧮 Smart Zakat Calculator (2.5%)', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 18)),
              TextField(controller: g, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gold Value (₹)')),
              TextField(controller: s, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Silver Value (₹)')),
              TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cash / Savings (₹)')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => setState(() => zakat = ((double.tryParse(g.text) ?? 0) + (double.tryParse(s.text) ?? 0) + (double.tryParse(c.text) ?? 0)) * 0.025),
                child: const Text('Calculate Zakat'),
              ),
              const SizedBox(height: 8),
              Text('Payable Zakat: ₹ ${zakat.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
