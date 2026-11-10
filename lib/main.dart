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

String getDateKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

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
  int quranSub = 0;

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

  void _go(int i, {int sub = 0}) => setState(() { idx = i; quranSub = sub; });

  @override
  Widget build(BuildContext context) {
    final pages = [
      CelestialHomeTab(onNav: _go, onUpdate: () => setState(() {})),
      const WidgetStudioTab(),
      const TrackerTab(),
      QuranHadithTab(initSec: quranSub),
      const QiblaTab(),
      const AiMuftiTab(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[idx],
      bottomNavigationBar: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1724),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _btn(0, Icons.auto_awesome_mosaic_rounded, 'Orbit'),
            _btn(1, Icons.widgets_rounded, 'Widgets'),
            _btn(2, Icons.donut_large_rounded, 'Iman'),
            _btn(3, Icons.menu_book_rounded, 'Kitab'),
            _btn(4, Icons.explore_rounded, 'Qibla'),
            _btn(5, Icons.psychology_alt_rounded, 'Mufti'),
          ],
        ),
      ),
    );
  }

  Widget _btn(int i, IconData ic, String lb) {
    bool sel = idx == i;
    return GestureDetector(
      onTap: () => setState(() => idx = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: sel ? 12 : 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFF59E0B)]) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(ic, color: sel ? Colors.black : Colors.white60, size: 20),
            if (sel) ...[const SizedBox(width: 4), Text(lb, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11))],
          ],
        ),
      ),
    );
  }
}

// ---------------- 1. CELESTIAL HOME TAB ----------------
class CelestialHomeTab extends StatefulWidget {
  final Function(int, {int sub}) onNav;
  final VoidCallback onUpdate;
  const CelestialHomeTab({super.key, required this.onNav, required this.onUpdate});
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
  double orbitProg = 0.35;

  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, String> times = {'Fajr': '04:15', 'Dhuhr': '12:30', 'Asr': '14:59', 'Maghrib': '16:32', 'Isha': '18:24'};
  Map<String, int> status = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};
  final quickPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    quickPlayer.onPlayerComplete.listen((_) => mounted ? setState(() => isPlaying = false) : null);
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
    for (var p in prayers) {
      final parts = times[p]!.split(':');
      final dt = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      if (dt.isAfter(now)) { nextT = dt; found = p; break; }
    }
    if (nextT == null) {
      final parts = times['Fajr']!.split(':');
      nextT = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1])).add(const Duration(days: 1));
    }
    final d = nextT.difference(now);
    if (mounted) {
      setState(() {
        nextP = found;
        countdown = '${d.inHours.toString().padLeft(2, '0')}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m ${(d.inSeconds % 60).toString().padLeft(2, '0')}s';
        orbitProg = ((now.hour * 60 + now.minute) / 1440.0).clamp(0.08, 0.95);
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
      manualMode = p.getBool('manual') ?? false;
      for (var pr in prayers) {
        status[pr] = p.getInt('st_${tKey}_$pr') ?? 0;
        if (manualMode) times[pr] = p.getString('mt_$pr') ?? times[pr]!;
      }
    });
    if (!manualMode) _fetchAPI();
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
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    int done = status.values.where((s) => s > 0 && s < 4).length;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌙 $hijri', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(loc, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  ActionChip(
                    label: Text(use12Hour ? '12H' : '24H', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
                    backgroundColor: const Color(0xFF151F30),
                    onPressed: () async {
                      final p = await SharedPreferences.getInstance();
                      await p.setBool('use12', !use12Hour);
                      setState(() => use12Hour = !use12Hour);
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: Text(school == 0 ? 'SHAFI' : 'HANAFI', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                    backgroundColor: const Color(0xFF151F30),
                    onPressed: () async {
                      final p = await SharedPreferences.getInstance();
                      await p.setInt('school', school == 0 ? 1 : 0);
                      _load();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Celestial Solar Orbit Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A2942), Color(0xFF0D1422)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text('UPCOMING: ${nextP.toUpperCase()} • ${formatClock(times[nextP]!)}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Text(countdown, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('🌙 Suhur: ${formatClock(times['Fajr']!)}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    Text('🌅 Sunrise: ${formatClock(sunrise)}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    Text('🌇 Iftar: ${formatClock(times['Maghrib']!)}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2-in-1 Salah Strip (Tap to Log, Hold to Edit Time)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('⚡ Interactive Salah Strip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('$done/5 Ada • Hold to Edit', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: prayers.map((pr) {
              bool isN = pr == nextP;
              int st = status[pr] ?? 0;
              final cols = [Colors.white24, const Color(0xFF10B981), const Color(0xFF38BDF8), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
              final tags = ['Tap', 'Jamaat', 'OnTime', 'Qaza', 'Missed'];
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    int next = ((status[pr] ?? 0) + 1) % 5;
                    final p = await SharedPreferences.getInstance();
                    await p.setInt('st_${getDateKey(DateTime.now())}_$pr', next);
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
                      setState(() { times[pr] = t24; manualMode = true; });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isN ? const Color(0xFF1E3246) : const Color(0xFF111927),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: st > 0 ? cols[st] : (isN ? const Color(0xFFD4AF37) : Colors.white12), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(pr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isN ? const Color(0xFFD4AF37) : Colors.white)),
                        const SizedBox(height: 2),
                        Text(formatClock(times[pr]!).split(' ')[0], style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(tags[st], style: TextStyle(fontSize: 8, color: cols[st], fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Smart Bento Grid
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () => widget.onNav(3, sub: 0),
                  child: Container(
                    height: 95,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0F3D3E), Color(0xFF111927)]),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('📖 Al-Quran (114)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            GestureDetector(
                              onTap: () async {
                                if (isPlaying) { await quickPlayer.stop(); setState(() => isPlaying = false); }
                                else { setState(() => isPlaying = true); await quickPlayer.play(UrlSource('https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3')); }
                              },
                              child: CircleAvatar(radius: 13, backgroundColor: const Color(0xFFD4AF37), child: Icon(isPlaying ? Icons.stop : Icons.play_arrow, size: 16, color: Colors.black)),
                            ),
                          ],
                        ),
                        const Text('Tilawat & Translation', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => widget.onNav(1),
                  child: Container(
                    height: 95,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4))),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.widgets_rounded, color: Color(0xFFD4AF37), size: 24),
                        SizedBox(height: 4),
                        Text('VIP Widgets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _tile('🕋 Royal Qibla', '3D Sensor', const Color(0xFFD4AF37), () => widget.onNav(4)),
              const SizedBox(width: 8),
              _tile('📜 Hadiths', 'Cloud API', const Color(0xFF38BDF8), () => widget.onNav(3, sub: 1)),
              const SizedBox(width: 8),
              _tile('🤖 AI Mufti', 'Chatbot', const Color(0xFF10B981), () => widget.onNav(5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(String t, String s, Color c, VoidCallback tap) {
    return Expanded(
      child: GestureDetector(
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withOpacity(0.3))),
          child: Column(children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)), Text(s, style: TextStyle(fontSize: 9.5, color: c))]),
        ),
      ),
    );
  }
}

// ---------------- 2. VIP DUAL-PANE WIDGET STUDIO ----------------
class WidgetStudioTab extends StatefulWidget {
  const WidgetStudioTab({super.key});
  @override
  State<WidgetStudioTab> createState() => _WidgetStudioTabState();
}

class _WidgetStudioTabState extends State<WidgetStudioTab> {
  int verseIdx = 0;
  final verses = const [
    {'ref': 'ASH-SHARH • 94:5', 'ar': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا', 'hi': '"Beshak, har mushkil ke sath aasani hai."'},
    {'ref': 'AR-RA\'D • 13:28', 'ar': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', 'hi': '"Sun lo! Allah ke zikr hi se dilon ko sukoon milta hai."'},
    {'ref': 'AL-BAQARAH • 2:152', 'ar': 'فَاذْكُرُونِي أَذْكُرْكُمْ', 'hi': '"Tum mujhe yaad rakho, main tumhe yaad rakhunga."'},
  ];

  @override
  Widget build(BuildContext context) {
    final v = verses[verseIdx];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          const Text('✨ VIP Split-Pane Home Widgets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
          const SizedBox(height: 14),

          // Widget 1: Dual-Pane Prayer Strip (Inspired & Unique!)
          const Text('🕌 1. Noor Horizon Dual-Pane Prayer Widget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D352E), Color(0xFF061A17)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)), child: const Text('FAJR • ACTIVE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      const Text('UPCOMING', style: TextStyle(fontSize: 9, color: Colors.white54)),
                      const Text('Dhuhr', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('12:30 PM', style: TextStyle(fontSize: 22, fontFamily: 'serif', color: Color(0xFFD4AF37))),
                      const SizedBox(height: 8),
                      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF14493F), borderRadius: BorderRadius.circular(14)), child: const Text('● NEXT IN -04:18:00', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                Container(width: 1, height: 110, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 10)),
                const Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Text('🌅 Fajr      04:15 AM', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
                      SizedBox(height: 8),
                      Text('☀️ Dhuhr   12:30 PM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2DD4BF))),
                      SizedBox(height: 8),
                      Text('⛅ Asr       02:59 PM', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Widget 2: Dual-Pane Verse Widget
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📖 2. Noor Manuscript Verse Widget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              TextButton(onPressed: () => setState(() => verseIdx = (verseIdx + 1) % verses.length), child: const Text('↻ Next Verse')),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF141E30), Color(0xFF070B12)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text(v['ref']!, style: const TextStyle(fontSize: 9.5, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(v['ar']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text(v['hi']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 3. TRACKER TAB ----------------
class TrackerTab extends StatefulWidget {
  const TrackerTab({super.key});
  @override
  State<TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<TrackerTab> {
  SharedPreferences? prefs;
  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) => setState(() => prefs = p));
  }
  @override
  Widget build(BuildContext context) {
    int qTotal = prayers.fold(0, (a, p) => a + (prefs?.getInt('qb_$p') ?? 0));
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const Text('📊 Consistency & Qaza Bank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF111927), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏦 Qaza-e-Umri Total: $qTotal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    for (var p in prayers) { await prefs?.setInt('qb_$p', (prefs?.getInt('qb_$p') ?? 0) + 30); }
                    setState(() {});
                  },
                  child: const Text('+ Add 1 Month (30 Days) Qaza'),
                ),
                ...prayers.map((p) {
                  int v = prefs?.getInt('qb_$p') ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$p: $v'),
                      TextButton(onPressed: () async { await prefs?.setInt('qb_$p', math.max(0, v - 1)); setState(() {}); }, child: const Text('-1 Paid ✅')),
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

// ---------------- 4. QURAN & HADITH TAB ----------------
class QuranHadithTab extends StatefulWidget {
  final int initSec;
  const QuranHadithTab({super.key, this.initSec = 0});
  @override
  State<QuranHadithTab> createState() => _QuranHadithTabState();
}

class _QuranHadithTabState extends State<QuranHadithTab> {
  late int sec;
  List surahs = [], hadiths = [];
  bool loading = true;
  String qSearch = '', hSearch = '';
  final instHadiths = const [
    {'hadithnumber': '1', 'text': 'Sahih Bukhari #1: Actions are judged only by intentions.'},
    {'hadithnumber': '5027', 'text': 'Sahih Bukhari #5027: The best among you are those who learn the Qur\'an and teach it.'},
    {'hadithnumber': '223', 'text': 'Sahih Muslim #223: Cleanliness is half of faith.'},
  ];

  @override
  void initState() {
    super.initState();
    sec = widget.initSec;
    hadiths = instHadiths;
    http.get(Uri.parse('https://api.alquran.cloud/v1/surah')).then((r) {
      if (r.statusCode == 200 && mounted) setState(() { surahs = json.decode(r.body)['data']; loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final fS = surahs.where((s) => s['englishName'].toString().toLowerCase().contains(qSearch.toLowerCase())).toList();
    final fH = hadiths.where((h) => h['text'].toString().toLowerCase().contains(hSearch.toLowerCase())).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 85),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: sec == 0 ? const Color(0xFFD4AF37) : const Color(0xFF111927)), onPressed: () => setState(() => sec = 0), child: Text('📖 Quran (114)', style: TextStyle(color: sec == 0 ? Colors.black : Colors.white)))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: sec == 1 ? const Color(0xFFD4AF37) : const Color(0xFF111927)), onPressed: () => setState(() => sec = 1), child: Text('📜 Hadiths', style: TextStyle(color: sec == 1 ? Colors.black : Colors.white)))),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: sec == 0
                  ? Column(
                      children: [
                        TextField(onChanged: (v) => setState(() => qSearch = v), decoration: const InputDecoration(hintText: '🔍 Search Surah (e.g. Yaseen)...')),
                        Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: fS.length, itemBuilder: (_, i) => ListTile(title: Text(fS[i]['englishName']), trailing: Text(fS[i]['name'], style: const TextStyle(color: Color(0xFFD4AF37)))))),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(onChanged: (v) => setState(() => hSearch = v), decoration: const InputDecoration(hintText: '🔍 Search Hadith keyword...')),
                        Expanded(child: ListView.builder(itemCount: fH.length, itemBuilder: (_, i) => ListTile(title: Text(fH[i]['text'])))),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 5. 3D ROYAL ASTROLABE QIBLA ----------------
class QiblaTab extends StatefulWidget {
  const QiblaTab({super.key});
  @override
  State<QiblaTab> createState() => _QiblaTabState();
}

class _QiblaTabState extends State<QiblaTab> {
  double heading = 0.0, qiblaAngle = 277.2;
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
    double diff = (qiblaAngle - heading + 360.0) % 360.0;
    bool aligned = diff < 8.0 || diff > 352.0;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ROYAL ASTROLABE QIBLA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            const SizedBox(height: 12),
            Text(aligned ? '🕋 LOCKED ON HOLY KAABA' : 'Turn phone towards Kaaba', style: TextStyle(color: aligned ? const Color(0xFF10B981) : Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Transform.rotate(
              angle: (qiblaAngle - heading) * (math.pi / 180.0),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF111927), border: Border.all(color: aligned ? const Color(0xFF10B981) : const Color(0xFFD4AF37), width: 3.5)),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('🕋', style: TextStyle(fontSize: 40)), Icon(Icons.navigation_rounded, size: 40, color: Color(0xFFD4AF37))]),
              ),
            ),
            const SizedBox(height: 25),
            Text('Heading: ${heading.toStringAsFixed(0)}° • Kaaba: ${qiblaAngle.toStringAsFixed(1)}°', style: const TextStyle(color: Color(0xFFD4AF37))),
          ],
        ),
      ),
    );
  }
}

// ---------------- 6. AI MUFTI & HUB ----------------
class AiMuftiTab extends StatefulWidget {
  const AiMuftiTab({super.key});
  @override
  State<AiMuftiTab> createState() => _AiMuftiTabState();
}

class _AiMuftiTabState extends State<AiMuftiTab> {
  final ctrl = TextEditingController();
  final msgs = [{'sender': 'bot', 'text': 'Assalamu Alaikum! 🕌 Ask me any question on Namaz, Wudu, Qaza, or Zakat!'}];

  void _ask(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => msgs.add({'sender': 'user', 'text': q}));
    ctrl.clear();
    String rep = '📖 Har Farz ibadat mein Niyat shart hai (Sahih Bukhari #1).';
    try {
      final r = await http.get(Uri.parse('https://text.pollinations.ai/${Uri.encodeComponent("Answer as Sunni Islamic scholar: $q")}')).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200 && r.body.isNotEmpty) rep = r.body;
    } catch (_) {}
    if (mounted) setState(() => msgs.add({'sender': 'bot', 'text': rep}));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 85),
        child: Column(
          children: [
            const Text('🤖 Ask AI Mufti Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: msgs.length,
                itemBuilder: (_, i) => Align(
                  alignment: msgs[i]['sender'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: msgs[i]['sender'] == 'user' ? const Color(0xFF0F3D3E) : const Color(0xFF111927), borderRadius: BorderRadius.circular(14)),
                    child: Text(msgs[i]['text']!),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: TextField(controller: ctrl, onSubmitted: _ask, decoration: const InputDecoration(hintText: 'Ask any question...'))),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFFD4AF37)), onPressed: () => _ask(ctrl.text)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
