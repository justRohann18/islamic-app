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
        scaffoldBackgroundColor: const Color(0xFF070B12),
        primaryColor: const Color(0xFFD4AF37),
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
      const WidgetStudioTab(),
      const TrackerTab(),
      QuranHadithTab(initialSec: quranSubTab),
      const QiblaTab(),
      const AiMuftiHubTab(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[idx],
      bottomNavigationBar: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF131C2E), Color(0xFF0B111D)]),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _dockItem(0, Icons.auto_awesome_mosaic_rounded, 'Orbit'),
            _dockItem(1, Icons.widgets_rounded, 'Widgets'),
            _dockItem(2, Icons.donut_large_rounded, 'Iman'),
            _dockItem(3, Icons.menu_book_rounded, 'Kitab'),
            _dockItem(4, Icons.explore_rounded, 'Qibla'),
            _dockItem(5, Icons.psychology_alt_rounded, 'Mufti'),
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
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: sel ? 12 : 8, vertical: 9),
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFF59E0B)]) : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: sel ? Colors.black : Colors.white60, size: 20),
            if (sel) ...[
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- CELESTIAL SOLAR ORBIT PAINTER ----------------
class CelestialOrbitPainter extends CustomPainter {
  final double progress;
  final int activePrayerIdx;
  CelestialOrbitPainter({required this.progress, required this.activePrayerIdx});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.92);
    final rx = size.width * 0.44, ry = size.height * 0.72;
    final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);

    canvas.drawArc(rect, math.pi, math.pi, false, Paint()..color = Colors.white12..style = PaintingStyle.stroke..strokeWidth = 3.0);

    final activeSweep = math.pi * progress.clamp(0.05, 1.0);
    final fgTrack = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF10B981), Color(0xFFD4AF37), Color(0xFFF59E0B)]).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, activeSweep, false, fgTrack);

    for (int i = 0; i < 5; i++) {
      double angle = math.pi + (math.pi * ((i + 0.5) / 5.0));
      Offset nodePos = Offset(center.dx + rx * math.cos(angle), center.dy + ry * math.sin(angle));
      canvas.drawCircle(nodePos, 5.5, Paint()..color = i <= activePrayerIdx ? const Color(0xFFD4AF37) : const Color(0xFF1E293B));
    }

    double sunAngle = math.pi + activeSweep;
    Offset sunPos = Offset(center.dx + rx * math.cos(sunAngle), center.dy + ry * math.sin(sunAngle));
    canvas.drawCircle(sunPos, 15, Paint()..color = const Color(0xFFD4AF37).withOpacity(0.28));
    canvas.drawCircle(sunPos, 8, Paint()..color = const Color(0xFFFFEA79));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- 1. CELESTIAL HOME TAB ----------------
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
  Map<String, String> times = {'Fajr': '04:15', 'Dhuhr': '12:30', 'Asr': '14:59', 'Maghrib': '16:32', 'Isha': '18:24'};
  Map<String, int> status = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

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
    }
    final d = nextT.difference(now);
    if (mounted) {
      setState(() {
        nextP = found;
        nextPrayerIndex = foundIdx;
        countdown = '${d.inHours.toString().padLeft(2, '0')}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m ${(d.inSeconds % 60).toString().padLeft(2, '0')}s';
        orbitProgress = ((now.hour * 60 + now.minute) / 1440.0).clamp(0.08, 0.95);
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
    _syncPrayerWidgetData();
  }

  Future<void> _syncPrayerWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    int done = status.values.where((s) => s == 1 || s == 2 || s == 3).length;
    await prefs.setString('wp_loc', '🕌 $loc • $hijri • $done/5 Ada');
    await prefs.setString('wp_next', 'Next: $nextP (${formatClock(times[nextP]!)}) • Iftar: ${formatClock(times['Maghrib']!)}');
    await prefs.setString('wp_strip', 'Fajr ${formatClock(times['Fajr']!)} | Dhuhr ${formatClock(times['Dhuhr']!)} | Asr ${formatClock(times['Asr']!)} | Mag ${formatClock(times['Maghrib']!)} | Isha ${formatClock(times['Isha']!)}');
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
        _syncPrayerWidgetData();
      }
    } catch (_) {}
  }

  void _pickManualTime(String p) async {
    final parts = times[p]!.split(':');
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
    if (picked != null) {
      String t24 = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mt_$p', t24);
      await prefs.setBool('manual', true);
      setState(() {
        times[p] = t24;
        manualMode = true;
      });
      _syncPrayerWidgetData();
    }
  }

  void _cyclePrayerStatus(String p) async {
    final prefs = await SharedPreferences.getInstance();
    int next = ((status[p] ?? 0) + 1) % 5;
    await prefs.setInt('st_${getDateKey(DateTime.now())}_$p', next);
    HapticFeedback.lightImpact();
    setState(() => status[p] = next);
    _syncPrayerWidgetData();
  }

  void _openLocationDialog() {
    final ctrl = TextEditingController(text: loc);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111927),
        title: const Text('📍 Set Location', style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Enter Village / City (e.g. Barpaka, Rupahi)')),
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
                  final r = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?q=$place&format=json&limit=1'), headers: {'User-Agent': 'NoorCelestial/12.0'});
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🌙 $hijri', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13)),
                    GestureDetector(
                      onTap: _openLocationDialog,
                      child: Row(
                        children: [
                          Text(loc, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('use12', !use12Hour);
                        setState(() => use12Hour = !use12Hour);
                        _syncPrayerWidgetData();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF151F30), borderRadius: BorderRadius.circular(14)),
                        child: Text(use12Hour ? '12H' : '24H', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('school', school == 0 ? 1 : 0);
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF151F30), borderRadius: BorderRadius.circular(14)),
                        child: Text(school == 0 ? 'SHAFI' : 'HANAFI', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const RadialGradient(center: Alignment.topCenter, radius: 1.3, colors: [Color(0xFF1A2942), Color(0xFF0D1422), Color(0xFF090D16)]),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1.2),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 115,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: CelestialOrbitPainter(progress: orbitProgress, activePrayerIdx: nextPrayerIndex),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('UPCOMING • ${nextP.toUpperCase()} AT ${formatClock(times[nextP]!)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10.5, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(countdown, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _celestialMiniStat('🌙 Suhur', formatClock(times['Fajr']!)),
                        _celestialMiniStat('🌅 Sunrise', formatClock(sunrise)),
                        _celestialMiniStat('🌇 Iftar', formatClock(times['Maghrib']!)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('⚡ Interactive Salah Strip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$completedCount/5 Ada • Tap to Log / Hold Time', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: prayers.map((p) {
                bool isNext = (p == nextP);
                int st = status[p] ?? 0;
                final statusCols = [Colors.white24, const Color(0xFF10B981), const Color(0xFF38BDF8), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
                final statusLabels = ['Tap', 'Jamaat', 'OnTime', 'Qaza', 'Missed'];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _cyclePrayerStatus(p),
                    onLongPress: () => _pickManualTime(p),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isNext ? const Color(0xFF1A2942) : const Color(0xFF111927),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: st > 0 ? statusCols[st] : (isNext ? const Color(0xFFD4AF37) : Colors.white10), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: st > 0 ? statusCols[st] : Colors.white10,
                            child: Icon(st == 0 ? Icons.notifications_none : (st == 4 ? Icons.close : Icons.check), size: 13, color: st == 0 ? Colors.white70 : Colors.black),
                          ),
                          const SizedBox(height: 6),
                          Text(p, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isNext ? const Color(0xFFD4AF37) : Colors.white)),
                          Text(formatClock(times[p]!), style: const TextStyle(fontSize: 9.5, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(statusLabels[st], style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: st == 0 ? Colors.white54 : statusCols[st])),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text('✨ Noor Smart Bento Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => widget.onNavigate(3, sub: 0),
                    child: Container(
                      height: 110,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0F3D3E), Color(0xFF111927)]),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('📖 Al-Quran (114)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                                  radius: 14,
                                  backgroundColor: const Color(0xFFD4AF37),
                                  child: Icon(isPlayingQuickAudio ? Icons.stop : Icons.play_arrow, color: Colors.black, size: 16),
                                ),
                              ),
                            ],
                          ),
                          const Text('Multi-Language & Non-Stop Tilawat', style: TextStyle(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => widget.onNavigate(1),
                    child: Container(
                      height: 110,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2E1F0F), Color(0xFF111927)]),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.widgets_rounded, color: Color(0xFFD4AF37), size: 24),
                          Text('VIP Widgets\nQuran & Salah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                _bentoMiniTile('🕋 Royal Qibla', '3D Astrolabe', const Color(0xFFD4AF37), () => widget.onNavigate(4)),
                const SizedBox(width: 10),
                _bentoMiniTile('📜 Hadiths', 'Bukhari Cloud', const Color(0xFF38BDF8), () => widget.onNavigate(3, sub: 1)),
                const SizedBox(width: 10),
                _bentoMiniTile('🤖 AI Mufti', '& Zakat Hub', const Color(0xFF10B981), () => widget.onNavigate(5)),
              ],
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
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
      ],
    );
  }

  Widget _bentoMiniTile(String title, String sub, Color col, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(18), border: Border.all(color: col.withOpacity(0.35))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(sub, style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
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
        scaffoldBackgroundColor: const Color(0xFF070B12),
        primaryColor: const Color(0xFFD4AF37),
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
      const WidgetStudioTab(),
      const TrackerTab(),
      QuranHadithTab(initialSec: quranSubTab),
      const QiblaTab(),
      const AiMuftiHubTab(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[idx],
      bottomNavigationBar: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF131C2E), Color(0xFF0B111D)]),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _dockItem(0, Icons.auto_awesome_mosaic_rounded, 'Orbit'),
            _dockItem(1, Icons.widgets_rounded, 'Widgets'),
            _dockItem(2, Icons.donut_large_rounded, 'Iman'),
            _dockItem(3, Icons.menu_book_rounded, 'Kitab'),
            _dockItem(4, Icons.explore_rounded, 'Qibla'),
            _dockItem(5, Icons.psychology_alt_rounded, 'Mufti'),
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
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: sel ? 12 : 8, vertical: 9),
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFF59E0B)]) : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: sel ? Colors.black : Colors.white60, size: 20),
            if (sel) ...[
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- CELESTIAL SOLAR ORBIT PAINTER ----------------
class CelestialOrbitPainter extends CustomPainter {
  final double progress;
  final int activePrayerIdx;
  CelestialOrbitPainter({required this.progress, required this.activePrayerIdx});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.92);
    final rx = size.width * 0.44, ry = size.height * 0.72;
    final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);

    canvas.drawArc(rect, math.pi, math.pi, false, Paint()..color = Colors.white12..style = PaintingStyle.stroke..strokeWidth = 3.0);

    final activeSweep = math.pi * progress.clamp(0.05, 1.0);
    final fgTrack = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF10B981), Color(0xFFD4AF37), Color(0xFFF59E0B)]).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, activeSweep, false, fgTrack);

    for (int i = 0; i < 5; i++) {
      double angle = math.pi + (math.pi * ((i + 0.5) / 5.0));
      Offset nodePos = Offset(center.dx + rx * math.cos(angle), center.dy + ry * math.sin(angle));
      canvas.drawCircle(nodePos, 5.5, Paint()..color = i <= activePrayerIdx ? const Color(0xFFD4AF37) : const Color(0xFF1E293B));
    }

    double sunAngle = math.pi + activeSweep;
    Offset sunPos = Offset(center.dx + rx * math.cos(sunAngle), center.dy + ry * math.sin(sunAngle));
    canvas.drawCircle(sunPos, 15, Paint()..color = const Color(0xFFD4AF37).withOpacity(0.28));
    canvas.drawCircle(sunPos, 8, Paint()..color = const Color(0xFFFFEA79));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- 1. CELESTIAL HOME TAB ----------------
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
  Map<String, String> times = {'Fajr': '04:15', 'Dhuhr': '12:30', 'Asr': '14:59', 'Maghrib': '16:32', 'Isha': '18:24'};
  Map<String, int> status = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

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
    }
    final d = nextT.difference(now);
    if (mounted) {
      setState(() {
        nextP = found;
        nextPrayerIndex = foundIdx;
        countdown = '${d.inHours.toString().padLeft(2, '0')}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m ${(d.inSeconds % 60).toString().padLeft(2, '0')}s';
        orbitProgress = ((now.hour * 60 + now.minute) / 1440.0).clamp(0.08, 0.95);
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
    _syncPrayerWidgetData();
  }

  Future<void> _syncPrayerWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    int done = status.values.where((s) => s == 1 || s == 2 || s == 3).length;
    await prefs.setString('wp_loc', '🕌 $loc • $hijri • $done/5 Ada');
    await prefs.setString('wp_next', 'Next: $nextP (${formatClock(times[nextP]!)}) • Iftar: ${formatClock(times['Maghrib']!)}');
    await prefs.setString('wp_strip', 'Fajr ${formatClock(times['Fajr']!)} | Dhuhr ${formatClock(times['Dhuhr']!)} | Asr ${formatClock(times['Asr']!)} | Mag ${formatClock(times['Maghrib']!)} | Isha ${formatClock(times['Isha']!)}');
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
        _syncPrayerWidgetData();
      }
    } catch (_) {}
  }

  void _pickManualTime(String p) async {
    final parts = times[p]!.split(':');
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
    if (picked != null) {
      String t24 = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mt_$p', t24);
      await prefs.setBool('manual', true);
      setState(() {
        times[p] = t24;
        manualMode = true;
      });
      _syncPrayerWidgetData();
    }
  }

  void _cyclePrayerStatus(String p) async {
    final prefs = await SharedPreferences.getInstance();
    int next = ((status[p] ?? 0) + 1) % 5;
    await prefs.setInt('st_${getDateKey(DateTime.now())}_$p', next);
    HapticFeedback.lightImpact();
    setState(() => status[p] = next);
    _syncPrayerWidgetData();
  }

  void _openLocationDialog() {
    final ctrl = TextEditingController(text: loc);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111927),
        title: const Text('📍 Set Location', style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Enter Village / City (e.g. Barpaka, Rupahi)')),
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
                  final r = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?q=$place&format=json&limit=1'), headers: {'User-Agent': 'NoorCelestial/12.0'});
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🌙 $hijri', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13)),
                    GestureDetector(
                      onTap: _openLocationDialog,
                      child: Row(
                        children: [
                          Text(loc, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('use12', !use12Hour);
                        setState(() => use12Hour = !use12Hour);
                        _syncPrayerWidgetData();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF151F30), borderRadius: BorderRadius.circular(14)),
                        child: Text(use12Hour ? '12H' : '24H', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('school', school == 0 ? 1 : 0);
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF151F30), borderRadius: BorderRadius.circular(14)),
                        child: Text(school == 0 ? 'SHAFI' : 'HANAFI', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const RadialGradient(center: Alignment.topCenter, radius: 1.3, colors: [Color(0xFF1A2942), Color(0xFF0D1422), Color(0xFF090D16)]),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1.2),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 115,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: CelestialOrbitPainter(progress: orbitProgress, activePrayerIdx: nextPrayerIndex),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('UPCOMING • ${nextP.toUpperCase()} AT ${formatClock(times[nextP]!)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10.5, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(countdown, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _celestialMiniStat('🌙 Suhur', formatClock(times['Fajr']!)),
                        _celestialMiniStat('🌅 Sunrise', formatClock(sunrise)),
                        _celestialMiniStat('🌇 Iftar', formatClock(times['Maghrib']!)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('⚡ Interactive Salah Strip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$completedCount/5 Ada • Tap to Log / Hold Time', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: prayers.map((p) {
                bool isNext = (p == nextP);
                int st = status[p] ?? 0;
                final statusCols = [Colors.white24, const Color(0xFF10B981), const Color(0xFF38BDF8), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
                final statusLabels = ['Tap', 'Jamaat', 'OnTime', 'Qaza', 'Missed'];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _cyclePrayerStatus(p),
                    onLongPress: () => _pickManualTime(p),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isNext ? const Color(0xFF1A2942) : const Color(0xFF111927),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: st > 0 ? statusCols[st] : (isNext ? const Color(0xFFD4AF37) : Colors.white10), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: st > 0 ? statusCols[st] : Colors.white10,
                            child: Icon(st == 0 ? Icons.notifications_none : (st == 4 ? Icons.close : Icons.check), size: 13, color: st == 0 ? Colors.white70 : Colors.black),
                          ),
                          const SizedBox(height: 6),
                          Text(p, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isNext ? const Color(0xFFD4AF37) : Colors.white)),
                          Text(formatClock(times[p]!), style: const TextStyle(fontSize: 9.5, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(statusLabels[st], style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: st == 0 ? Colors.white54 : statusCols[st])),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text('✨ Noor Smart Bento Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => widget.onNavigate(3, sub: 0),
                    child: Container(
                      height: 110,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0F3D3E), Color(0xFF111927)]),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('📖 Al-Quran (114)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                                  radius: 14,
                                  backgroundColor: const Color(0xFFD4AF37),
                                  child: Icon(isPlayingQuickAudio ? Icons.stop : Icons.play_arrow, color: Colors.black, size: 16),
                                ),
                              ),
                            ],
                          ),
                          const Text('Multi-Language & Non-Stop Tilawat', style: TextStyle(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => widget.onNavigate(1),
                    child: Container(
                      height: 110,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2E1F0F), Color(0xFF111927)]),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.widgets_rounded, color: Color(0xFFD4AF37), size: 24),
                          Text('VIP Widgets\nQuran & Salah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                _bentoMiniTile('🕋 Royal Qibla', '3D Astrolabe', const Color(0xFFD4AF37), () => widget.onNavigate(4)),
                const SizedBox(width: 10),
                _bentoMiniTile('📜 Hadiths', 'Bukhari Cloud', const Color(0xFF38BDF8), () => widget.onNavigate(3, sub: 1)),
                const SizedBox(width: 10),
                _bentoMiniTile('🤖 AI Mufti', '& Zakat Hub', const Color(0xFF10B981), () => widget.onNavigate(5)),
              ],
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
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
      ],
    );
  }

  Widget _bentoMiniTile(String title, String sub, Color col, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(18), border: Border.all(color: col.withOpacity(0.35))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(sub, style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
// ---------------- 2. SIGNATURE "NOOR HORIZON" SPLIT-PANE WIDGET STUDIO ----------------
class WidgetTopoPainter extends CustomPainter {
  final Color lineColor;
  WidgetTopoPainter(this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = lineColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Subtle Celestial Contour Rings (My Signature Touch!)
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), size.width * 0.45, p);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), size.width * 0.32, p);

    final wave = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.55, size.width, size.height * 0.82);
    canvas.drawPath(wave, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WidgetStudioTab extends StatefulWidget {
  const WidgetStudioTab({super.key});
  @override
  State<WidgetStudioTab> createState() => _WidgetStudioTabState();
}

class _WidgetStudioTabState extends State<WidgetStudioTab> {
  int selectedThemeIdx = 0;
  int selectedVerseIdx = 0;
  String loc = 'Barpaka';
  Map<String, String> times = {
    'Fajr': '04:15',
    'Dhuhr': '11:58',
    'Asr': '15:10',
    'Maghrib': '16:38',
    'Isha': '18:15'
  };

  final List<Map<String, dynamic>> themes = const [
    {
      'name': 'Emerald Velvet',
      'c1': Color(0xFF0D352E),
      'c2': Color(0xFF061A17),
      'pill': Color(0xFF14493F),
      'accent': Color(0xFF2DD4BF),
      'gold': Color(0xFFEAB308)
    },
    {
      'name': 'Obsidian Gold',
      'c1': Color(0xFF1B2436),
      'c2': Color(0xFF090D16),
      'pill': Color(0xFF243048),
      'accent': Color(0xFFD4AF37),
      'gold': Color(0xFFD4AF37)
    },
    {
      'name': 'Royal Sapphira',
      'c1': Color(0xFF172554),
      'c2': Color(0xFF090D16),
      'pill': Color(0xFF1E3A8A),
      'accent': Color(0xFF38BDF8),
      'gold': Color(0xFFFBBF24)
    },
  ];

  final List<Map<String, String>> verses = const [
    {
      'surah': 'ASH-SHARH',
      'ayah': '94 : 5',
      'arab': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
      'hing': '"Beshak, har mushkil ke sath aasani hai."'
    },
    {
      'surah': 'AR-RA\'D',
      'ayah': '13 : 28',
      'arab': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      'hing': '"Sun lo! Allah ke zikr hi se dilon ko sukoon milta hai."'
    },
    {
      'surah': 'AL-BAQARAH',
      'ayah': '2 : 152',
      'arab': 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي',
      'hing': '"Tum mujhe yaad rakho, main tumhe yaad rakhunga."'
    },
    {
      'surah': 'AT-TALAQ',
      'ayah': '65 : 3',
      'arab': 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
      'hing': '"Aur jo Allah par bharosa rakhe, toh Allah uske liye kaafi hai."'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedWidgetConfig();
  }

  Future<void> _loadSavedWidgetConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedThemeIdx = prefs.getInt('wid_theme') ?? 0;
      selectedVerseIdx = prefs.getInt('wid_verse') ?? 0;
      loc = prefs.getString('loc') ?? 'Barpaka';
    });
    _pushWidgetsToAndroid();
  }

  Future<void> _pushWidgetsToAndroid() async {
    final prefs = await SharedPreferences.getInstance();
    final v = verses[selectedVerseIdx];
    await prefs.setInt('wid_theme', selectedThemeIdx);
    await prefs.setInt('wid_verse', selectedVerseIdx);
    await prefs.setString('wq_ref', '✨ SURAH ${v['surah']} • ${v['ayah']}');
    await prefs.setString('wq_arab', v['arab']!);
    await prefs.setString('wq_hing', v['hing']!);
    await prefs.setString('wp_loc', '🕌 ${loc.toUpperCase()}');
    await prefs.setString('wp_next_name', 'Dhuhr');
    await prefs.setString('wp_next', formatClock(times['Dhuhr']!));
  }

  @override
  Widget build(BuildContext context) {
    final th = themes[selectedThemeIdx];
    final v = verses[selectedVerseIdx];
    final Color accentCol = th['accent'] as Color;
    final Color goldCol = th['gold'] as Color;
    final Color pillCol = th['pill'] as Color;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✨ NOOR WIDGET ATELIER',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 0.8)),
                  Text('Editorial Dual-Pane Home Screen Widgets',
                      style: TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
              // Theme Switcher Pills
              Row(
                children: List.generate(themes.length, (i) {
                  bool sel = selectedThemeIdx == i;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedThemeIdx = i);
                      _pushWidgetsToAndroid();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: themes[i]['c1'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(color: sel ? const Color(0xFFD4AF37) : Colors.white24, width: sel ? 2.5 : 1),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🌟 WIDGET 1: "NOOR HORIZON" SPLIT-PANE PRAYER WIDGET 🌟
          const Text('🕌 1. Noor Horizon Prayer Widget (Dual-Pane Edition)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white70)),
          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 205,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [th['c1'] as Color, th['c2'] as Color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: accentCol.withOpacity(0.35), width: 1.4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle Topographic Celestial Lines in Background
                  Positioned.fill(child: CustomPaint(painter: WidgetTopoPainter(accentCol))),

                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        // LEFT PANE: Brand + Active Pill + Editorial Serif Time + Countdown Pill
                        Expanded(
                          flex: 55,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: pillCol,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.mosque_rounded, size: 12, color: accentCol),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(loc.toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: pillCol.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: goldCol.withOpacity(0.4)),
                                    ),
                                    child: Text('FAJR • ACTIVE',
                                        style: TextStyle(color: goldCol, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Text('NEXT PRAYER',
                                  style: TextStyle(color: Colors.white60, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
                              const SizedBox(height: 2),
                              const Text('Dhuhr',
                                  style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, height: 1.1)),
                              Text(
                                formatClock(times['Dhuhr']!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontFamily: 'serif',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              // Frosted Remaining Countdown Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: pillCol.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: accentCol.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(color: goldCol, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('REMAINING',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white70)),
                                      ],
                                    ),
                                    Text('-04:18:24',
                                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: accentCol)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Vertical Subtle Divider Line
                        Container(
                          width: 1,
                          height: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          color: Colors.white12,
                        ),

                        // RIGHT PANE: 3-Step Vertical Timeline with Highlighted Capsule
                        Expanded(
                          flex: 45,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _timelineRow(Icons.wb_twilight_rounded, 'Fajr', 'CURRENT', formatClock(times['Fajr']!), false, pillCol, accentCol),
                              _timelineRow(Icons.wb_sunny_outlined, 'Dhuhr', 'NEXT PRAYER', formatClock(times['Dhuhr']!), true, pillCol, accentCol),
                              _timelineRow(Icons.wb_cloudy_outlined, 'Asr', '', formatClock(times['Asr']!), false, pillCol, accentCol),
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
          const SizedBox(height: 24),

          // 🌟 WIDGET 2: "NOOR MANUSCRIPT" ARABIC + HINGLISH VERSE WIDGET 🌟
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📖 2. Noor Manuscript Verse Widget (Arabic + Hinglish)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white70)),
              GestureDetector(
                onTap: () {
                  setState(() => selectedVerseIdx = (selectedVerseIdx + 1) % verses.length);
                  _pushWidgetsToAndroid();
                },
                child: Text('↻ Next Ayah', style: TextStyle(color: goldCol, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [th['c1'] as Color, th['c2'] as Color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: accentCol.withOpacity(0.35), width: 1.4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: WidgetTopoPainter(accentCol))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(color: pillCol, shape: BoxShape.circle),
                                child: Icon(Icons.auto_stories_rounded, size: 12, color: accentCol),
                              ),
                              const SizedBox(width: 6),
                              const Text('NOOR AYAH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: pillCol.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: goldCol.withOpacity(0.4)),
                            ),
                            child: Text('SURAH ${v['surah']} • ${v['ayah']}',
                                style: TextStyle(color: goldCol, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        v['arab']!,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: pillCol.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: accentCol.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 3, height: 24, decoration: BoxDecoration(color: goldCol, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                v['hing']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'serif',
                                  fontStyle: FontStyle.italic,
                                  color: accentCol,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () async {
              await _pushWidgetsToAndroid();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Masterpiece Widgets Synced! Add from Phone Home Screen -> Widgets!')),
                );
              }
            },
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.black),
            label: const Text('Apply & Sync Both Widgets to Home Screen',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(IconData ic, String name, String sub, String time, bool highlight, Color pillCol, Color accentCol) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: highlight ? 10 : 4, vertical: highlight ? 10 : 4),
      decoration: highlight
          ? BoxDecoration(
              color: pillCol.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentCol.withOpacity(0.35)),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(ic, size: 15, color: highlight ? accentCol : Colors.white70),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        style: TextStyle(
                            fontSize: 7.5, fontWeight: FontWeight.w900, color: highlight ? accentCol : Colors.white54, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 10.5,
              fontFamily: 'serif',
              fontWeight: FontWeight.bold,
              color: highlight ? accentCol : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 3. IMAN SCORE TRACKER & QAZA BANK ----------------
class TrackerTab extends StatefulWidget {
  const TrackerTab({super.key});
  @override
  State<TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<TrackerTab> {
  SharedPreferences? prefs;
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
    int qazaTotal = prayers.fold(0, (a, p) => a + (prefs?.getInt('qb_$p') ?? 0));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👑 MONTHLY IMAN CONSISTENCY', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('$mAda Offered • $mJamaat in Jamaat', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏦 Qaza-e-Umri Bank (Pending: $qazaTotal)', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    for (var p in prayers) {
                      await prefs?.setInt('qb_$p', (prefs?.getInt('qb_$p') ?? 0) + 30);
                    }
                    setState(() {});
                  },
                  child: const Text('+ Add 1 Month Missed Qaza'),
                ),
                ...prayers.map((p) {
                  int val = prefs?.getInt('qb_$p') ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$p Qaza: $val'),
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

// ---------------- 4. QURAN & HADITH WITH INSTANT SEARCH BAR ----------------
class QuranHadithTab extends StatefulWidget {
  final int initialSec;
  const QuranHadithTab({super.key, this.initialSec = 0});
  @override
  State<QuranHadithTab> createState() => _QuranHadithTabState();
}

class _QuranHadithTabState extends State<QuranHadithTab> {
  late int sec;
  List surahs = [], hadiths = [];
  bool loadingQuran = true;
  String book = 'bukhari';
  int chap = 1;
  String quranSearch = '', hadithSearch = '';

  final List<Map<String, String>> instantHadiths = const [
    {'hadithnumber': '1', 'arab': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ', 'text': 'Sahih Bukhari #1: Actions are judged only by intentions.'},
    {'hadithnumber': '5027', 'arab': 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ', 'text': 'Sahih Bukhari #5027: The best among you are those who learn the Qur\'an and teach it.'},
    {'hadithnumber': '223', 'arab': 'الطُّهُورُ شَطْرُ الإِيمَانِ', 'text': 'Sahih Muslim #223: Cleanliness is half of faith (Iman).'},
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
    try {
      String lang = appLang == 'ur' ? 'urd' : 'eng';
      final r = await http.get(Uri.parse('https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$lang-$book/sections/$chap.json'));
      if (r.statusCode == 200 && mounted) {
        List fetched = json.decode(r.body)['hadiths'] ?? [];
        if (fetched.isNotEmpty) setState(() => hadiths = fetched);
      }
    } catch (_) {}
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
                            hintText: '🔍 Search Surah name or number...',
                            filled: true,
                            fillColor: const Color(0xFF111927),
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
                        TextField(
                          onChanged: (v) => setState(() => hadithSearch = v),
                          decoration: InputDecoration(
                            hintText: '🔍 Search Hadith topic, word or number...',
                            filled: true,
                            fillColor: const Color(0xFF111927),
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
                                decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(14)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text('📜 Hadith #${h['hadithnumber']}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(h['text'].toString(), style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
      appBar: AppBar(title: Text(widget.name), backgroundColor: const Color(0xFF111927)),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: ar.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(14)),
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
    );
  }
}

// ---------------- 5. REDESIGNED 3D ROYAL ASTROLABE & KAABA QIBLA ----------------
class RoyalAstrolabePainter extends CustomPainter {
  final bool isLocked;
  RoyalAstrolabePainter({required this.isLocked});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final starPaint = Paint()
      ..color = (isLocked ? const Color(0xFF10B981) : const Color(0xFFD4AF37)).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    double sqSize = radius * 1.15;
    canvas.drawRect(Rect.fromCenter(center: center, width: sqSize, height: sqSize), starPaint);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: sqSize, height: sqSize), starPaint);
    canvas.restore();

    final tickPaint = Paint()..style = PaintingStyle.stroke;
    for (int deg = 0; deg < 360; deg += 5) {
      bool isMajor = deg % 30 == 0;
      tickPaint.color = isMajor ? const Color(0xFFD4AF37) : Colors.white24;
      tickPaint.strokeWidth = isMajor ? 2.5 : 1.0;
      double len = isMajor ? 14.0 : 6.0;
      double rad = deg * math.pi / 180.0;
      Offset p1 = Offset(center.dx + (radius - 6) * math.cos(rad), center.dy + (radius - 6) * math.sin(rad));
      Offset p2 = Offset(center.dx + (radius - 6 - len) * math.cos(rad), center.dy + (radius - 6 - len) * math.sin(rad));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Kaaba3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cubeRect = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.7, h * 0.75), const Radius.circular(6));
    canvas.drawRRect(cubeRect, Paint()..color = const Color(0xFF09090B));
    canvas.drawRRect(cubeRect, Paint()..color = const Color(0xFFD4AF37)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawRect(Rect.fromLTWH(w * 0.16, h * 0.32, w * 0.68, h * 0.12), Paint()..color = const Color(0xFFD4AF37));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.52, h * 0.52, w * 0.16, h * 0.28), const Radius.circular(2)), Paint()..color = const Color(0xFFD4AF37));
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
  double heading = 0.0, qiblaAngle = 277.2;
  StreamSubscription? _magSub;
  StreamSubscription? _accSub;
  double _ax = 0, _ay = 0, _az = 9.8;

  @override
  void initState() {
    super.initState();
    _startRealSensors();
  }

  @override
  void dispose() {
    _magSub?.cancel();
    _accSub?.cancel();
    super.dispose();
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
        double pitch = math.asin(-ax), roll = math.atan2(ay, az);
        double mx = e.x * math.cos(pitch) + e.z * math.sin(pitch);
        double my = e.x * math.sin(roll) * math.sin(pitch) + e.y * math.cos(roll) - e.z * math.sin(roll) * math.cos(pitch);
        double deg = (math.atan2(-my, mx) * 180.0 / math.pi + 360.0) % 360.0;
        double diff = deg - heading;
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;
        if (mounted) setState(() => heading = (heading + diff * 0.18 + 360.0) % 360.0);
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    double diff = (qiblaAngle - heading + 360.0) % 360.0;
    bool aligned = diff < 8.0 || diff > 352.0;
    String turnText = aligned ? '🕋 LOCKED ON HOLY KAABA' : (diff <= 180 ? 'Turn Right ↻ ${diff.toStringAsFixed(0)}°' : 'Turn Left ↺ ${(360 - diff).toStringAsFixed(0)}°');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 95),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ROYAL ASTROLABE QIBLA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 1.5)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: aligned ? const Color(0xFF10B981) : const Color(0xFF111927),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Text(turnText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF111927),
                    border: Border.all(color: aligned ? const Color(0xFF10B981) : const Color(0xFFD4AF37), width: 3.5),
                  ),
                ),
                Transform.rotate(
                  angle: -heading * (math.pi / 180.0),
                  child: SizedBox(
                    width: 265,
                    height: 265,
                    child: CustomPaint(painter: RoyalAstrolabePainter(isLocked: aligned)),
                  ),
                ),
                Transform.rotate(
                  angle: (qiblaAngle - heading) * (math.pi / 180.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation_rounded, size: 30, color: aligned ? const Color(0xFF10B981) : const Color(0xFFD4AF37)),
                      SizedBox(width: 42, height: 42, child: CustomPaint(painter: Kaaba3DPainter())),
                      Container(width: 4, height: 65, color: const Color(0xFFD4AF37)),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ],
            ),
            Text('Heading: ${heading.toStringAsFixed(0)}° • Kaaba: ${qiblaAngle.toStringAsFixed(1)}°', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ---------------- 6. AI MUFTI CHATBOT & ZAKAT HUB ----------------
class AiMuftiHubTab extends StatefulWidget {
  const AiMuftiHubTab({super.key});
  @override
  State<AiMuftiHubTab> createState() => _AiMuftiHubTabState();
}

class _AiMuftiHubTabState extends State<AiMuftiHubTab> {
  final TextEditingController msgCtrl = TextEditingController();
  final List<Map<String, String>> chatMessages = [
    {'sender': 'bot', 'text': 'Assalamu Alaikum! 🕌 Ask me any question on Namaz, Wudu, Qaza, Zakat or Duas!'}
  ];

  Future<void> _askAi(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => chatMessages.add({'sender': 'user', 'text': q}));
    msgCtrl.clear();
    String reply = '📖 Har Farz ibadat mein Niyat shart hai (Sahih Bukhari #1).';
    try {
      final res = await http.get(Uri.parse('https://text.pollinations.ai/${Uri.encodeComponent("Answer as Sunni Islamic scholar: $q")}')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty) reply = res.body.trim();
    } catch (_) {}
    if (mounted) setState(() => chatMessages.add({'sender': 'bot', 'text': reply}));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 85),
        child: Column(
          children: [
            const Text('🤖 Ask AI Mufti Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: chatMessages.length,
                itemBuilder: (_, i) {
                  final m = chatMessages[i];
                  bool isUser = m['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: isUser ? const Color(0xFF0F3D3E) : const Color(0xFF111927), borderRadius: BorderRadius.circular(16)),
                      child: Text(m['text']!),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(child: TextField(controller: msgCtrl, onSubmitted: _askAi, decoration: const InputDecoration(hintText: 'Ask any Islamic question...'))),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFFD4AF37)), onPressed: () => _askAi(msgCtrl.text)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
