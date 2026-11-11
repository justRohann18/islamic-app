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
  runApp(const NoorSuperApp());
}

const MethodChannel _widgetChannel = MethodChannel('com.noor/widgets');

bool isDarkMode = true;
int accentIndex = 0;
String appLang = 'en';
bool use12Hour = true;

final List<Map<String, dynamic>> kAccentPalettes = [
  {'name': 'Amber Gold', 'primary': const Color(0xFFF59E0B), 'sec': const Color(0xFF2DD4BF)},
  {'name': 'Emerald Mint', 'primary': const Color(0xFF10B981), 'sec': const Color(0xFFFBBF24)},
  {'name': 'Royal Sapphire', 'primary': const Color(0xFF38BDF8), 'sec': const Color(0xFF818CF8)},
  {'name': 'Amethyst Velvet', 'primary': const Color(0xFFA855F7), 'sec': const Color(0xFFF472B6)},
  {'name': 'Rose Ruby', 'primary': const Color(0xFFF43F5E), 'sec': const Color(0xFFFBBF24)},
  {'name': 'Cyan Ocean', 'primary': const Color(0xFF06B6D4), 'sec': const Color(0xFF34D399)},
];

Color get kPrimary => kAccentPalettes[accentIndex]['primary'] as Color;
Color get kSecondary => kAccentPalettes[accentIndex]['sec'] as Color;
Color get kBg => isDarkMode ? const Color(0xFF080C0B) : const Color(0xFFF4F6F5);
Color get kCard => isDarkMode ? const Color(0xFF111917) : const Color(0xFFFFFFFF);
Color get kCardAlt => isDarkMode ? const Color(0xFF192622) : const Color(0xFFE6F0EC);
Color get kBorder => isDarkMode ? const Color(0xFF243832) : const Color(0xFFD0DFD9);
Color get kText => isDarkMode ? Colors.white : const Color(0xFF0F172A);
Color get kMuted => isDarkMode ? const Color(0xFF8E9E99) : const Color(0xFF64748B);

String liveAyahRef = 'Surah Ash-Sharh • 94:5';
String liveAyahArab = 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا';
String liveAyahTrans = '"Indeed, with hardship comes ease."';
String liveAyahAudio = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6095.mp3';

String liveDuaRef = 'Quranic Rabbanah Dua • 2:201';
String liveDuaArab = 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ';
String liveDuaTrans = '"Our Lord! Grant us good in this world and good in the Hereafter, and protect us from the Fire."';

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

String tr(String en, String hi, String ur, String ro) {
  if (appLang == 'hi') return hi;
  if (appLang == 'ur') return ur;
  if (appLang == 'ro') return ro;
  return en;
}

Future<void> triggerNativeWidgetBroadcast() async {
  try {
    await _widgetChannel.invokeMethod('refreshWidgets');
  } catch (_) {}
}

Future<void> fetchLiveDailyAyahAndDua({bool forceRandom = false}) async {
  try {
    final now = DateTime.now();
    int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    int ayahNum = forceRandom ? (math.Random().nextInt(6200) + 10) : ((dayOfYear * 37 + now.year) % 6220) + 7;
    String ed = appLang == 'hi' ? 'hi.hindi' : (appLang == 'ur' ? 'ur.jalandhry' : 'en.asad');

    final r = await http.get(Uri.parse('https://api.alquran.cloud/v1/ayah/$ayahNum/editions/ar.alafasy,$ed'));
    if (r.statusCode == 200) {
      final d = json.decode(r.body)['data'];
      liveAyahArab = d[0]['text'];
      liveAyahAudio = d[0]['audio'] ?? liveAyahAudio;
      liveAyahTrans = '"${d[1]['text']}"';
      liveAyahRef = '${d[0]['surah']['englishName']} • ${d[0]['surah']['number']}:${d[0]['numberInSurah']}';
    }

    const duaAyahNumbers = [208, 293, 301, 1750, 2373, 2935, 3189, 4153, 5150];
    int duaAyah = duaAyahNumbers[(forceRandom ? math.Random().nextInt(9) : dayOfYear) % duaAyahNumbers.length];
    final dr = await http.get(Uri.parse('https://api.alquran.cloud/v1/ayah/$duaAyah/editions/ar.alafasy,$ed'));
    if (dr.statusCode == 200) {
      final dd = json.decode(dr.body)['data'];
      liveDuaArab = dd[0]['text'];
      liveDuaTrans = '"${dd[1]['text']}"';
      liveDuaRef = 'Daily Dua • ${dd[0]['surah']['englishName']} ${dd[0]['surah']['number']}:${dd[0]['numberInSurah']}';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wq_ref', '✨ $liveAyahRef');
    await prefs.setString('wq_arab', liveAyahArab);
    await prefs.setString('wq_hing', liveAyahTrans);
    await triggerNativeWidgetBroadcast();
  } catch (_) {}
}

class NoorSuperApp extends StatefulWidget {
  const NoorSuperApp({super.key});
  @override
  State<NoorSuperApp> createState() => _NoorSuperAppState();
}

class _NoorSuperAppState extends State<NoorSuperApp> {
  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = p.getBool('dark') ?? true;
      accentIndex = p.getInt('accent') ?? 0;
      appLang = p.getString('lang') ?? 'en';
      use12Hour = p.getBool('use12') ?? true;
    });
    await fetchLiveDailyAyahAndDua();
    if (mounted) setState(() {});
  }

  void _rebuildApp() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOOR',
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: kBg,
        primaryColor: kPrimary,
        cardColor: kCard,
      ),
      home: MainShell(onAppRebuild: _rebuildApp),
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onAppRebuild;
  const MainShell({super.key, required this.onAppRebuild});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int idx = 0;
  int kitSub = 0;

  void _nav(int i, {int sub = 0}) => setState(() { idx = i; kitSub = sub; });

  @override
  Widget build(BuildContext context) {
    final pages = [
      InteractiveHomeScreen(onNav: _nav, onRebuild: widget.onAppRebuild),
      UniqueWidgetStudioScreen(onRebuild: widget.onAppRebuild),
      const UniqueStreakScreen(),
      KitabScreen(initTab: kitSub),
      SettingsProfileScreen(onRebuild: widget.onAppRebuild),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[idx],
      bottomNavigationBar: Container(
        height: 66,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: kCard.withOpacity(0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kBorder, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navPill(0, Icons.wb_twilight_rounded, tr('Today', 'आज', 'آج', 'Today')),
            _navPill(1, Icons.widgets_rounded, tr('Widgets', 'विजेट', 'ویجٹ', 'Widgets')),
            _navPill(2, Icons.local_fire_department_rounded, tr('Streak', 'स्ट्रीक', 'اسٹریک', 'Streak')),
            _navPill(3, Icons.menu_book_rounded, tr('Kitab', 'किताब', 'کتاب', 'Kitab')),
            _navPill(4, Icons.settings_rounded, tr('Settings', 'सेटिंग्स', 'ترتیبات', 'Settings')),
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
        padding: EdgeInsets.symmetric(horizontal: sel ? 13 : 9, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(ic, size: 19, color: sel ? Colors.black : kMuted),
            if (sel) ...[
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.w900)),
            ],
          ],
        ),
      ),
    );
  }
}

class MihrabArchPainter extends CustomPainter {
  final Color col;
  MihrabArchPainter(this.col);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = col.withOpacity(0.18)..style = PaintingStyle.stroke..strokeWidth = 1.6;
    final arch = Path()
      ..moveTo(size.width * 0.12, size.height)
      ..lineTo(size.width * 0.12, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.12, size.height * 0.08, size.width * 0.5, size.height * 0.02)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.08, size.width * 0.88, size.height * 0.45)
      ..lineTo(size.width * 0.88, size.height);
    canvas.drawPath(arch, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}















// ---------------- 1. ENGAGING DAILY HABIT HOMEPAGE ----------------
class InteractiveHomeScreen extends StatefulWidget {
  final Function(int, {int sub}) onNav;
  final VoidCallback onRebuild;
  const InteractiveHomeScreen({super.key, required this.onNav, required this.onRebuild});
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

  int tasbihCount = 0;
  int zikrIdx = 0;
  final List<Map<String, String>> azkar = const [
    {'ar': 'سُبْحَانَ اللَّهِ', 'en': 'SubhanAllah'},
    {'ar': 'الْحَمْدُ لِلَّهِ', 'en': 'Alhamdulillah'},
    {'ar': 'اللَّهُ أَكْبَرُ', 'en': 'Allahu Akbar'},
    {'ar': 'أَسْتَغْفِرُ اللَّهَ', 'en': 'Astaghfirullah'},
  ];

  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlayingAyah = false;

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    audioPlayer.onPlayerComplete.listen((_) => mounted ? setState(() => isPlayingAyah = false) : null);
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
        'Fajr ${formatClock(times['Fajr']!).split(' ')[0]}  •  Dhuhr ${formatClock(times['Dhuhr']!).split(' ')[0]}  •  Asr ${formatClock(times['Asr']!).split(' ')[0]}  •  Mag ${formatClock(times['Maghrib']!).split(' ')[0]}  •  Isha ${formatClock(times['Isha']!).split(' ')[0]}');
    await triggerNativeWidgetBroadcast();
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
        title: Text('Set City / Village', style: TextStyle(color: kPrimary)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'e.g. Barpaka, Rupahi, Delhi')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              String pl = ctrl.text.trim();
              Navigator.pop(ctx);
              if (pl.isNotEmpty) {
                final p = await SharedPreferences.getInstance();
                await p.setString('loc', pl);
                try {
                  final r = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?q=$pl&format=json&limit=1'), headers: {'User-Agent': 'NoorSuper/1.0'});
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

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _editLoc,
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.place_rounded, size: 16, color: Colors.black)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Text(loc, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)), Icon(Icons.arrow_drop_down, size: 18, color: kPrimary)]),
                        Text('🌙 $hijri', style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600)),
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

          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kPrimary.withOpacity(0.22), kCardAlt, kCard], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kPrimary.withOpacity(0.5), width: 1.5),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: MihrabArchPainter(kPrimary))),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20), border: Border.all(color: kPrimary.withOpacity(0.5))),
                          child: Text('UPCOMING SALAH • ${nextP.toUpperCase()}', style: TextStyle(color: kPrimary, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        ),
                        const SizedBox(height: 12),
                        Text(formatClock(times[nextP]!), style: TextStyle(fontSize: 42, fontFamily: 'serif', fontWeight: FontWeight.w900, color: kText, height: 1.05)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_outlined, size: 15, color: kSecondary),
                            const SizedBox(width: 5),
                            Text('Starts in $countdown', style: TextStyle(color: kSecondary, fontSize: 13.5, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: kBg.withOpacity(0.55), borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _archStat('🌙 SUHUR', formatClock(times['Fajr']!)),
                              Container(width: 1, height: 24, color: kBorder),
                              _archStat('🌅 SUNRISE', formatClock(sunrise)),
                              Container(width: 1, height: 24, color: kBorder),
                              _archStat('🌇 IFTAR', formatClock(times['Maghrib']!)),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('🕌 Daily Salah Check-In', '🕌 आज की नमाज़ चेक-इन', '🕌 آج کی نماز چیک ان', '🕌 Daily Salah Check-In'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
              Text('$salahDone/5 Offered • Hold Time to Edit', style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: prayers.map((pr) {
              bool isN = pr == nextP;
              int st = status[pr] ?? 0;
              final stCols = [kMuted, kSecondary, const Color(0xFF38BDF8), kPrimary, const Color(0xFFEF4444)];
              final stTags = ['Tap +', 'Jamaat', 'OnTime', 'Late', 'Missed'];
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
                      color: st > 0 ? stCols[st].withOpacity(0.16) : (isN ? kCardAlt : kCard),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: st > 0 ? stCols[st] : (isN ? kPrimary : kBorder), width: (st > 0 || isN) ? 1.6 : 1.0),
                    ),
                    child: Column(
                      children: [
                        Icon(st > 0 && st < 4 ? Icons.check_circle_rounded : prIcons[pr], size: 20, color: st > 0 ? stCols[st] : (isN ? kPrimary : kMuted)),
                        const SizedBox(height: 8),
                        Text(pr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isN ? kPrimary : kText)),
                        const SizedBox(height: 3),
                        Text(formatClock(times[pr]!).split(' ')[0], style: TextStyle(fontSize: 10.5, fontFamily: 'serif', color: kMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(color: stCols[st].withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
                          child: Text(stTags[st], style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: st == 0 ? kMuted : stCols[st])),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final p = await SharedPreferences.getInstance();
                    setState(() => tasbihCount++);
                    await p.setInt('home_tasbih', tasbihCount);
                  },
                  child: Container(
                    height: 135,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kSecondary.withOpacity(0.45), width: 1.4)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(onTap: () => setState(() => zikrIdx = (zikrIdx + 1) % azkar.length), child: Text('${azkar[zikrIdx]['en']} ↻', style: TextStyle(fontSize: 10.5, color: kSecondary, fontWeight: FontWeight.bold))),
                            GestureDetector(onTap: () async { final p = await SharedPreferences.getInstance(); setState(() => tasbihCount = 0); await p.setInt('home_tasbih', 0); }, child: Icon(Icons.refresh_rounded, size: 16, color: kMuted)),
                          ],
                        ),
                        Text(azkar[zikrIdx]['ar']!, style: TextStyle(fontSize: 20, color: kPrimary, fontWeight: FontWeight.bold)),
                        Text('$tasbihCount', style: TextStyle(fontSize: 28, fontFamily: 'serif', fontWeight: FontWeight.w900, color: kText)),
                        Text('TAP TO COUNT 📿', style: TextStyle(fontSize: 9, color: kSecondary, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onNav(3, sub: 1),
                  child: Container(
                    height: 135,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kPrimary.withOpacity(0.45), width: 1.4)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.library_books_rounded, color: kPrimary, size: 28),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('10 Hadith Books', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kText)),
                            const SizedBox(height: 4),
                            Text('Search All 36,000+ Hadiths Globally', style: TextStyle(fontSize: 11, color: kMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kPrimary.withOpacity(0.4))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [Icon(Icons.auto_awesome, size: 15, color: kPrimary), const SizedBox(width: 6), Text('LIVE AYAH OF THE DAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1))]),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (isPlayingAyah) { await audioPlayer.stop(); setState(() => isPlayingAyah = false); }
                            else { setState(() => isPlayingAyah = true); await audioPlayer.play(UrlSource(liveAyahAudio)); }
                          },
                          child: Icon(isPlayingAyah ? Icons.stop_circle : Icons.volume_up_rounded, size: 20, color: kSecondary),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            await fetchLiveDailyAyahAndDua(forceRandom: true);
                            if (mounted) setState(() {});
                          },
                          child: Text('New Live Ayah ↻', style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(liveAyahRef, style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(liveAyahArab, textAlign: TextAlign.right, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kText, height: 1.5)),
                const SizedBox(height: 10),
                Text(liveAyahTrans, style: TextStyle(fontSize: 13.5, fontFamily: 'serif', color: kSecondary, fontStyle: FontStyle.italic, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kSecondary.withOpacity(0.4))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🤲 LIVE QURANIC DUA OF THE DAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kSecondary, letterSpacing: 1)),
                    Text(liveDuaRef, style: TextStyle(fontSize: 10.5, color: kMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(liveDuaArab, textAlign: TextAlign.right, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kText, height: 1.5)),
                const SizedBox(height: 10),
                Text(liveDuaTrans, style: TextStyle(fontSize: 13, fontFamily: 'serif', color: kMuted, height: 1.4)),
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
        child: Text(txt, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary)),
      ),
    );
  }

  Widget _archStat(String label, String val) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: kMuted, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(val, style: TextStyle(fontSize: 12, color: kText, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

// ---------------- 2. IDENTICAL APP & HOME SCREEN WIDGET STUDIO ----------------
class UniqueWidgetStudioScreen extends StatefulWidget {
  final VoidCallback onRebuild;
  const UniqueWidgetStudioScreen({super.key, required this.onRebuild});
  @override
  State<UniqueWidgetStudioScreen> createState() => _UniqueWidgetStudioScreenState();
}

class _UniqueWidgetStudioScreenState extends State<UniqueWidgetStudioScreen> {
  String loc = '🕌 NOOR • BARPAKA';
  String nextP = 'Dhuhr';
  String nextTime = '12:15 PM';
  String stripText = 'Fajr 04:15  •  Dhuhr 12:15  •  Asr 03:25  •  Mag 04:45  •  Isha 06:15';

  @override
  void initState() {
    super.initState();
    _loadCurrentWidgetData();
  }

  Future<void> _loadCurrentWidgetData() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      loc = p.getString('wp_loc') ?? '🕌 NOOR • BARPAKA';
      nextP = p.getString('wp_next_name') ?? 'Dhuhr';
      nextTime = p.getString('wp_next') ?? '12:15 PM';
      stripText = p.getString('wp_strip') ?? stripText;
    });
  }

  Future<void> _syncAndBroadcast() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('wq_ref', '✨ $liveAyahRef');
    await p.setString('wq_arab', liveAyahArab);
    await p.setString('wq_hing', liveAyahTrans);
    await triggerNativeWidgetBroadcast();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kPrimary,
          content: const Text('✅ Live Broadcast Sent! Your Phone Home Screen Widget is now 100% identical!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          Text('✨ LIVE HOME SCREEN WIDGETS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1.4)),
          const SizedBox(height: 4),
          Text('100% Identical on App & Phone', style: TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 18),

          Text('🕌 1. Noor Salah Pass Widget (Exact Phone Preview)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF24170D), Color(0xFF0E1A16), Color(0xFF080C0B)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF15221E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2DD4BF))),
                      child: const Text('🌙 SUHUR & IFTAR LIVE', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('UPCOMING SALAH', style: TextStyle(color: Color(0xFF8E9E99), fontSize: 9, fontWeight: FontWeight.bold)),
                        Text(nextP, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(nextTime, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 24, fontFamily: 'serif', fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF15221E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2DD4BF))),
                  child: Text(stripText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📖 2. Noor Live Verse Widget (Exact Phone Preview)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
              GestureDetector(
                onTap: () async {
                  await fetchLiveDailyAyahAndDua(forceRandom: true);
                  if (mounted) setState(() {});
                },
                child: Text('Load New API Verse ↻', style: TextStyle(fontSize: 11.5, color: kPrimary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF24170D), Color(0xFF0E1A16), Color(0xFF080C0B)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF15221E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2DD4BF))),
                  child: Text('✨ $liveAyahRef', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Text(liveAyahArab, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: const Color(0xFF15221E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2DD4BF))),
                  child: Text(liveAyahTrans, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontFamily: 'serif', fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            onPressed: _syncAndBroadcast,
            icon: const Icon(Icons.sync_rounded, color: Colors.black),
            label: const Text('INSTANT SYNC TO PHONE HOME SCREEN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}










// ---------------- 3. UNIQUE STREAK, BADGES & CONSISTENCY TAB ----------------
class UniqueStreakScreen extends StatefulWidget {
  const UniqueStreakScreen({super.key});
  @override
  State<UniqueStreakScreen> createState() => _UniqueStreakScreenState();
}

class _UniqueStreakScreenState extends State<UniqueStreakScreen> {
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
    int mAda = 0, mJamaat = 0, perfectDays = 0;
    Map<String, int> pCounts = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

    for (int i = 1; i <= daysInM; i++) {
      final dt = DateTime(now.year, now.month, i);
      int dayC = 0;
      for (var p in prayers) {
        int s = _st(dt, p);
        if (s > 0 && s < 4) {
          mAda++;
          dayC++;
          pCounts[p] = (pCounts[p] ?? 0) + 1;
        }
        if (s == 1) mJamaat++;
      }
      if (dayC == 5) perfectDays++;
    }

    int activeStreak = 0;
    for (int i = 0; i < 30; i++) {
      final dt = now.subtract(Duration(days: i));
      int c = prayers.where((p) { int s = _st(dt, p); return s > 0 && s < 4; }).length;
      if (c > 0) activeStreak++;
      else if (i > 0) break;
    }

    int passedDays = math.max(1, now.day);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          Text('🔥 SPIRITUAL STREAK & MILESTONES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1.4)),
          const SizedBox(height: 4),
          Text('Your Daily Salah Journey', style: TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kPrimary.withOpacity(0.25), kCard]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: kPrimary.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(color: kPrimary.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: kPrimary, width: 2.5)),
                  child: Center(child: Text('🔥 $activeStreak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kText))),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$activeStreak DAY ACTIVE STREAK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPrimary)),
                      const SizedBox(height: 4),
                      Text('$mAda Prayers Offered • $mJamaat in Jamaat • $perfectDays Perfect 5/5 Days', style: TextStyle(fontSize: 12, color: kMuted, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text('🏆 SPIRITUAL ACHIEVEMENT BADGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              _badgeCard('🌅 Fajr Warrior', (pCounts['Fajr'] ?? 0) >= 3, '3+ Fajr on time'),
              const SizedBox(width: 8),
              _badgeCard('🕌 Jamaat Star', mJamaat >= 5, '5+ in Jamaat'),
              const SizedBox(width: 8),
              _badgeCard('👑 5/5 Master', perfectDays >= 1, 'Full 5/5 Day'),
            ],
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 PRAYER-BY-PRAYER STRENGTH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary)),
                const SizedBox(height: 12),
                ...prayers.map((p) {
                  int c = pCounts[p] ?? 0;
                  double ratio = (c / passedDays).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kText)),
                            Text('${(ratio * 100).toInt()}% ($c/$passedDays days)', style: TextStyle(fontSize: 11.5, color: kSecondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: ratio, minHeight: 7, backgroundColor: kBg, valueColor: AlwaysStoppedAnimation<Color>(kSecondary)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🗓️ MONTHLY STREAK HEATMAP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kMuted)),
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
                        color: count == 5 ? kSecondary.withOpacity(0.35) : (count > 0 ? kCardAlt : kBg),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: count == 5 ? kSecondary : kBorder),
                      ),
                      child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText))),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeCard(String title, bool unlocked, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: unlocked ? kPrimary.withOpacity(0.18) : kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: unlocked ? kPrimary : kBorder)),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: unlocked ? kPrimary : kMuted)),
            const SizedBox(height: 4),
            Text(unlocked ? 'UNLOCKED ✓' : sub, style: TextStyle(fontSize: 9.5, color: unlocked ? kSecondary : kMuted, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ---------------- 4. QURAN & 10-BOOK HADITH VAULT (GLOBAL SEARCH!) ----------------
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
            prefixIcon: Icon(Icons.search, size: 18, color: kPrimary),
            filled: true,
            fillColor: kCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kBorder)),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: loadingQuran
              ? Center(child: CircularProgressIndicator(color: kPrimary))
              : ListView.builder(
                  itemCount: fS.length,
                  itemBuilder: (_, i) {
                    final s = fS[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                      child: ListTile(
                        leading: Text('${s['number']}', style: TextStyle(fontFamily: 'serif', color: kPrimary, fontWeight: FontWeight.bold)),
                        title: Text(s['englishName'], style: TextStyle(fontWeight: FontWeight.w700, color: kText)),
                        subtitle: Text('${s['englishNameTranslation']} • ${s['numberOfAyahs']} Verses', style: TextStyle(fontSize: 11, color: kMuted)),
                        trailing: Text(s['name'], style: TextStyle(fontSize: 18, color: kPrimary)),
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
                        Text(b['title'] as String, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: kText, height: 1.2)),
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
          child: Center(child: Text(lb, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: sel ? kPrimary : kMuted))),
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
  List chapterHadiths = [], arabHadiths = [];
  List? fullBookCache;
  bool loading = true, loadingGlobalSearch = false;
  String search = '';

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

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
        setState(() {
          chapterHadiths = td['hadiths'] ?? [];
          arabHadiths = ad != null ? (ad['hadiths'] ?? []) : [];
          loading = false;
        });
      } else if (mounted) {
        if (hLang == 'urd') { hLang = 'eng'; _loadChapter(); return; }
        setState(() => loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _ensureFullBookLoadedForSearch() async {
    if (fullBookCache != null || loadingGlobalSearch) return;
    setState(() => loadingGlobalSearch = true);
    try {
      final url = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$hLang-${widget.bookId}.min.json';
      final r = await http.get(Uri.parse(url));
      if (r.statusCode == 200 && mounted) {
        final d = json.decode(r.body);
        setState(() {
          fullBookCache = d['hadiths'] ?? [];
          loadingGlobalSearch = false;
        });
      } else if (mounted) {
        setState(() => loadingGlobalSearch = false);
      }
    } catch (_) {
      if (mounted) setState(() => loadingGlobalSearch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearchingGlobally = search.trim().isNotEmpty;
    final List sourceList = (isSearchingGlobally && fullBookCache != null) ? fullBookCache! : chapterHadiths;

    final filtered = sourceList.where((h) {
      final t = h['text']?.toString().toLowerCase() ?? '';
      final n = h['hadithnumber']?.toString() ?? '';
      return t.contains(search.toLowerCase()) || n.contains(search);
    }).take(150).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle, style: const TextStyle(fontFamily: 'serif', fontSize: 17)),
        backgroundColor: kBg,
        actions: [
          TextButton(
            onPressed: () {
              setState(() { hLang = hLang == 'eng' ? 'urd' : 'eng'; fullBookCache = null; });
              _loadChapter();
            },
            child: Text(hLang == 'eng' ? 'اردو' : 'EN', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.maxSections > 1 && !isSearchingGlobally)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: kCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: Icon(Icons.chevron_left, color: kPrimary), onPressed: section > 1 ? () { setState(() => section--); _loadChapter(); } : null),
                  Text('Chapter $section / ${widget.maxSections}', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
                  IconButton(icon: Icon(Icons.chevron_right, color: kPrimary), onPressed: section < widget.maxSections ? () { setState(() => section++); _loadChapter(); } : null),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) {
                setState(() => search = v);
                if (v.trim().isNotEmpty) _ensureFullBookLoadedForSearch();
              },
              decoration: InputDecoration(
                hintText: '🔍 Search across ALL ${widget.maxSections} Chapters...',
                prefixIcon: Icon(Icons.search, size: 18, color: widget.accentColor),
                suffixIcon: loadingGlobalSearch ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                filled: true,
                fillColor: kCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (isSearchingGlobally)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                loadingGlobalSearch ? 'Searching all ${widget.maxSections} chapters...' : 'Found ${filtered.length} matches across entire ${widget.bookTitle}',
                style: TextStyle(fontSize: 11, color: kSecondary, fontWeight: FontWeight.bold),
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
                      String arab = (!isSearchingGlobally && i < arabHadiths.length) ? (arabHadiths[i]['text']?.toString() ?? '') : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('${widget.bookTitle} • Hadith #${h['hadithnumber']}', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.w800, fontSize: 11)),
                            if (arab.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(arab, textAlign: TextAlign.right, style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, height: 1.6, color: kText)),
                              Divider(color: kBorder, height: 20),
                            ] else const SizedBox(height: 8),
                            Text(txt, style: TextStyle(fontSize: 14, fontFamily: 'serif', color: kText.withOpacity(0.85), height: 1.5)),
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
    String ed = appLang == 'hi' ? 'hi.hindi' : (appLang == 'ur' ? 'ur.jalandhry' : 'en.asad');
    http.get(Uri.parse('https://api.alquran.cloud/v1/surah/${widget.num}/editions/ar.alafasy,$ed')).then((r) {
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
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ar.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: playingIdx == i ? kPrimary : kBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('VERSE ${ar[i]['numberInSurah']}', style: TextStyle(fontSize: 10, color: kPrimary, fontWeight: FontWeight.w800)),
                        IconButton(
                          icon: Icon(playingIdx == i ? Icons.stop_circle_outlined : Icons.play_circle_outline, color: kSecondary),
                          onPressed: () {
                            if (playingIdx == i) { player.stop(); setState(() => playingIdx = null); }
                            else { setState(() => playingIdx = i); player.play(UrlSource(ar[i]['audio'])); }
                          },
                        ),
                      ],
                    ),
                    Text(ar[i]['text'], textAlign: TextAlign.right, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.7, color: kText)),
                    const SizedBox(height: 10),
                    Text(tr[i]['text'], style: TextStyle(fontSize: 13.5, fontFamily: 'serif', color: kMuted, height: 1.4)),
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------------- 5. SETTINGS, THEME CUSTOMIZER & DEVELOPER PROFILE TAB ----------------
class SettingsProfileScreen extends StatefulWidget {
  final VoidCallback onRebuild;
  const SettingsProfileScreen({super.key, required this.onRebuild});
  @override
  State<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends State<SettingsProfileScreen> {
  final TextEditingController feedbackCtrl = TextEditingController();

  void _copySocial(String handle) {
    Clipboard.setData(ClipboardData(text: handle));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: kPrimary, content: Text('Copied $handle!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kPrimary.withOpacity(0.22), kCard]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: kPrimary.withOpacity(0.45)),
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [kPrimary, kSecondary]), borderRadius: BorderRadius.circular(22)),
                  child: const Icon(Icons.mosque_rounded, size: 36, color: Colors.black),
                ),
                const SizedBox(height: 12),
                Text('NOOR ISLAMIC PRO', style: TextStyle(fontSize: 20, fontFamily: 'serif', fontWeight: FontWeight.w900, color: kText, letterSpacing: 1.2)),
                Text('All-in-One Daily Salah, Live Quran & Hadith Companion', style: TextStyle(fontSize: 11.5, color: kMuted)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialPill(Icons.camera_alt_outlined, '@noor.islamic.app', () => _copySocial('@noor.islamic.app')),
                    const SizedBox(width: 10),
                    _socialPill(Icons.facebook_rounded, 'fb.com/NoorIslamicApp', () => _copySocial('fb.com/NoorIslamicApp')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: kPrimary,
              title: Text(isDarkMode ? '🌙 Dark Mode Active' : '☀️ Light Mode Active', style: TextStyle(fontWeight: FontWeight.bold, color: kText)),
              subtitle: Text('Switch between Dark Obsidian and Clean Light theme', style: TextStyle(fontSize: 11.5, color: kMuted)),
              value: isDarkMode,
              onChanged: (v) async {
                final p = await SharedPreferences.getInstance();
                await p.setBool('dark', v);
                isDarkMode = v;
                widget.onRebuild();
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎨 SELECT APP THEME COLOUR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(kAccentPalettes.length, (i) {
                    final pal = kAccentPalettes[i];
                    bool sel = accentIndex == i;
                    return GestureDetector(
                      onTap: () async {
                        final p = await SharedPreferences.getInstance();
                        await p.setInt('accent', i);
                        accentIndex = i;
                        widget.onRebuild();
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (pal['primary'] as Color).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: sel ? (pal['primary'] as Color) : kBorder, width: sel ? 2 : 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 7, backgroundColor: pal['primary'] as Color),
                            const SizedBox(width: 7),
                            Text(pal['name'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kText)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌐 SELECT APP LANGUAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var l in [{'c': 'en', 'n': 'English'}, {'c': 'hi', 'n': 'हिंदी'}, {'c': 'ur', 'n': 'اردو'}, {'c': 'ro', 'n': 'Hinglish'}])
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final p = await SharedPreferences.getInstance();
                            await p.setString('lang', l['c']!);
                            appLang = l['c']!;
                            await fetchLiveDailyAyahAndDua();
                            widget.onRebuild();
                            setState(() {});
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: appLang == l['c'] ? kPrimary : kCardAlt, borderRadius: BorderRadius.circular(12)),
                            child: Center(child: Text(l['n']!, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: appLang == l['c'] ? Colors.black : kText))),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💬 SEND FEEDBACK & SUGGESTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1)),
                const SizedBox(height: 10),
                TextField(
                  controller: feedbackCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Write your feedback or feature request...',
                    filled: true,
                    fillColor: kBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kBorder)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                    onPressed: () {
                      feedbackCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: kSecondary, content: const Text('JazakAllah Khair! Your feedback has been submitted.', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                      );
                    },
                    child: const Text('Submit Feedback', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kCardAlt, kCard]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kSecondary.withOpacity(0.45), width: 1.4),
            ),
            child: Column(
              children: [
                Text('👨‍💻 DEVELOPED WITH ❤️ FOR THE UMMAH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 14),
                CircleAvatar(
                  radius: 38,
                  backgroundColor: kPrimary,
                  child: CircleAvatar(radius: 35, backgroundColor: kCard, child: Icon(Icons.person_rounded, size: 42, color: kPrimary)),
                ),
                const SizedBox(height: 10),
                Text('Lead Creator & Developer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kText)),
                const SizedBox(height: 6),
                Text(
                  'Passionate about building modern, ad-free, and authentic Islamic digital experiences as Sadaqah Jariyah for Muslims worldwide.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: kMuted, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialPill(Icons.camera_alt_outlined, 'Insta: @developer.noor', () => _copySocial('@developer.noor')),
                    const SizedBox(width: 10),
                    _socialPill(Icons.facebook_rounded, 'FB: /developer.noor', () => _copySocial('fb.com/developer.noor')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialPill(IconData ic, String handle, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 15, color: kPrimary),
            const SizedBox(width: 6),
            Text(handle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText)),
          ],
        ),
      ),
    );
  }
}




