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
String globalUserName = 'Mumin';

String adminPinCode = '7860';
bool adminShowBanner = true;
String adminBannerTitle = 'Noor Official Reminder';
String adminBannerMsg = 'Recite Surah Al-Mulk before sleeping and track your five daily prayers.';
bool adminShowPopup = false;
String adminPopupTitle = 'Special Islamic Broadcast';
String adminPopupBody = 'Assalamu Alaikum. May Allah accept your prayers and good deeds today.';
bool adminUpdateAvailable = false;
String adminLatestVer = 'v13.0 Pro';
String adminUpdateUrl = 'https://github.com/';

String adminAppInsta = '@noor.islamic.app';
String adminAppFb = 'fb.com/NoorIslamicApp';
String adminDevName = 'Lead Creator & Developer';
String adminDevBio = 'Building modern, ad-free and authentic Islamic digital experiences as Sadaqah Jariyah.';
String adminDevInsta = '@developer.noor';
String adminDevFb = 'fb.com/developer.noor';

final List<Map<String, dynamic>> kAccentPalettes = [
  {'name': 'Champagne Gold', 'primary': const Color(0xFFD6B36A), 'sec': const Color(0xFF2DD4BF)},
  {'name': 'Emerald Mint', 'primary': const Color(0xFF10B981), 'sec': const Color(0xFFF59E0B)},
  {'name': 'Royal Sapphire', 'primary': const Color(0xFF38BDF8), 'sec': const Color(0xFF818CF8)},
  {'name': 'Amethyst Velvet', 'primary': const Color(0xFFA855F7), 'sec': const Color(0xFFF472B6)},
  {'name': 'Crimson Ruby', 'primary': const Color(0xFFF43F5E), 'sec': const Color(0xFFFBBF24)},
];

Color get kPrimary => kAccentPalettes[accentIndex]['primary'] as Color;
Color get kSecondary => kAccentPalettes[accentIndex]['sec'] as Color;
Color get kBg => isDarkMode ? const Color(0xFF060D0B) : const Color(0xFFF4F6F5);
Color get kCard => isDarkMode ? const Color(0xFF0E1A16) : const Color(0xFFFFFFFF);
Color get kCardAlt => isDarkMode ? const Color(0xFF142822) : const Color(0xFFE6F0EC);
Color get kBorder => isDarkMode ? const Color(0xFF1E352F) : const Color(0xFFD0DFD9);
Color get kText => isDarkMode ? Colors.white : const Color(0xFF0F172A);
Color get kMuted => isDarkMode ? const Color(0xFF8E9E99) : const Color(0xFF64748B);

String liveAyahRef = 'Surah Ash-Sharh • 94:5';
String liveAyahArab = 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا';
String liveAyahTrans = '"Indeed, with hardship comes ease."';
String liveAyahAudio = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6095.mp3';

String liveDuaRef = 'Quranic Dua • 2:201';
String liveDuaArab = 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ';
String liveDuaTrans = '"Our Lord, grant us good in this world and good in the Hereafter."';

// Authentic Vector Instagram & Facebook Brand Logo Painter (ZERO EMOJIS!)
class SocialLogoPainter extends CustomPainter {
  final bool isInstagram;
  final Color color;
  SocialLogoPainter({required this.isInstagram, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;
    if (isInstagram) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8), Radius.circular(w * 0.24)), p);
      canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.2, p);
      canvas.drawCircle(Offset(w * 0.72, h * 0.28), w * 0.05, Paint()..color = color);
    } else {
      canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.42, p);
      final fPath = Path()
        ..moveTo(w * 0.62, h * 0.28)
        ..lineTo(w * 0.52, h * 0.28)
        ..quadraticBezierTo(w * 0.44, h * 0.28, w * 0.44, h * 0.38)
        ..lineTo(w * 0.44, h * 0.78)
        ..moveTo(w * 0.35, h * 0.50)
        ..lineTo(w * 0.60, h * 0.50);
      canvas.drawPath(fPath, p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

Future<void> triggerNativeWidgetBroadcast() async {
  try { await _widgetChannel.invokeMethod('refreshWidgets'); } catch (_) {}
}

Future<void> fetchLiveDailyAyahAndDua({bool forceRandom = false}) async {
  try {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    String ed = appLang == 'hi' ? 'hi.hindi' : (appLang == 'ur' ? 'ur.jalandhry' : 'en.asad');
    int ayahNum = forceRandom ? (math.Random().nextInt(6200) + 10) : ((dayOfYear * 37 + now.year) % 6220) + 7;

    final r = await http.get(Uri.parse('https://api.alquran.cloud/v1/ayah/$ayahNum/editions/ar.alafasy,$ed'));
    if (r.statusCode == 200) {
      final d = json.decode(r.body)['data'];
      liveAyahArab = d[0]['text'];
      liveAyahAudio = d[0]['audio'] ?? liveAyahAudio;
      liveAyahTrans = '"${d[1]['text']}"';
      liveAyahRef = '${d[0]['surah']['englishName']} • ${d[0]['surah']['number']}:${d[0]['numberInSurah']}';
    }

    const duaNums = [208, 293, 301, 1750, 2373, 2935, 3189, 4153, 5150];
    int duaAyah = duaNums[(forceRandom ? math.Random().nextInt(9) : dayOfYear) % duaNums.length];
    final dr = await http.get(Uri.parse('https://api.alquran.cloud/v1/ayah/$duaAyah/editions/ar.alafasy,$ed'));
    if (dr.statusCode == 200) {
      final dd = json.decode(dr.body)['data'];
      liveDuaArab = dd[0]['text'];
      liveDuaTrans = '"${dd[1]['text']}"';
      liveDuaRef = 'Daily Dua • ${dd[0]['surah']['englishName']} ${dd[0]['surah']['number']}:${dd[0]['numberInSurah']}';
    }

    await p.setString('wq_ref', liveAyahRef.toUpperCase());
    await p.setString('wq_arab', liveAyahArab);
    await p.setString('wq_hing', liveAyahTrans);
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
    SharedPreferences.getInstance().then((p) async {
      setState(() {
        isDarkMode = p.getBool('dark') ?? true;
        accentIndex = p.getInt('accent') ?? 0;
        appLang = p.getString('lang') ?? 'en';
        use12Hour = p.getBool('use12') ?? true;
        globalUserName = p.getString('user_name') ?? 'Mumin';
      });
      await fetchLiveDailyAyahAndDua();
      if (mounted) setState(() {});
    });
  }

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
      home: MainShell(onAppRebuild: () => setState(() {})),
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
  int idx = 0, kitSub = 0;
  void _nav(int i, {int sub = 0}) => setState(() { idx = i; kitSub = sub; });

  @override
  Widget build(BuildContext context) {
    final pages = [
      InteractiveHomeScreen(onNav: _nav, onRebuild: widget.onAppRebuild),
      const UniqueStreakScreen(),
      KitabScreen(initTab: kitSub),
      SettingsProfileScreen(onRebuild: widget.onAppRebuild),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[idx],
      bottomNavigationBar: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: kCard.withOpacity(0.96), borderRadius: BorderRadius.circular(24), border: Border.all(color: kBorder)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navPill(0, Icons.wb_twilight_rounded, 'Today'),
            _navPill(1, Icons.donut_large_rounded, 'Streak'),
            _navPill(2, Icons.menu_book_rounded, 'Kitab'),
            _navPill(3, Icons.tune_rounded, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _navPill(int i, IconData ic, String label) {
    bool sel = idx == i;
    return GestureDetector(
      onTap: () => setState(() => idx = i),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sel ? 16 : 10, vertical: 9),
        decoration: BoxDecoration(color: sel ? kPrimary : Colors.transparent, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(ic, size: 19, color: sel ? Colors.black : kMuted),
            if (sel) ...[const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800))],
          ],
        ),
      ),
    );
  }
}






// ---------------- 1. ARCHITECTURAL HOMEPAGE & IDENTICAL WIDGET STUDIO ----------------
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
  int school = 0, tasbihCount = 0, zikrIdx = 0, remSeconds = 3600;
  bool manual = false, isPlayingAyah = false;
  Timer? timer;
  String nextP = 'Dhuhr', countdown = '02:14:30';

  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, String> times = {'Fajr': '04:15', 'Dhuhr': '12:15', 'Asr': '15:25', 'Maghrib': '16:45', 'Isha': '18:15'};
  Map<String, int> status = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};
  final List<Map<String, String>> azkar = const [
    {'ar': 'سُبْحَانَ اللَّهِ', 'en': 'SubhanAllah'},
    {'ar': 'الْحَمْدُ لِلَّهِ', 'en': 'Alhamdulillah'},
    {'ar': 'اللَّهُ أَكْبَرُ', 'en': 'Allahu Akbar'},
  ];
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    audioPlayer.onPlayerComplete.listen((_) => mounted ? setState(() => isPlayingAyah = false) : null);
  }

  @override
  void dispose() { timer?.cancel(); audioPlayer.dispose(); super.dispose(); }

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
    remSeconds = d.inSeconds;
    if (mounted) {
      setState(() {
        nextP = found;
        countdown = '-${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
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
    _tick();
    final p = await SharedPreferences.getInstance();
    await p.setString('wp_loc', loc.toUpperCase());
    await p.setString('wp_user', globalUserName.toUpperCase());
    await p.setString('wp_next_name', nextP);
    await p.setString('wp_next', formatClock(times[nextP]!));
    await p.setInt('wp_rem_sec', remSeconds);
    await p.setString('wp_strip', 'Fajr   ${formatClock(times['Fajr']!).split(' ')[0]}\nDhuhr  ${formatClock(times['Dhuhr']!).split(' ')[0]}\nAsr    ${formatClock(times['Asr']!).split(' ')[0]}\nMag    ${formatClock(times['Maghrib']!).split(' ')[0]}\nIsha   ${formatClock(times['Isha']!).split(' ')[0]}');
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.location_on_outlined, size: 15, color: kPrimary), const SizedBox(width: 4), Text(loc.toUpperCase(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kText, letterSpacing: 1))]),
                  Text('$hijri • $globalUserName', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  ActionChip(label: Text(use12Hour ? '12H' : '24H', style: TextStyle(fontSize: 10.5, color: kPrimary)), backgroundColor: kCard, onPressed: () async { final p = await SharedPreferences.getInstance(); await p.setBool('use12', !use12Hour); setState(() => use12Hour = !use12Hour); _syncWidgetPrefs(); }),
                  const SizedBox(width: 6),
                  ActionChip(label: Text(school == 0 ? 'SHAFI' : 'HANAFI', style: TextStyle(fontSize: 10.5, color: kSecondary)), backgroundColor: kCard, onPressed: () async { final p = await SharedPreferences.getInstance(); await p.setInt('school', school == 0 ? 1 : 0); _load(); }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual-Pane Architectural Hero Card (Matches Phone Home Screen Widget!)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D2621), Color(0xFF091916), Color(0xFF060D0B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kSecondary.withOpacity(0.55), width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.toUpperCase(), style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: kPrimary.withOpacity(0.5))), child: Text(globalUserName.toUpperCase(), style: TextStyle(color: kSecondary, fontSize: 8.5, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text('NEXT PRAYER', style: TextStyle(color: Color(0xFF8E9E99), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Text(nextP, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      Text(formatClock(times[nextP]!), style: TextStyle(color: kPrimary, fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: kPrimary.withOpacity(0.4))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('REMAINING', style: TextStyle(color: Color(0xFF8E9E99), fontSize: 8.5, fontWeight: FontWeight.bold)),
                            Text(countdown, style: TextStyle(color: kSecondary, fontSize: 13, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(16), border: Border.all(color: kPrimary.withOpacity(0.35))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: prayers.map((p) {
                        bool isN = p == nextP;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p, style: TextStyle(fontSize: 11, fontWeight: isN ? FontWeight.w900 : FontWeight.normal, color: isN ? kSecondary : Colors.white70)),
                              Text(formatClock(times[p]!).split(' ')[0], style: TextStyle(fontSize: 11, fontFamily: 'serif', fontWeight: FontWeight.bold, color: isN ? kPrimary : Colors.white)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DAILY SALAH TRACKER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kMuted, letterSpacing: 1.2)),
              Text('$salahDone OF 5 COMPLETED • HOLD TO EDIT', style: TextStyle(fontSize: 10, color: kPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: prayers.map((pr) {
              bool isN = pr == nextP;
              int st = status[pr] ?? 0;
              final stCols = [kMuted, kSecondary, const Color(0xFF38BDF8), kPrimary, const Color(0xFFEF4444)];
              final stTags = ['LOG', 'JAMAAT', 'ONTIME', 'LATE', 'MISSED'];
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
                      setState(() { times[pr] = t24; manual = true; });
                      _syncWidgetPrefs();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
                    decoration: BoxDecoration(
                      color: st > 0 ? stCols[st].withOpacity(0.16) : (isN ? kCardAlt : kCard),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: st > 0 ? stCols[st] : (isN ? kPrimary : kBorder), width: 1.3),
                    ),
                    child: Column(
                      children: [
                        Icon(st > 0 && st < 4 ? Icons.check_circle_outline_rounded : Icons.schedule_rounded, size: 16, color: stCols[st]),
                        const SizedBox(height: 6),
                        Text(pr, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: isN ? kPrimary : kText)),
                        const SizedBox(height: 4),
                        Text(stTags[st], style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: stCols[st])),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Live API Ayah Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('VERSE OF THE DAY • $liveAyahRef', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 0.8)),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (isPlayingAyah) { await audioPlayer.stop(); setState(() => isPlayingAyah = false); }
                            else { setState(() => isPlayingAyah = true); await audioPlayer.play(UrlSource(liveAyahAudio)); }
                          },
                          child: Icon(isPlayingAyah ? Icons.stop_circle_outlined : Icons.volume_up_outlined, size: 18, color: kSecondary),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async { await fetchLiveDailyAyahAndDua(forceRandom: true); if (mounted) setState(() {}); },
                          child: Icon(Icons.refresh_rounded, size: 18, color: kPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(liveAyahArab, textAlign: TextAlign.right, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kText)),
                const SizedBox(height: 8),
                Text(liveAyahTrans, style: TextStyle(fontSize: 13, fontFamily: 'serif', color: kSecondary, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Live API Dua Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(liveDuaRef.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Text(liveDuaArab, textAlign: TextAlign.right, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kText)),
                const SizedBox(height: 6),
                Text(liveDuaTrans, style: TextStyle(fontSize: 12.5, fontFamily: 'serif', color: kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LiveAnimatedWidgetStudioPage extends StatefulWidget {
  const LiveAnimatedWidgetStudioPage({super.key});
  @override
  State<LiveAnimatedWidgetStudioPage> createState() => _LiveAnimatedWidgetStudioPageState();
}

class _LiveAnimatedWidgetStudioPageState extends State<LiveAnimatedWidgetStudioPage> {
  Timer? _clockTimer;
  String loc = 'BARPAKA', nextP = 'Dhuhr', nextTime = '12:15 PM';
  String stripText = 'Fajr   04:15\nDhuhr  12:15\nAsr    15:25\nMag    16:45\nIsha   18:15';
  int remSec = 5420;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() {
          loc = p.getString('wp_loc') ?? loc;
          nextP = p.getString('wp_next_name') ?? nextP;
          nextTime = p.getString('wp_next') ?? nextTime;
          stripText = p.getString('wp_strip') ?? stripText;
          remSec = p.getInt('wp_rem_sec') ?? 5420;
        });
      }
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted && remSec > 0) setState(() => remSec--); });
  }

  @override
  void dispose() { _clockTimer?.cancel(); super.dispose(); }

  String _fmt(int s) => '-${(s ~/ 3600).toString().padLeft(2, '0')}:${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$globalUserName\'s Home Screen Widgets'), backgroundColor: kBg),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('1. DUAL-PANE PRAYER WIDGET (EXACT PHONE MATCH)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kSecondary, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D2621), Color(0xFF091916), Color(0xFF060D0B)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2DD4BF), width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc, style: const TextStyle(color: Color(0xFFD6B36A), fontSize: 11, fontWeight: FontWeight.bold)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF132A24), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD6B36A))), child: Text(globalUserName.toUpperCase(), style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 8.5, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('NEXT PRAYER', style: TextStyle(color: Color(0xFF8E9E99), fontSize: 9, fontWeight: FontWeight.bold)),
                      Text(nextP, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(nextTime, style: const TextStyle(color: Color(0xFFD6B36A), fontSize: 20, fontFamily: 'serif', fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFF132A24), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD6B36A))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('REMAINING', style: TextStyle(color: Color(0xFF8E9E99), fontSize: 8.5, fontWeight: FontWeight.bold)),
                            Text(_fmt(remSec), style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF132A24), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD6B36A))),
                    child: Text(stripText, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold, height: 1.5)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('2. DAILY QURAN VERSE WIDGET (EXACT PHONE MATCH)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D2621), Color(0xFF091916), Color(0xFF060D0B)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2DD4BF), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(liveAyahRef.toUpperCase(), style: const TextStyle(color: Color(0xFFD6B36A), fontSize: 9.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(liveAyahArab, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF132A24), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD6B36A))),
                  child: Text(liveAyahTrans, style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11.5, fontFamily: 'serif', fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () async {
              await triggerNativeWidgetBroadcast();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kSecondary, content: const Text('Widgets Force-Pushed to Phone Home Screen!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))));
            },
            icon: const Icon(Icons.sync_rounded, color: Colors.black),
            label: const Text('FORCE SYNC TO PHONE HOME SCREEN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}








// ---------------- 3. ENHANCED EXECUTIVE STREAK TAB & 4. KITAB TAB ----------------
class UniqueStreakScreen extends StatefulWidget {
  const UniqueStreakScreen({super.key});
  @override
  State<UniqueStreakScreen> createState() => _UniqueStreakScreenState();
}

class _UniqueStreakScreenState extends State<UniqueStreakScreen> {
  SharedPreferences? prefs;
  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  @override
  void initState() { super.initState(); SharedPreferences.getInstance().then((p) => setState(() => prefs = p)); }
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
        if (s > 0 && s < 4) { mAda++; dayC++; pCounts[p] = (pCounts[p] ?? 0) + 1; }
        if (s == 1) mJamaat++;
      }
      if (dayC == 5) perfectDays++;
    }

    int activeStreak = 0;
    for (int i = 0; i < 30; i++) {
      final dt = now.subtract(Duration(days: i));
      int c = prayers.where((p) { int s = _st(dt, p); return s > 0 && s < 4; }).length;
      if (c > 0) activeStreak++; else if (i > 0) break;
    }

    int passedDays = math.max(1, now.day);
    double scorePct = ((mAda / (passedDays * 5)) * 100).clamp(0.0, 100.0);
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          Text('SPIRITUAL ANALYTICS & STREAK', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1.2)),
          const SizedBox(height: 12),

          // 1. Radial Score Gauge & KPI Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kPrimary.withOpacity(0.45))),
            child: Row(
              children: [
                SizedBox(
                  width: 82,
                  height: 82,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(value: scorePct / 100, strokeWidth: 8, backgroundColor: kBg, valueColor: AlwaysStoppedAnimation(kSecondary)),
                      Center(child: Text('${scorePct.toInt()}%', style: TextStyle(fontSize: 19, fontFamily: 'serif', fontWeight: FontWeight.w900, color: kText))),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.bolt_rounded, size: 18, color: kPrimary), const SizedBox(width: 4), Text('$activeStreak DAY ACTIVE STREAK', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kPrimary))]),
                      const SizedBox(height: 6),
                      Text('$mAda Offered • $mJamaat in Jamaat • $perfectDays Full 5/5 Days', style: TextStyle(fontSize: 12, color: kMuted, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. 7-Day Weekly Performance Bar Chart
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAST 7 DAYS PERFORMANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kMuted, letterSpacing: 1)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 115,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final d = now.subtract(Duration(days: 6 - i));
                      int c = prayers.where((p) { int s = _st(d, p); return s > 0 && s < 4; }).length;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$c/5', style: TextStyle(fontSize: 9.5, color: kMuted)),
                          const SizedBox(height: 5),
                          Container(width: 24, height: math.max(8, c * 15.0), decoration: BoxDecoration(color: c == 5 ? kPrimary : kSecondary, borderRadius: BorderRadius.circular(6))),
                          const SizedBox(height: 6),
                          Text(weekDays[d.weekday - 1], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText)),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Prayer-by-Prayer Consistency Meters
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRAYER-BY-PRAYER DISCIPLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1)),
                const SizedBox(height: 12),
                ...prayers.map((p) {
                  int c = pCounts[p] ?? 0;
                  double r = (c / passedDays).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: kText)), Text('${(r * 100).toInt()}% ($c/$passedDays)', style: TextStyle(fontSize: 11, color: kSecondary, fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 4),
                        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: r, minHeight: 6, backgroundColor: kBg, valueColor: AlwaysStoppedAnimation(kSecondary))),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. 30-Day Monthly Matrix
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemCount: daysInM,
              itemBuilder: (_, i) {
                final dt = DateTime(now.year, now.month, i + 1);
                int c = prayers.where((p) { int s = _st(dt, p); return s > 0 && s < 4; }).length;
                return Container(
                  decoration: BoxDecoration(color: c == 5 ? kSecondary.withOpacity(0.35) : (c > 0 ? kCardAlt : kBg), borderRadius: BorderRadius.circular(8), border: Border.all(color: c == 5 ? kSecondary : kBorder)),
                  child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class KitabScreen extends StatefulWidget {
  final int initTab;
  const KitabScreen({super.key, this.initTab = 0});
  @override
  State<KitabScreen> createState() => _KitabScreenState();
}

class _KitabScreenState extends State<KitabScreen> {
  late int tab;
  List surahs = [];
  bool loadingQuran = true, loadingCloudHadiths = false;
  String qSearch = '', globalHadithQuery = '';
  List<Map<String, String>> globalHadithPool = [];

  final List<Map<String, dynamic>> hadithBooks = const [
    {'id': 'bukhari', 'title': 'Sahih\nal-Bukhari', 'count': '7589', 'sec': 97, 'col': Color(0xFF818CF8), 'ic': Icons.book_rounded},
    {'id': 'muslim', 'title': 'Sahih\nMuslim', 'count': '7563', 'sec': 56, 'col': Color(0xFF2DD4BF), 'ic': Icons.menu_book_rounded},
    {'id': 'nasai', 'title': 'Sunan\nan-Nasa\'i', 'count': '5765', 'sec': 51, 'col': Color(0xFFF59E0B), 'ic': Icons.auto_stories_rounded},
    {'id': 'abudawud', 'title': 'Sunan\nAbu Dawud', 'count': '5274', 'sec': 43, 'col': Color(0xFFEF4444), 'ic': Icons.bookmark_rounded},
    {'id': 'tirmidhi', 'title': 'Jami\'\nat-Tirmidhi', 'count': '3998', 'sec': 49, 'col': Color(0xFF38BDF8), 'ic': Icons.library_books_rounded},
    {'id': 'ibnmajah', 'title': 'Sunan\nIbn Majah', 'count': '4343', 'sec': 37, 'col': Color(0xFFC084FC), 'ic': Icons.collections_bookmark_rounded},
    {'id': 'malik', 'title': 'Muwatta\nMalik', 'count': '1858', 'sec': 61, 'col': Color(0xFF34D399), 'ic': Icons.layers_rounded},
    {'id': 'nawawi', 'title': 'An-Nawawi\'s\n40 Hadith', 'count': '42', 'sec': 1, 'col': Color(0xFFF43F5E), 'ic': Icons.star_border_rounded},
    {'id': 'qudsi', 'title': 'Hadith\nQudsi', 'count': '40', 'sec': 1, 'col': Color(0xFF60A5FA), 'ic': Icons.article_outlined},
    {'id': 'dehlawi', 'title': 'Shah Waliullah\n40 Hadith', 'count': '40', 'sec': 1, 'col': Color(0xFF10B981), 'ic': Icons.history_edu_rounded},
  ];

  @override
  void initState() {
    super.initState();
    tab = widget.initTab;
    http.get(Uri.parse('https://api.alquran.cloud/v1/surah')).then((r) {
      if (r.statusCode == 200 && mounted) setState(() { surahs = json.decode(r.body)['data']; loadingQuran = false; });
    });
    _preloadMassiveHadithDatabase();
  }

  // Loads thousands of Hadiths from full book JSONs and calls setState() so Search works 100%!
  Future<void> _preloadMassiveHadithDatabase() async {
    if (loadingCloudHadiths) return;
    setState(() => loadingCloudHadiths = true);
    try {
      final sources = [
        {'b': 'An-Nawawi 40', 'url': 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-nawawi.min.json'},
        {'b': 'Hadith Qudsi', 'url': 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-qudsi.min.json'},
        {'b': 'Shah Waliullah', 'url': 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-dehlawi.min.json'},
        {'b': 'Sahih Bukhari', 'url': 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-bukhari.min.json'},
        {'b': 'Sahih Muslim', 'url': 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-muslim.min.json'},
      ];
      for (var src in sources) {
        final r = await http.get(Uri.parse(src['url']!));
        if (r.statusCode == 200) {
          final List list = json.decode(r.body)['hadiths'] ?? [];
          for (var h in list) {
            final t = h['text']?.toString() ?? '';
            if (t.isNotEmpty) {
              globalHadithPool.add({'book': src['b']!, 'num': h['hadithnumber']?.toString() ?? '', 'en': t});
            }
          }
          if (mounted) setState(() {}); // Immediately refresh search results as each book arrives!
        }
      }
    } catch (_) {}
    if (mounted) setState(() => loadingCloudHadiths = false);
  }

  void _openFullHadithModal(Map<String, String> h) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${h['book']} • Hadith #${h['num']}', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900, fontSize: 13)),
                IconButton(icon: Icon(Icons.copy_rounded, color: kSecondary), onPressed: () { Clipboard.setData(ClipboardData(text: '${h['en']} (${h['book']} #${h['num']})')); Navigator.pop(ctx); }),
              ],
            ),
            Divider(color: kBorder, height: 22),
            Text(h['en']!, style: TextStyle(fontSize: 15, fontFamily: 'serif', color: kText, height: 1.6)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fS = surahs.where((s) => s['englishName'].toString().toLowerCase().contains(qSearch.toLowerCase()) || s['number'].toString().contains(qSearch)).toList();
    final bool isSearchingH = globalHadithQuery.trim().isNotEmpty;
    final hResults = isSearchingH
        ? globalHadithPool.where((h) {
            final q = globalHadithQuery.toLowerCase();
            return h['en']!.toLowerCase().contains(q) || h['book']!.toLowerCase().contains(q) || h['num']!.contains(q);
          }).take(200).toList()
        : <Map<String, String>>[];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 85),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
              child: Row(children: [_segBtn('AL-QURAN (114)', 0), _segBtn('10 HADITH BOOKS', 1)]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tab == 0
                  ? Column(
                      children: [
                        TextField(onChanged: (v) => setState(() => qSearch = v), decoration: InputDecoration(hintText: 'Search Surah name or number...', prefixIcon: Icon(Icons.search, color: kPrimary), filled: true, fillColor: kCard, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                        const SizedBox(height: 10),
                        Expanded(
                          child: loadingQuran
                              ? Center(child: CircularProgressIndicator(color: kPrimary))
                              : ListView.builder(
                                  itemCount: fS.length,
                                  itemBuilder: (_, i) => ListTile(
                                    leading: Text('${fS[i]['number']}', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                                    title: Text(fS[i]['englishName'], style: TextStyle(fontWeight: FontWeight.bold, color: kText)),
                                    trailing: Text(fS[i]['name'], style: TextStyle(fontSize: 18, color: kPrimary)),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReaderPage(num: fS[i]['number'], name: fS[i]['englishName']))),
                                  ),
                                ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(
                          onChanged: (v) => setState(() => globalHadithQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search across ${globalHadithPool.length}+ Hadiths (word or #)...',
                            prefixIcon: Icon(Icons.search_rounded, color: kPrimary),
                            suffixIcon: isSearchingH ? IconButton(icon: Icon(Icons.clear, color: kMuted), onPressed: () => setState(() => globalHadithQuery = '')) : null,
                            filled: true,
                            fillColor: kCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: isSearchingH
                              ? ListView.builder(
                                  itemCount: hResults.length,
                                  itemBuilder: (_, i) {
                                    final h = hResults[i];
                                    return GestureDetector(
                                      onTap: () => _openFullHadithModal(h),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kPrimary.withOpacity(0.4))),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('${h['book']} • #${h['num']}', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                                                Text('View Full Hadith', style: TextStyle(color: kSecondary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(h['en']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: kText)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1),
                                  itemCount: hadithBooks.length,
                                  itemBuilder: (ctx, i) {
                                    final b = hadithBooks[i];
                                    final Color c = b['col'] as Color;
                                    return GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HadithBookReaderPage(bookId: b['id'] as String, bookTitle: b['title'].toString().replaceAll('\n', ' '), maxSections: b['sec'] as int, accentColor: c))),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.35))),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Icon(b['ic'] as IconData, color: c, size: 24),
                                                Text(b['count'] as String, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 12)),
                                              ],
                                            ),
                                            const Spacer(),
                                            Text(b['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
                                          ],
                                        ),
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

  Widget _segBtn(String lb, int i) {
    bool sel = tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: sel ? kCardAlt : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(lb, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: sel ? kPrimary : kMuted))),
        ),
      ),
    );
  }
}


// ---------------- READERS, SETTINGS (VECTOR BRAND LOGOS!) & ADMIN PANEL ----------------
class HadithBookReaderPage extends StatefulWidget {
  final String bookId, bookTitle;
  final int maxSections;
  final Color accentColor;
  const HadithBookReaderPage({super.key, required this.bookId, required this.bookTitle, required this.maxSections, required this.accentColor});
  @override
  State<HadithBookReaderPage> createState() => _HadithBookReaderPageState();
}

class _HadithBookReaderPageState extends State<HadithBookReaderPage> {
  int section = 1;
  List chapterHadiths = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _loadChapter(); }

  Future<void> _loadChapter() async {
    setState(() => loading = true);
    try {
      String u = widget.maxSections == 1
          ? 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-${widget.bookId}.json'
          : 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-${widget.bookId}/sections/$section.json';
      final r = await http.get(Uri.parse(u));
      if (r.statusCode == 200 && mounted) setState(() { chapterHadiths = json.decode(r.body)['hadiths'] ?? []; loading = false; });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }

  void _showFull(String num, String txt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.bookTitle} • Hadith #$num', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(txt, style: TextStyle(fontSize: 15, fontFamily: 'serif', color: kText, height: 1.55)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bookTitle), backgroundColor: kBg),
      body: Column(
        children: [
          if (widget.maxSections > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: Icon(Icons.chevron_left, color: kPrimary), onPressed: section > 1 ? () { setState(() => section--); _loadChapter(); } : null),
                Text('Chapter $section / ${widget.maxSections}', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                IconButton(icon: Icon(Icons.chevron_right, color: kPrimary), onPressed: section < widget.maxSections ? () { setState(() => section++); _loadChapter(); } : null),
              ],
            ),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: widget.accentColor))
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: chapterHadiths.length,
                    itemBuilder: (_, i) {
                      final h = chapterHadiths[i];
                      final txt = h['text']?.toString() ?? '';
                      if (txt.isEmpty) return const SizedBox.shrink();
                      final num = h['hadithnumber']?.toString() ?? '';
                      return GestureDetector(
                        onTap: () => _showFull(num, txt),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hadith #$num', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 12)), Text('View Full Hadith', style: TextStyle(color: kSecondary, fontSize: 10.5, fontWeight: FontWeight.bold))]),
                              const SizedBox(height: 6),
                              Text(txt, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: kText, fontSize: 13.5)),
                            ],
                          ),
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
      appBar: AppBar(title: Text(widget.name), backgroundColor: kBg),
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
                        Text('VERSE ${ar[i]['numberInSurah']}', style: TextStyle(fontSize: 10, color: kPrimary, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(playingIdx == i ? Icons.stop_circle_outlined : Icons.play_circle_outline, color: kSecondary),
                          onPressed: () {
                            if (playingIdx == i) { player.stop(); setState(() => playingIdx = null); }
                            else { setState(() => playingIdx = i); player.play(UrlSource(ar[i]['audio'])); }
                          },
                        ),
                      ],
                    ),
                    Text(ar[i]['text'], textAlign: TextAlign.right, style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: kText)),
                    const SizedBox(height: 8),
                    Text(tr[i]['text'], style: TextStyle(fontSize: 13.5, color: kMuted)),
                  ],
                ),
              ),
            ),
    );
  }
}

class SettingsProfileScreen extends StatefulWidget {
  final VoidCallback onRebuild;
  const SettingsProfileScreen({super.key, required this.onRebuild});
  @override
  State<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends State<SettingsProfileScreen> {
  void _openUserNameAndWidgets() {
    final ctrl = TextEditingController(text: globalUserName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Profile Name & Widgets', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Your Name')),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              String n = ctrl.text.trim();
              if (n.isNotEmpty) {
                final p = await SharedPreferences.getInstance();
                await p.setString('user_name', n);
                await p.setString('wp_user', n.toUpperCase());
                globalUserName = n;
                await triggerNativeWidgetBroadcast();
                widget.onRebuild();
                setState(() {});
              }
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveAnimatedWidgetStudioPage()));
              }
            },
            child: const Text('Save & Open Widgets', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openAdminPin() {
    final pinC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Admin Access (PIN: 7860)', style: TextStyle(color: kPrimary)),
        content: TextField(controller: pinC, obscureText: true, keyboardType: TextInputType.number),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () {
              if (pinC.text.trim() == adminPinCode) {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboardPage(onRebuild: widget.onRebuild)));
              }
            },
            child: const Text('Unlock', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _brandBadge(bool isInsta, String handle) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: handle));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kPrimary, content: Text('Copied $handle', style: const TextStyle(color: Colors.black))));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CustomPaint(painter: SocialLogoPainter(isInstagram: isInsta, color: isInsta ? kPrimary : kSecondary))),
            const SizedBox(width: 7),
            Text(handle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        children: [
          // 1. TOP APP LOGO & VECTOR SOCIAL HANDLES
          GestureDetector(
            onLongPress: _openAdminPin,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kPrimary.withOpacity(0.45))),
              child: Column(
                children: [
                  Container(width: 58, height: 58, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.mosque_outlined, size: 30, color: Colors.black)),
                  const SizedBox(height: 10),
                  Text('NOOR ARCHITECTURAL', style: TextStyle(fontSize: 18, fontFamily: 'serif', fontWeight: FontWeight.w900, color: kText, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _brandBadge(true, adminAppInsta),
                      const SizedBox(width: 10),
                      _brandBadge(false, adminAppFb),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. DARK / LIGHT MODE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: kPrimary,
              title: Text(isDarkMode ? 'Dark Appearance' : 'Light Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: kText)),
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
          const SizedBox(height: 14),

          // 3. USERNAME & WIDGET STUDIO (DIRECTLY ABOVE LANGUAGE!)
          GestureDetector(
            onTap: _openUserNameAndWidgets,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(18), border: Border.all(color: kSecondary)),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: kSecondary, child: const Icon(Icons.layers_outlined, color: Colors.black)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User: $globalUserName • Home Widgets', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: kText)),
                        Text('Tap to set Username and sync Dual-Pane Widgets', style: TextStyle(fontSize: 11, color: kSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 15, color: kSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. LANGUAGE SELECTOR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LANGUAGE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var l in [{'c': 'en', 'n': 'English'}, {'c': 'hi', 'n': 'Hindi'}, {'c': 'ur', 'n': 'Urdu'}, {'c': 'ro', 'n': 'Hinglish'}])
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
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(color: appLang == l['c'] ? kPrimary : kCardAlt, borderRadius: BorderRadius.circular(10)),
                            child: Center(child: Text(l['n']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: appLang == l['c'] ? Colors.black : kText))),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. THEME COLOUR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THEME ACCENT COLOUR', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(kAccentPalettes.length, (i) {
                    final pal = kAccentPalettes[i];
                    return GestureDetector(
                      onTap: () async {
                        final p = await SharedPreferences.getInstance();
                        await p.setInt('accent', i);
                        accentIndex = i;
                        widget.onRebuild();
                        setState(() {});
                      },
                      child: Chip(
                        backgroundColor: (pal['primary'] as Color).withOpacity(0.18),
                        avatar: CircleAvatar(backgroundColor: pal['primary'] as Color),
                        label: Text(pal['name'] as String, style: TextStyle(fontSize: 11, color: kText)),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 6. DEVELOPER PROFILE WITH VECTOR INSTA & FB LOGOS
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: Column(
              children: [
                CircleAvatar(radius: 32, backgroundColor: kPrimary, child: const Icon(Icons.person_outline_rounded, size: 34, color: Colors.black)),
                const SizedBox(height: 8),
                Text(adminDevName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                const SizedBox(height: 4),
                Text(adminDevBio, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: kMuted)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _brandBadge(true, adminDevInsta),
                    const SizedBox(width: 10),
                    _brandBadge(false, adminDevFb),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: _openAdminPin, icon: Icon(Icons.lock_outline_rounded, size: 15, color: kPrimary), label: Text('Owner Admin Panel', style: TextStyle(color: kPrimary, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  final VoidCallback onRebuild;
  const AdminDashboardPage({super.key, required this.onRebuild});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final banTC = TextEditingController(text: adminBannerTitle);
  final banMC = TextEditingController(text: adminBannerMsg);
  final devNC = TextEditingController(text: adminDevName);
  bool sBan = adminShowBanner, sPop = adminShowPopup, sUpd = adminUpdateAvailable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Admin Control Panel'), backgroundColor: kBg),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SwitchListTile(title: const Text('Show Home Banner'), value: sBan, onChanged: (v) => setState(() => sBan = v)),
          TextField(controller: banTC, decoration: const InputDecoration(labelText: 'Banner Title')),
          TextField(controller: banMC, decoration: const InputDecoration(labelText: 'Banner Message')),
          SwitchListTile(title: const Text('Show Startup Popup Alert'), value: sPop, onChanged: (v) => setState(() => sPop = v)),
          SwitchListTile(title: const Text('Show APK Update Available'), value: sUpd, onChanged: (v) => setState(() => sUpd = v)),
          TextField(controller: devNC, decoration: const InputDecoration(labelText: 'Developer Name')),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('adm_show_ban', sBan);
              await p.setString('adm_ban_t', banTC.text);
              await p.setString('adm_ban_m', banMC.text);
              await p.setBool('adm_show_pop', sPop);
              await p.setBool('adm_upd_on', sUpd);
              await p.setString('adm_dev_n', devNC.text);
              adminShowBanner = sBan;
              adminBannerTitle = banTC.text;
              adminBannerMsg = banMC.text;
              adminShowPopup = sPop;
              adminUpdateAvailable = sUpd;
              adminDevName = devNC.text;
              widget.onRebuild();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('SAVE ADMIN SETTINGS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
