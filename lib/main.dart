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
int widgetThemeIdx = 0;
int widgetAyahSize = 22;

String adminPinCode = '7860';
bool adminShowBanner = true;
String adminBannerTitle = 'Sirat Official Reminder';
String adminBannerMsg = 'Recite Surah Al-Mulk before sleeping and track your five daily prayers.';
bool adminShowPopup = false;
String adminPopupTitle = 'Sirat Broadcast';
String adminPopupBody = 'Assalamu Alaikum. May Allah accept your prayers and good deeds today.';
bool adminUpdateAvailable = false;
String adminLatestVer = 'v1.0.0 Official';
String adminUpdateUrl = 'https://github.com/';

String adminAppInsta = '@sirat.islamic.app';
String adminAppFb = 'fb.com/SiratIslamicApp';
String adminDevName = 'Lead Creator & Developer';
String adminDevBio = 'Building modern, ad-free and authentic Islamic digital experiences as Sadaqah Jariyah.';
String adminDevInsta = '@developer.sirat';
String adminDevFb = 'fb.com/developer.sirat';

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

// Custom Generated "SIRAT" (The Straight Path) Vector Emblem
class SiratLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bgRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(w * 0.26));
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF071713));
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFFD6B36A)..style = PaintingStyle.stroke..strokeWidth = 2.2);

    // Mihrab Arch
    final arch = Path()
      ..moveTo(w * 0.22, h * 0.85)
      ..lineTo(w * 0.22, h * 0.45)
      ..quadraticBezierTo(w * 0.22, h * 0.18, w * 0.5, h * 0.12)
      ..quadraticBezierTo(w * 0.78, h * 0.18, w * 0.78, h * 0.45)
      ..lineTo(w * 0.78, h * 0.85)
      ..close();
    canvas.drawPath(arch, Paint()..color = const Color(0xFFD6B36A)..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // Ascending Straight Path ("Sirat")
    final path = Path()
      ..moveTo(w * 0.36, h * 0.85)
      ..lineTo(w * 0.47, h * 0.38)
      ..lineTo(w * 0.53, h * 0.38)
      ..lineTo(w * 0.64, h * 0.85)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF2DD4BF));

    // Guiding 4-Point Star at the Summit
    final star = Path()
      ..moveTo(w * 0.5, h * 0.19)
      ..lineTo(w * 0.53, h * 0.26)
      ..lineTo(w * 0.60, h * 0.29)
      ..lineTo(w * 0.53, h * 0.32)
      ..lineTo(w * 0.5, h * 0.39)
      ..lineTo(w * 0.47, h * 0.32)
      ..lineTo(w * 0.40, h * 0.29)
      ..lineTo(w * 0.47, h * 0.26)
      ..close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFD6B36A));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
      final fPath = Path()..moveTo(w * 0.62, h * 0.28)..lineTo(w * 0.52, h * 0.28)..quadraticBezierTo(w * 0.44, h * 0.28, w * 0.44, h * 0.38)..lineTo(w * 0.44, h * 0.78)..moveTo(w * 0.35, h * 0.50)..lineTo(w * 0.60, h * 0.50);
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

Future<void> scheduleNativePrayerNotifications(Map<String, String> times) async {
  try { await _widgetChannel.invokeMethod('scheduleAlarms', times); } catch (_) {}
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
  bool showOnboarding = false;

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
        widgetThemeIdx = p.getInt('wid_theme') ?? 0;
        widgetAyahSize = p.getInt('wid_size') ?? 22;
        showOnboarding = !(p.getBool('sirat_onboarded') ?? false);
      });
      await fetchLiveDailyAyahAndDua();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sirat',
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: kBg,
        primaryColor: kPrimary,
        cardColor: kCard,
      ),
      home: showOnboarding
          ? SiratOnboardingFlashcards(onFinish: () => setState(() => showOnboarding = false))
          : MainShell(onAppRebuild: () => setState(() {})),
    );
  }
}

// Interactive 4-Slide Flashcard Onboarding for New Users!
class SiratOnboardingFlashcards extends StatefulWidget {
  final VoidCallback onFinish;
  const SiratOnboardingFlashcards({super.key, required this.onFinish});
  @override
  State<SiratOnboardingFlashcards> createState() => _SiratOnboardingFlashcardsState();
}

class _SiratOnboardingFlashcardsState extends State<SiratOnboardingFlashcards> {
  final PageController _pc = PageController();
  int page = 0;
  final nameC = TextEditingController(text: 'Mumin');
  final cityC = TextEditingController(text: 'Barpaka');

  final List<Map<String, dynamic>> cards = const [
    {'tag': 'WELCOME TO SIRAT', 'title': 'Your Companion on\nthe Straight Path', 'sub': 'An architectural, ad-free Islamic ecosystem crafted for daily Salah discipline, Quranic reflection, and authentic Sunnah.', 'ic': Icons.mosque_outlined},
    {'tag': 'PRECISION SALAH & ALARMS', 'title': 'Dual-Pane Live Timer\n& Prayer Alerts', 'sub': 'Track your 5 daily prayers in Jamaat or On-Time. Hold any prayer time to set your local Masjid schedule and receive exact prayer notifications.', 'ic': Icons.notifications_active_outlined},
    {'tag': 'QURAN.COM SCRIPT & HADITH', 'title': '114 Surahs & 36,000+\nAuthentic Hadiths', 'sub': 'Read the Noble Quran in authentic Uthmani calligraphy with audio recitation, and search globally across 10 major Hadith collections.', 'ic': Icons.menu_book_rounded},
    {'tag': 'HOME WIDGETS & PERSONALIZE', 'title': 'Live Wallpaper Widgets\n& Spiritual Streak', 'sub': 'Sync dual-pane countdown and daily verse widgets directly to your phone home screen. Enter your name and city below to begin.', 'ic': Icons.layers_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [SizedBox(width: 28, height: 28, child: CustomPaint(painter: SiratLogoPainter())), const SizedBox(width: 8), Text('SIRAT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: kPrimary))]),
                  Row(
                    children: List.generate(4, (i) => Container(width: page == i ? 22 : 7, height: 7, margin: const EdgeInsets.only(left: 5), decoration: BoxDecoration(color: page == i ? kPrimary : kBorder, borderRadius: BorderRadius.circular(6)))),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  onPageChanged: (i) => setState(() => page = i),
                  itemCount: cards.length,
                  itemBuilder: (_, i) {
                    final c = cards[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [kCardAlt, kCard], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: kPrimary.withOpacity(0.45), width: 1.5),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (i == 0)
                              Center(child: SizedBox(width: 84, height: 84, child: CustomPaint(painter: SiratLogoPainter())))
                            else
                              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Icon(c['ic'] as IconData, size: 36, color: kPrimary)),
                            const SizedBox(height: 24),
                            Text(c['tag'] as String, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kSecondary, letterSpacing: 1.4)),
                            const SizedBox(height: 8),
                            Text(c['title'] as String, style: TextStyle(fontSize: 26, fontFamily: 'serif', fontWeight: FontWeight.bold, color: kText, height: 1.2)),
                            const SizedBox(height: 14),
                            Text(c['sub'] as String, style: TextStyle(fontSize: 13.5, color: kMuted, height: 1.55)),
                            if (i == 3) ...[
                              const SizedBox(height: 20),
                              TextField(controller: nameC, decoration: InputDecoration(labelText: 'Your Name', filled: true, fillColor: kBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                              const SizedBox(height: 10),
                              TextField(controller: cityC, decoration: InputDecoration(labelText: 'Your City / Town', filled: true, fillColor: kBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  onPressed: () async {
                    if (page < 3) {
                      _pc.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                    } else {
                      final p = await SharedPreferences.getInstance();
                      await p.setBool('sirat_onboarded', true);
                      if (nameC.text.trim().isNotEmpty) {
                        globalUserName = nameC.text.trim();
                        await p.setString('user_name', globalUserName);
                      }
                      if (cityC.text.trim().isNotEmpty) {
                        await p.setString('loc', cityC.text.trim());
                      }
                      widget.onFinish();
                    }
                  },
                  child: Text(page < 3 ? 'NEXT FLASHCARD' : 'BEGIN MY SIRAT JOURNEY', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                ),
              ),
            ],
          ),
        ),
      ),
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








// ---------------- 1. HOMEPAGE (QURAN.COM FONT + ALARMS) & 2. WIDGET STUDIO (SIZE + THEME) ----------------
class InteractiveHomeScreen extends StatefulWidget {
  final Function(int, {int sub}) onNav;
  final VoidCallback onRebuild;
  const InteractiveHomeScreen({super.key, required this.onNav, required this.onRebuild});
  @override
  State<InteractiveHomeScreen> createState() => _InteractiveHomeScreenState();
}

class _InteractiveHomeScreenState extends State<InteractiveHomeScreen> {
  String loc = 'Barpaka', hijri = '1448 AH';
  double lat = 26.4167, lon = 92.7333;
  int school = 0, remSeconds = 3600;
  bool manual = false, isPlayingAyah = false;
  Timer? timer;
  String nextP = 'Dhuhr', countdown = '-02:14:30';

  final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, String> times = {'Fajr': '04:15', 'Dhuhr': '12:15', 'Asr': '15:25', 'Maghrib': '16:45', 'Isha': '18:15'};
  Map<String, int> status = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};
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
      for (var pr in prayers) {
        status[pr] = p.getInt('st_${tKey}_$pr') ?? 0;
        if (manual) times[pr] = p.getString('mt_$pr') ?? times[pr]!;
      }
    });
    if (!manual) _fetchAPI();
    _syncWidgetAndAlarms();
  }

  Future<void> _syncWidgetAndAlarms() async {
    _tick();
    final p = await SharedPreferences.getInstance();
    await p.setString('wp_loc', loc.toUpperCase());
    await p.setString('wp_user', globalUserName.toUpperCase());
    await p.setString('wp_next_name', nextP);
    await p.setString('wp_next', formatClock(times[nextP]!));
    await p.setInt('wp_rem_sec', remSeconds);
    await p.setString('wp_strip', 'Fajr   ${formatClock(times['Fajr']!).split(' ')[0]}\nDhuhr  ${formatClock(times['Dhuhr']!).split(' ')[0]}\nAsr    ${formatClock(times['Asr']!).split(' ')[0]}\nMag    ${formatClock(times['Maghrib']!).split(' ')[0]}\nIsha   ${formatClock(times['Isha']!).split(' ')[0]}');
    await triggerNativeWidgetBroadcast();
    await scheduleNativePrayerNotifications(times);
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
        _syncWidgetAndAlarms();
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
                  ActionChip(label: Text(use12Hour ? '12H' : '24H', style: TextStyle(fontSize: 10.5, color: kPrimary)), backgroundColor: kCard, onPressed: () async { final p = await SharedPreferences.getInstance(); await p.setBool('use12', !use12Hour); setState(() => use12Hour = !use12Hour); _syncWidgetAndAlarms(); }),
                  const SizedBox(width: 6),
                  ActionChip(label: Text(school == 0 ? 'SHAFI' : 'HANAFI', style: TextStyle(fontSize: 10.5, color: kSecondary)), backgroundColor: kCard, onPressed: () async { final p = await SharedPreferences.getInstance(); await p.setInt('school', school == 0 ? 1 : 0); _load(); }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual-Pane Hero Card
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
              Text('$salahDone OF 5 COMPLETED • HOLD TIME FOR ALARM', style: TextStyle(fontSize: 10, color: kPrimary, fontWeight: FontWeight.bold)),
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
                      await _syncWidgetAndAlarms();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kSecondary, content: Text('Alarm set for $pr at ${formatClock(t24)}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))));
                      }
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
                        Icon(st > 0 && st < 4 ? Icons.check_circle_outline_rounded : Icons.notifications_active_outlined, size: 16, color: stCols[st]),
                        const SizedBox(height: 6),
                        Text(pr, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: isN ? kPrimary : kText)),
                        const SizedBox(height: 2),
                        Text(formatClock(times[pr]!).split(' ')[0], style: TextStyle(fontSize: 9.5, color: kMuted)),
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

          // Live API Ayah Card with Quran.com Font
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
                const SizedBox(height: 12),
                Text(liveAyahArab, textAlign: TextAlign.right, style: TextStyle(fontSize: 25, fontFamily: 'QuranFont', color: kText, height: 1.8)),
                const SizedBox(height: 10),
                Text(liveAyahTrans, style: TextStyle(fontSize: 13, fontFamily: 'serif', color: kSecondary, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Live API Dua Card with Quran.com Font
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(liveDuaRef.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Text(liveDuaArab, textAlign: TextAlign.right, style: TextStyle(fontSize: 23, fontFamily: 'QuranFont', color: kText, height: 1.8)),
                const SizedBox(height: 8),
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

  final List<Map<String, dynamic>> widThemes = const [
    {'name': 'Pine Emerald', 'c1': Color(0xFF0D2621), 'c2': Color(0xFF060D0B), 'border': Color(0xFF2DD4BF)},
    {'name': 'Obsidian Gold', 'c1': Color(0xFF241A0E), 'c2': Color(0xFF080705), 'border': Color(0xFFD6B36A)},
    {'name': 'Midnight Sapphire', 'c1': Color(0xFF0F1E36), 'c2': Color(0xFF050912), 'border': Color(0xFF38BDF8)},
  ];

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

  Future<void> _saveWidgetCustomization() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('wid_theme', widgetThemeIdx);
    await p.setInt('wid_size', widgetAyahSize);
    await triggerNativeWidgetBroadcast();
  }

  @override
  Widget build(BuildContext context) {
    final th = widThemes[widgetThemeIdx];
    final Color bCol = th['border'] as Color;

    return Scaffold(
      appBar: AppBar(title: Text('$globalUserName\'s Widget Studio'), backgroundColor: kBg),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // NEW: Widget Theme Selector & Ayah Font Size Slider!
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WIDGET THEME & AYAH FONT SIZE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1)),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(widThemes.length, (i) {
                    bool sel = widgetThemeIdx == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () { setState(() => widgetThemeIdx = i); _saveWidgetCustomization(); },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: widThemes[i]['c1'] as Color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? (widThemes[i]['border'] as Color) : Colors.white24, width: sel ? 2 : 1),
                          ),
                          child: Center(child: Text(widThemes[i]['name'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white))),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Arabic Ayah Font Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kText)),
                    Text('${widgetAyahSize}sp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kSecondary)),
                  ],
                ),
                Slider(
                  activeColor: kPrimary,
                  min: 16,
                  max: 30,
                  divisions: 14,
                  value: widgetAyahSize.toDouble(),
                  onChanged: (v) { setState(() => widgetAyahSize = v.toInt()); _saveWidgetCustomization(); },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text('1. DUAL-PANE PRAYER WIDGET', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kSecondary, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [th['c1'] as Color, th['c2'] as Color]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: bCol, width: 1.5),
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
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Text(globalUserName.toUpperCase(), style: TextStyle(color: bCol, fontSize: 8.5, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('NEXT PRAYER', style: TextStyle(color: Color(0xFF8E9E99), fontSize: 9, fontWeight: FontWeight.bold)),
                      Text(nextP, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(nextTime, style: const TextStyle(color: Color(0xFFD6B36A), fontSize: 20, fontFamily: 'serif', fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('REMAINING', style: TextStyle(color: Color(0xFF8E9E99), fontSize: 8.5, fontWeight: FontWeight.bold)),
                            Text(_fmt(remSec), style: TextStyle(color: bCol, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(14)),
                    child: Text(stripText, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold, height: 1.5)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('2. DAILY QURAN VERSE WIDGET (QURAN.COM FONT)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [th['c1'] as Color, th['c2'] as Color]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: bCol, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(liveAyahRef.toUpperCase(), style: const TextStyle(color: Color(0xFFD6B36A), fontSize: 9.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(liveAyahArab, textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: widgetAyahSize.toDouble(), fontFamily: 'QuranFont', height: 1.8)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                  child: Text(liveAyahTrans, style: TextStyle(color: bCol, fontSize: 11.5, fontFamily: 'serif', fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () async {
              await _saveWidgetCustomization();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kSecondary, content: const Text('Widget Theme & Size Applied to Phone Home Screen!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))));
            },
            icon: const Icon(Icons.sync_rounded, color: Colors.black),
            label: const Text('APPLY THEME & SIZE TO HOME SCREEN WIDGET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(side: BorderSide(color: kSecondary), padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () async {
              try { await _widgetChannel.invokeMethod('testNotification', {'prayer': nextP}); } catch (_) {}
            },
            icon: Icon(Icons.notifications_active_outlined, size: 18, color: kSecondary),
            label: Text('TEST PRAYER NOTIFICATION ("May Allah accept your prayers")', style: TextStyle(color: kSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
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






// ---------------- EXTRA ADMIN STATE, READERS & DIRECT SOCIAL REDIRECT SETTINGS ----------------
String adminDevImage = '';
bool adminForceCustomAyah = false;
bool adminForceCustomDua = false;
bool adminMaintenanceMode = false;

// Directly opens Instagram or Facebook App / Browser when user taps handle!
Future<void> openSocialProfile(bool isInstagram, String handleOrUrl) async {
  String clean = handleOrUrl.trim();
  String finalUrl = clean;
  if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
    clean = clean.replaceAll('@', '');
    if (isInstagram) {
      clean = clean.replaceAll('instagram.com/', '').replaceAll('www.instagram.com/', '');
      finalUrl = 'https://www.instagram.com/$clean';
    } else {
      clean = clean.replaceAll('fb.com/', '').replaceAll('facebook.com/', '').replaceAll('www.facebook.com/', '');
      finalUrl = 'https://www.facebook.com/$clean';
    }
  }
  try {
    await _widgetChannel.invokeMethod('openUrl', {'url': finalUrl});
  } catch (_) {}
}

// Fetches live admin_config.json from justRohann18/islamic-app (with zero cache delay!)
Future<void> syncFromGitHubCloudGlobal() async {
  try {
    final p = await SharedPreferences.getInstance();
    adminPinCode = p.getString('adm_pin') ?? adminPinCode;
    adminDevImage = p.getString('adm_dev_img') ?? adminDevImage;
    adminAppInsta = p.getString('adm_app_ig') ?? adminAppInsta;
    adminAppFb = p.getString('adm_app_fb') ?? adminAppFb;
    adminDevInsta = p.getString('adm_dev_ig') ?? adminDevInsta;
    adminDevFb = p.getString('adm_dev_fb') ?? adminDevFb;
    adminDevName = p.getString('adm_dev_n') ?? adminDevName;
    adminDevBio = p.getString('adm_dev_b') ?? adminDevBio;

    final ts = DateTime.now().millisecondsSinceEpoch;
    final urls = [
      'https://api.github.com/repos/justRohann18/islamic-app/contents/admin_config.json?t=$ts',
      'https://raw.githubusercontent.com/justRohann18/islamic-app/main/admin_config.json?t=$ts',
    ];

    for (var u in urls) {
      final r = await http.get(Uri.parse(u), headers: {'Accept': 'application/vnd.github.v3.raw'});
      if (r.statusCode == 200 && r.body.trim().startsWith('{')) {
        final d = json.decode(r.body);
        adminShowBanner = d['show_banner'] ?? adminShowBanner;
        adminBannerTitle = d['banner_title'] ?? adminBannerTitle;
        adminBannerMsg = d['banner_message'] ?? adminBannerMsg;
        adminShowPopup = d['show_popup'] ?? adminShowPopup;
        adminPopupTitle = d['popup_title'] ?? adminPopupTitle;
        adminPopupBody = d['popup_body'] ?? adminPopupBody;
        adminUpdateAvailable = d['update_available'] ?? adminUpdateAvailable;
        adminLatestVer = d['latest_version'] ?? adminLatestVer;
        adminUpdateUrl = d['update_url'] ?? adminUpdateUrl;
        adminAppInsta = d['app_insta'] ?? adminAppInsta;
        adminAppFb = d['app_fb'] ?? adminAppFb;
        adminDevName = d['dev_name'] ?? adminDevName;
        adminDevBio = d['dev_bio'] ?? adminDevBio;
        adminDevImage = d['dev_image'] ?? adminDevImage;
        adminDevInsta = d['dev_insta'] ?? adminDevInsta;
        adminDevFb = d['dev_fb'] ?? adminDevFb;

        await p.setString('adm_dev_n', adminDevName);
        await p.setString('adm_dev_b', adminDevBio);
        await p.setString('adm_dev_img', adminDevImage);
        await p.setString('adm_dev_ig', adminDevInsta);
        await p.setString('adm_dev_fb', adminDevFb);
        await p.setString('adm_app_ig', adminAppInsta);
        await p.setString('adm_app_fb', adminAppFb);
        break;
      }
    }
  } catch (_) {}
}

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
                    Text(ar[i]['text'], textAlign: TextAlign.right, style: TextStyle(fontSize: 26, fontFamily: 'QuranFont', color: kText, height: 1.85)),
                    const SizedBox(height: 10),
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
  @override
  void initState() {
    super.initState();
    syncFromGitHubCloudGlobal().then((_) {
      if (mounted) { setState(() {}); widget.onRebuild(); }
    });
  }

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

  void _openSecretAdminPin() {
    HapticFeedback.heavyImpact();
    final pinC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Owner Command Center', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
        content: TextField(controller: pinC, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Enter Secret PIN')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () {
              if (pinC.text.trim() == adminPinCode) {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboardPage(onRebuild: () { setState(() {}); widget.onRebuild(); })));
              }
            },
            child: const Text('Unlock', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Tapping Instagram or Facebook directly redirects to Instagram/Facebook App!
  Widget _brandBadge(bool isInsta, String handle) {
    return GestureDetector(
      onTap: () => openSocialProfile(isInsta, handle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CustomPaint(painter: SocialLogoPainter(isInstagram: isInsta, color: isInsta ? kPrimary : kSecondary))),
            const SizedBox(width: 7),
            Text(handle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText)),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, size: 11, color: kMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = adminDevImage.trim().startsWith('http');
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        children: [
          GestureDetector(
            onLongPress: _openSecretAdminPin,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kPrimary.withOpacity(0.45))),
              child: Column(
                children: [
                  SizedBox(width: 72, height: 72, child: CustomPaint(painter: SiratLogoPainter())),
                  const SizedBox(height: 12),
                  Text('SIRAT', style: TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.w900, color: kText, letterSpacing: 2.5)),
                  Text('The Straight Path • v1.0.0 Official', style: TextStyle(fontSize: 11, color: kMuted)),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [_brandBadge(true, adminAppInsta), const SizedBox(width: 10), _brandBadge(false, adminAppFb)]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

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
                        Text('User: $globalUserName • Sirat Widgets', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: kText)),
                        Text('Tap to set Username, Widget Theme & Ayah Size', style: TextStyle(fontSize: 11, color: kSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 15, color: kSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

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
                      child: Chip(backgroundColor: (pal['primary'] as Color).withOpacity(0.18), avatar: CircleAvatar(backgroundColor: pal['primary'] as Color), label: Text(pal['name'] as String, style: TextStyle(fontSize: 11, color: kText))),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: kPrimary,
                  backgroundImage: hasPhoto ? NetworkImage(adminDevImage.trim()) : null,
                  child: hasPhoto ? null : const Icon(Icons.person_outline_rounded, size: 36, color: Colors.black),
                ),
                const SizedBox(height: 10),
                Text(adminDevName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                const SizedBox(height: 4),
                Text(adminDevBio, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: kMuted)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [_brandBadge(true, adminDevInsta), const SizedBox(width: 10), _brandBadge(false, adminDevFb)]),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SiratOnboardingFlashcards(onFinish: () => Navigator.pop(context)))),
                  icon: Icon(Icons.style_outlined, size: 15, color: kSecondary),
                  label: Text('Replay Intro Flashcards', style: TextStyle(color: kSecondary, fontSize: 11.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






// ---------------- SUPER-LOADED 8-MODULE OWNER ADMIN COMMAND CENTER ----------------
class AdminDashboardPage extends StatefulWidget {
  final VoidCallback onRebuild;
  const AdminDashboardPage({super.key, required this.onRebuild});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late TextEditingController pinC, banTC, banMC, popTC, popBC, updVC, updUC;
  late TextEditingController ayRefC, ayArC, ayTrC, duRefC, duArC, duTrC;
  late TextEditingController defCityC, devNC, devBC, devImgC, devIgC, devFbC, appIgC, appFbC;
  bool sBan = adminShowBanner, sPop = adminShowPopup, sUpd = adminUpdateAvailable;
  bool fAyah = adminForceCustomAyah, fDua = adminForceCustomDua, mLock = adminMaintenanceMode;
  int defSchool = 0, defWidTheme = widgetThemeIdx, defWidSize = widgetAyahSize;

  @override
  void initState() {
    super.initState();
    pinC = TextEditingController(text: adminPinCode);
    banTC = TextEditingController(text: adminBannerTitle);
    banMC = TextEditingController(text: adminBannerMsg);
    popTC = TextEditingController(text: adminPopupTitle);
    popBC = TextEditingController(text: adminPopupBody);
    updVC = TextEditingController(text: adminLatestVer);
    updUC = TextEditingController(text: adminUpdateUrl);
    ayRefC = TextEditingController(text: liveAyahRef);
    ayArC = TextEditingController(text: liveAyahArab);
    ayTrC = TextEditingController(text: liveAyahTrans);
    duRefC = TextEditingController(text: liveDuaRef);
    duArC = TextEditingController(text: liveDuaArab);
    duTrC = TextEditingController(text: liveDuaTrans);
    defCityC = TextEditingController(text: 'Barpaka');
    devNC = TextEditingController(text: adminDevName);
    devBC = TextEditingController(text: adminDevBio);
    devImgC = TextEditingController(text: adminDevImage);
    devIgC = TextEditingController(text: adminDevInsta);
    devFbC = TextEditingController(text: adminDevFb);
    appIgC = TextEditingController(text: adminAppInsta);
    appFbC = TextEditingController(text: adminAppFb);
  }

  Future<void> _saveAndExportAll() async {
    final p = await SharedPreferences.getInstance();
    adminPinCode = pinC.text.trim().isEmpty ? '7860' : pinC.text.trim();
    adminShowBanner = sBan;
    adminBannerTitle = banTC.text.trim();
    adminBannerMsg = banMC.text.trim();
    adminShowPopup = sPop;
    adminPopupTitle = popTC.text.trim();
    adminPopupBody = popBC.text.trim();
    adminUpdateAvailable = sUpd;
    adminLatestVer = updVC.text.trim();
    adminUpdateUrl = updUC.text.trim();
    adminMaintenanceMode = mLock;
    adminForceCustomAyah = fAyah;
    adminForceCustomDua = fDua;
    widgetThemeIdx = defWidTheme;
    widgetAyahSize = defWidSize;

    if (fAyah) {
      liveAyahRef = ayRefC.text.trim();
      liveAyahArab = ayArC.text.trim();
      liveAyahTrans = ayTrC.text.trim();
    }
    if (fDua) {
      liveDuaRef = duRefC.text.trim();
      liveDuaArab = duArC.text.trim();
      liveDuaTrans = duTrC.text.trim();
    }

    adminDevName = devNC.text.trim();
    adminDevBio = devBC.text.trim();
    adminDevImage = devImgC.text.trim();
    adminDevInsta = devIgC.text.trim();
    adminDevFb = devFbC.text.trim();
    adminAppInsta = appIgC.text.trim();
    adminAppFb = appFbC.text.trim();

    await p.setString('adm_pin', adminPinCode);
    await p.setBool('adm_show_ban', adminShowBanner);
    await p.setString('adm_ban_t', adminBannerTitle);
    await p.setString('adm_ban_m', adminBannerMsg);
    await p.setBool('adm_show_pop', adminShowPopup);
    await p.setString('adm_pop_t', adminPopupTitle);
    await p.setString('adm_pop_b', adminPopupBody);
    await p.setBool('adm_upd_on', adminUpdateAvailable);
    await p.setString('adm_upd_v', adminLatestVer);
    await p.setString('adm_upd_u', adminUpdateUrl);
    await p.setInt('wid_theme', widgetThemeIdx);
    await p.setInt('wid_size', widgetAyahSize);
    await p.setInt('school', defSchool);
    if (defCityC.text.trim().isNotEmpty) await p.setString('loc', defCityC.text.trim());
    await p.setString('wq_ref', liveAyahRef.toUpperCase());
    await p.setString('wq_arab', liveAyahArab);
    await p.setString('wq_hing', liveAyahTrans);
    await p.setString('adm_dev_n', adminDevName);
    await p.setString('adm_dev_b', adminDevBio);
    await p.setString('adm_dev_img', adminDevImage);
    await p.setString('adm_dev_ig', adminDevInsta);
    await p.setString('adm_dev_fb', adminDevFb);
    await p.setString('adm_app_ig', adminAppInsta);
    await p.setString('adm_app_fb', adminAppFb);

    final cloudJson = const JsonEncoder.withIndent('  ').convert({
      'show_banner': adminShowBanner,
      'banner_title': adminBannerTitle,
      'banner_message': adminBannerMsg,
      'show_popup': adminShowPopup,
      'popup_title': adminPopupTitle,
      'popup_body': adminPopupBody,
      'update_available': adminUpdateAvailable,
      'latest_version': adminLatestVer,
      'update_url': adminUpdateUrl,
      'force_custom_ayah': adminForceCustomAyah,
      'custom_ayah_ref': liveAyahRef,
      'custom_ayah_arab': liveAyahArab,
      'custom_ayah_trans': liveAyahTrans,
      'force_custom_dua': adminForceCustomDua,
      'custom_dua_ref': liveDuaRef,
      'custom_dua_arab': liveDuaArab,
      'custom_dua_trans': liveDuaTrans,
      'app_insta': adminAppInsta,
      'app_fb': adminAppFb,
      'dev_name': adminDevName,
      'dev_bio': adminDevBio,
      'dev_image': adminDevImage,
      'dev_insta': adminDevInsta,
      'dev_fb': adminDevFb,
    });
    Clipboard.setData(ClipboardData(text: cloudJson));
    await triggerNativeWidgetBroadcast();
    widget.onRebuild();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kSecondary, content: const Text('Saved & Cloud JSON Copied! Paste in admin_config.json on GitHub!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))));
      Navigator.pop(context);
    }
  }

  Widget _hdr(String t) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 1)));
  Widget _inp(TextEditingController c, String l) => Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(controller: c, decoration: InputDecoration(labelText: l, filled: true, fillColor: kCard, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sirat Master Command Center'),
        backgroundColor: kBg,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active_outlined, color: kSecondary),
            tooltip: 'Test Prayer Notification',
            onPressed: () async { try { await _widgetChannel.invokeMethod('testNotification', {'prayer': 'Fajr'}); } catch (_) {} },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _hdr('1. SECURITY & ACCESS PIN'),
          _inp(pinC, 'Secret Admin PIN (Default: 7860)'),

          _hdr('2. HOME ANNOUNCEMENT BANNER'),
          SwitchListTile(title: const Text('Enable Top Home Banner'), activeColor: kPrimary, value: sBan, onChanged: (v) => setState(() => sBan = v)),
          _inp(banTC, 'Banner Heading'),
          _inp(banMC, 'Banner Description'),

          _hdr('3. STARTUP BROADCAST POPUP DIALOG'),
          SwitchListTile(title: const Text('Show Popup Alert on App Launch'), activeColor: kPrimary, value: sPop, onChanged: (v) => setState(() => sPop = v)),
          _inp(popTC, 'Popup Title'),
          _inp(popBC, 'Popup Message Body'),

          _hdr('4. OTA APP UPDATE PUSHER & MAINTENANCE'),
          SwitchListTile(title: const Text('Show "New Update Live" Banner'), activeColor: kSecondary, value: sUpd, onChanged: (v) => setState(() => sUpd = v)),
          _inp(updVC, 'New Version Label (e.g. v2.0.0 Pro)'),
          _inp(updUC, 'Direct APK Download Link (GitHub Release URL)'),
          SwitchListTile(title: const Text('Maintenance Mode Lock'), activeColor: Colors.redAccent, value: mLock, onChanged: (v) => setState(() => mLock = v)),

          _hdr('5. CUSTOM DAILY AYAH & WIDGET OVERRIDE'),
          SwitchListTile(title: const Text('Force Custom Ayah instead of Auto API'), activeColor: kPrimary, value: fAyah, onChanged: (v) => setState(() => fAyah = v)),
          _inp(ayRefC, 'Custom Ayah Reference (e.g. Surah Al-Baqarah 2:152)'),
          _inp(ayArC, 'Custom Arabic Verse'),
          _inp(ayTrC, 'Custom Verse Translation'),

          _hdr('6. CUSTOM DAILY DUA OVERRIDE'),
          SwitchListTile(title: const Text('Force Custom Daily Dua'), activeColor: kSecondary, value: fDua, onChanged: (v) => setState(() => fDua = v)),
          _inp(duRefC, 'Custom Dua Reference'),
          _inp(duArC, 'Custom Dua Arabic'),
          _inp(duTrC, 'Custom Dua Translation'),

          _hdr('7. GLOBAL PRAYER, WIDGET & THEME DEFAULTS'),
          _inp(defCityC, 'Default City / Town Name'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Default Fiqh School:'),
              ChoiceChip(label: const Text('Shafi\'i'), selected: defSchool == 0, onSelected: (_) => setState(() => defSchool = 0)),
              ChoiceChip(label: const Text('Hanafi'), selected: defSchool == 1, onSelected: (_) => setState(() => defSchool = 1)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Widget Theme:'),
              ChoiceChip(label: const Text('Emerald'), selected: defWidTheme == 0, onSelected: (_) => setState(() => defWidTheme = 0)),
              ChoiceChip(label: const Text('Gold'), selected: defWidTheme == 1, onSelected: (_) => setState(() => defWidTheme = 1)),
              ChoiceChip(label: const Text('Sapphire'), selected: defWidTheme == 2, onSelected: (_) => setState(() => defWidTheme = 2)),
            ],
          ),
          Slider(
            activeColor: kPrimary,
            min: 16,
            max: 30,
            divisions: 14,
            label: '${defWidSize}sp',
            value: defWidSize.toDouble(),
            onChanged: (v) => setState(() => defWidSize = v.toInt()),
          ),

          _hdr('8. DEVELOPER PHOTO, BIO & SOCIAL HANDLES'),
          _inp(devImgC, 'Developer Photo URL (https://...)'),
          _inp(devNC, 'Developer Name'),
          _inp(devBC, 'Developer Bio / About'),
          _inp(devIgC, 'Developer Instagram Handle'),
          _inp(devFbC, 'Developer Facebook Link'),
          _inp(appIgC, 'App Official Instagram Handle'),
          _inp(appFbC, 'App Official Facebook Link'),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _saveAndExportAll,
            icon: const Icon(Icons.cloud_upload_outlined, color: Colors.black),
            label: const Text('SAVE ALL & COPY CLOUD JSON FOR ALL USERS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('sirat_onboarded', false);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kSecondary, content: const Text('Onboarding Reset! Restart app to view Intro Flashcards.', style: TextStyle(color: Colors.black))));
            },
            icon: Icon(Icons.refresh_rounded, color: kSecondary),
            label: Text('Reset First-Time Onboarding Flashcards', style: TextStyle(color: kSecondary)),
          ),
        ],
      ),
    );
  }
}


