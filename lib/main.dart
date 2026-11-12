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
const String kInstalledVersion = 'v2.0.0';

bool isDarkMode = true;
int accentIndex = 0;
String appLang = 'en';
bool use12Hour = true;
String globalUserName = 'Mumin';
int widgetThemeIdx = 0;
int widgetAyahSize = 22;

bool adminShowBanner = true;
String adminBannerTitle = 'Sirat v2.0 Official';
String adminBannerMsg = 'Recite Surah Al-Mulk before sleeping and track your five daily prayers.';
bool adminUpdateAvailable = false;
String adminLatestVer = 'v2.0.0';
String adminUpdateUrl = 'https://github.com/justRohann18/islamic-app/releases';
String adminChangelog = '• Added Multi-Qari Quran Audio (Alafasy, Imam Sudais, Al-Husary)\n• Added Automatic Last-Read Surah Bookmark\n• Added Sunnah Fasting (Roza) Tracker on Home\n• Added Custom Widget Themes & Ayah Font Size Slider';

String adminAppInsta = '@app_sirat';
String adminAppFb = 'https://www.facebook.com/share/1Bz6Qs6BKV/';
String adminDevName = 'Jahidul Hassan';
String adminDevBio = 'Building modern, ad-free and authentic Islamic digital experiences as Sadaqah Jariyah.';
String adminDevInsta = '@just.jahidulx';
String adminDevFb = 'https://www.facebook.com/share/1Bz6Qs6BKV/';
String adminDevImage = 'https://instasize.com/api/image/f82d477b378ee650f67b95f504fcdec6c2b01ca112ac64faa0d4aef2766656ec.jpeg';

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

Future<void> openSocialProfile(bool isInstagram, String handleOrUrl) async {
  String clean = handleOrUrl.trim();
  String finalUrl = clean;
  if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
    clean = clean.replaceAll('@', '');
    finalUrl = isInstagram ? 'https://www.instagram.com/$clean/' : 'https://www.facebook.com/$clean';
  }
  try { await _widgetChannel.invokeMethod('openUrl', {'url': finalUrl}); } catch (_) {}
}

Future<void> syncFromGitHubCloudGlobal() async {
  try {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final r = await http.get(Uri.parse('https://api.github.com/repos/justRohann18/islamic-app/contents/admin_config.json?t=$ts'), headers: {'Accept': 'application/vnd.github.v3.raw'});
    if (r.statusCode == 200 && r.body.trim().startsWith('{')) {
      final d = json.decode(r.body);
      adminShowBanner = d['show_banner'] ?? adminShowBanner;
      adminBannerTitle = d['banner_title'] ?? adminBannerTitle;
      adminBannerMsg = d['banner_message'] ?? adminBannerMsg;
      adminUpdateAvailable = d['update_available'] ?? adminUpdateAvailable;
      adminLatestVer = d['latest_version'] ?? adminLatestVer;
      adminUpdateUrl = d['update_url'] ?? adminUpdateUrl;
      adminChangelog = d['changelog'] ?? adminChangelog;
      adminAppInsta = d['app_insta'] ?? adminAppInsta;
      adminAppFb = d['app_fb'] ?? adminAppFb;
      adminDevName = d['dev_name'] ?? adminDevName;
      adminDevBio = d['dev_bio'] ?? adminDevBio;
      adminDevImage = d['dev_image'] ?? adminDevImage;
      adminDevInsta = d['dev_insta'] ?? adminDevInsta;
      adminDevFb = d['dev_fb'] ?? adminDevFb;
    }
  } catch (_) {}
}

void showWhatsNewUpdateModal(BuildContext context) {
  final lines = adminChangelog.split('\n').where((s) => s.trim().isNotEmpty).toList();
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: BorderSide(color: kPrimary, width: 1.6)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WHAT\'S NEW', style: TextStyle(fontSize: 19, fontFamily: 'serif', fontWeight: FontWeight.w900, color: kText, letterSpacing: 1)),
                    Text('Sirat Update • $adminLatestVer', style: TextStyle(fontSize: 11.5, color: kSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: Icon(Icons.close_rounded, color: kMuted, size: 20), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Divider(color: kBorder, height: 22),
            ...lines.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 15, color: kSecondary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.replaceAll('•', '').trim(), style: TextStyle(fontSize: 13, color: kText, height: 1.35))),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  Navigator.pop(ctx);
                  openSocialProfile(false, adminUpdateUrl);
                },
                icon: const Icon(Icons.download_rounded, color: Colors.black, size: 19),
                label: const Text('UPDATE NOW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SiratLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bgRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(w * 0.26));
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF071713));
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFFD6B36A)..style = PaintingStyle.stroke..strokeWidth = 2.2);
    final arch = Path()..moveTo(w * 0.22, h * 0.85)..lineTo(w * 0.22, h * 0.45)..quadraticBezierTo(w * 0.22, h * 0.18, w * 0.5, h * 0.12)..quadraticBezierTo(w * 0.78, h * 0.18, w * 0.78, h * 0.45)..lineTo(w * 0.78, h * 0.85)..close();
    canvas.drawPath(arch, Paint()..color = const Color(0xFFD6B36A)..style = PaintingStyle.stroke..strokeWidth = 2.0);
    final path = Path()..moveTo(w * 0.36, h * 0.85)..lineTo(w * 0.47, h * 0.38)..lineTo(w * 0.53, h * 0.38)..lineTo(w * 0.64, h * 0.85)..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF2DD4BF));
    final star = Path()..moveTo(w * 0.5, h * 0.19)..lineTo(w * 0.53, h * 0.26)..lineTo(w * 0.60, h * 0.29)..lineTo(w * 0.53, h * 0.32)..lineTo(w * 0.5, h * 0.39)..lineTo(w * 0.47, h * 0.32)..lineTo(w * 0.40, h * 0.29)..lineTo(w * 0.47, h * 0.26)..close();
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
    await syncFromGitHubCloudGlobal();
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    String ed = appLang == 'hi' ? 'hi.hindi' : (appLang == 'ur' ? 'ur.jalandhry' : 'en.asad');
    int ayahNum = forceRandom ? (math.Random().nextInt(6200) + 10) : ((dayOfYear * 37 + now.year) % 6220) + 7;

    final r = await http.get(Uri.parse('https://api.alquran.cloud/v1/ayah/$ayahNum/editions/ar.alafasy,$ed'));
    if (r.statusCode == 200) {
      final d = json.decode(r.body)['data'];
      liveAyahArab = d[0]['text'];
      liveAyahTrans = '"${d[1]['text']}"';
      liveAyahRef = '${d[0]['surah']['englishName']} • ${d[0]['surah']['number']}:${d[0]['numberInSurah']}';
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
      theme: ThemeData(brightness: isDarkMode ? Brightness.dark : Brightness.light, scaffoldBackgroundColor: kBg, primaryColor: kPrimary, cardColor: kCard),
      home: showOnboarding ? SiratOnboardingFlashcards(onFinish: () => setState(() => showOnboarding = false)) : MainShell(onAppRebuild: () => setState(() {})),
    );
  }
}

class SiratOnboardingFlashcards extends StatefulWidget {
  final VoidCallback onFinish;
  const SiratOnboardingFlashcards({super.key, required this.onFinish});
  @override
  State<SiratOnboardingFlashcards> createState() => _SiratOnboardingFlashcardsState();
}

class _SiratOnboardingFlashcardsState extends State<SiratOnboardingFlashcards> {
  final PageController _pc = PageController();
  int page = 0;
  final nameC = TextEditingController(text: 'Mumin'), cityC = TextEditingController(text: 'Barpaka');

  final List<Map<String, dynamic>> cards = const [
    {'tag': 'WELCOME TO SIRAT', 'title': 'Your Companion on\nthe Straight Path', 'sub': 'An architectural, ad-free Islamic ecosystem crafted for daily Salah discipline, Quranic reflection, and authentic Sunnah.', 'ic': Icons.mosque_outlined},
    {'tag': 'PRECISION SALAH & ALARMS', 'title': 'Dual-Pane Live Timer\n& Prayer Alerts', 'sub': 'Track your 5 daily prayers in Jamaat or On-Time. Hold any prayer time to set your local Masjid schedule and receive exact prayer notifications.', 'ic': Icons.notifications_active_outlined},
    {'tag': 'QURAN.COM SCRIPT & HADITH', 'title': '114 Surahs & 36,000+\nAuthentic Hadiths', 'sub': 'Read the Noble Quran in authentic Uthmani calligraphy with Multi-Qari audio recitation, and search globally across 10 major Hadith collections.', 'ic': Icons.menu_book_rounded},
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
                  Row(children: List.generate(4, (i) => Container(width: page == i ? 22 : 7, height: 7, margin: const EdgeInsets.only(left: 5), decoration: BoxDecoration(color: page == i ? kPrimary : kBorder, borderRadius: BorderRadius.circular(6))))),
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(28), border: Border.all(color: kPrimary.withOpacity(0.45), width: 1.5)),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (i == 0) Center(child: SizedBox(width: 80, height: 80, child: CustomPaint(painter: SiratLogoPainter())))
                            else Icon(c['ic'] as IconData, size: 40, color: kPrimary),
                            const SizedBox(height: 20),
                            Text(c['tag'] as String, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kSecondary)),
                            const SizedBox(height: 8),
                            Text(c['title'] as String, style: TextStyle(fontSize: 24, fontFamily: 'serif', fontWeight: FontWeight.bold, color: kText)),
                            const SizedBox(height: 12),
                            Text(c['sub'] as String, style: TextStyle(fontSize: 13.5, color: kMuted, height: 1.5)),
                            if (i == 3) ...[
                              const SizedBox(height: 16),
                              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Your Name')),
                              TextField(controller: cityC, decoration: const InputDecoration(labelText: 'Your City / Town')),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: () async {
                    if (page < 3) { _pc.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut); }
                    else {
                      final p = await SharedPreferences.getInstance();
                      await p.setBool('sirat_onboarded', true);
                      if (nameC.text.trim().isNotEmpty) { globalUserName = nameC.text.trim(); await p.setString('user_name', globalUserName); }
                      if (cityC.text.trim().isNotEmpty) { await p.setString('loc', cityC.text.trim()); }
                      widget.onFinish();
                    }
                  },
                  child: Text(page < 3 ? 'NEXT FLASHCARD' : 'BEGIN MY SIRAT JOURNEY', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
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
  bool updateDialogShown = false;
  void _nav(int i, {int sub = 0}) => setState(() { idx = i; kitSub = sub; });

  @override
  Widget build(BuildContext context) {
    if (adminUpdateAvailable && !updateDialogShown) {
      updateDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => showWhatsNewUpdateModal(context));
    }
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
        child: Row(children: [Icon(ic, size: 19, color: sel ? Colors.black : kMuted), if (sel) ...[const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800))]]),
      ),
    );
  }
}












// ---------------- HOME, WIDGET STUDIO, STREAK, KITAB (MULTI-QARI) & CLEAN SETTINGS ----------------
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
  bool manual = false, isFastingToday = false;
  Timer? timer;
  String nextP = 'Dhuhr', countdown = '-02:14:30';
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
    if (mounted) setState(() { nextP = found; countdown = '-${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}'; });
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final tKey = getDateKey(DateTime.now());
    setState(() {
      loc = p.getString('loc') ?? 'Barpaka';
      school = p.getInt('school') ?? 0;
      manual = p.getBool('manual') ?? false;
      isFastingToday = p.getBool('fast_$tKey') ?? false;
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
          if (adminShowBanner)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.14), borderRadius: BorderRadius.circular(16), border: Border.all(color: kPrimary.withOpacity(0.5))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(adminBannerTitle, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: kPrimary)), Text(adminBannerMsg, style: TextStyle(fontSize: 11.5, color: kText))]),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(loc.toUpperCase(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kText)), Text('$hijri • $globalUserName', style: TextStyle(fontSize: 11, color: kMuted))]),
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
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0D2621), Color(0xFF060D0B)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: kSecondary.withOpacity(0.55), width: 1.5)),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NEXT PRAYER', style: TextStyle(color: kMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                      Text(nextP, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      Text(formatClock(times[nextP]!), style: TextStyle(color: kPrimary, fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('REMAINING  $countdown', style: TextStyle(color: kSecondary, fontSize: 12, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: prayers.map((p) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p, style: const TextStyle(fontSize: 11, color: Colors.white70)), Text(formatClock(times[p]!).split(' ')[0], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: p == nextP ? kPrimary : Colors.white))])).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('DAILY SALAH ($salahDone/5) • HOLD TIME FOR ALARM', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary)),
          const SizedBox(height: 8),
          Row(
            children: prayers.map((pr) {
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
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: st > 0 ? stCols[st] : kBorder)),
                    child: Column(children: [Text(pr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText)), const SizedBox(height: 4), Text(stTags[st], style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: stCols[st]))]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final p = await SharedPreferences.getInstance();
              final tKey = getDateKey(DateTime.now());
              setState(() => isFastingToday = !isFastingToday);
              await p.setBool('fast_$tKey', isFastingToday);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: isFastingToday ? kSecondary.withOpacity(0.16) : kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: isFastingToday ? kSecondary : kBorder)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SUNNAH & FARZ FASTING (ROZA) TRACKER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kText)),
                  Text(isFastingToday ? 'FASTING TODAY' : 'LOG ROZA +', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('VERSE OF THE DAY • $liveAyahRef', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kPrimary)),
                    GestureDetector(onTap: () async { await fetchLiveDailyAyahAndDua(forceRandom: true); if (mounted) setState(() {}); }, child: Icon(Icons.refresh_rounded, size: 18, color: kPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(liveAyahArab, textAlign: TextAlign.right, style: TextStyle(fontSize: 25, fontFamily: 'QuranFont', color: kText, height: 1.8)),
                const SizedBox(height: 8),
                Text(liveAyahTrans, style: TextStyle(fontSize: 13, fontFamily: 'serif', color: kSecondary, fontStyle: FontStyle.italic)),
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
  final List<Map<String, dynamic>> widThemes = const [
    {'name': 'Pine Emerald', 'c1': Color(0xFF0D2621), 'c2': Color(0xFF060D0B), 'border': Color(0xFF2DD4BF)},
    {'name': 'Obsidian Gold', 'c1': Color(0xFF241A0E), 'c2': Color(0xFF080705), 'border': Color(0xFFD6B36A)},
    {'name': 'Midnight Sapphire', 'c1': Color(0xFF0F1E36), 'c2': Color(0xFF050912), 'border': Color(0xFF38BDF8)},
  ];

  Future<void> _saveWid() async {
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WIDGET THEME & AYAH FONT SIZE (${widgetAyahSize}sp)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(widThemes.length, (i) => Expanded(
                    child: GestureDetector(
                      onTap: () { setState(() => widgetThemeIdx = i); _saveWid(); },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(color: widThemes[i]['c1'] as Color, borderRadius: BorderRadius.circular(10), border: Border.all(color: widgetThemeIdx == i ? bCol : Colors.white24)),
                        child: Center(child: Text(widThemes[i]['name'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                      ),
                    ),
                  )),
                ),
                Slider(activeColor: kPrimary, min: 16, max: 30, divisions: 14, value: widgetAyahSize.toDouble(), onChanged: (v) { setState(() => widgetAyahSize = v.toInt()); _saveWid(); }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [th['c1'] as Color, th['c2'] as Color]), borderRadius: BorderRadius.circular(24), border: Border.all(color: bCol, width: 1.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(liveAyahRef.toUpperCase(), style: const TextStyle(color: Color(0xFFD6B36A), fontSize: 9.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(liveAyahArab, textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: widgetAyahSize.toDouble(), fontFamily: 'QuranFont', height: 1.8)),
                const SizedBox(height: 8),
                Text(liveAyahTrans, style: TextStyle(color: bCol, fontSize: 11.5, fontFamily: 'serif', fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _saveWid,
            icon: const Icon(Icons.sync_rounded, color: Colors.black),
            label: const Text('APPLY TO HOME SCREEN WIDGET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

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
    int mAda = 0, mJamaat = 0, fastDays = 0;
    for (int i = 1; i <= daysInM; i++) {
      final dt = DateTime(now.year, now.month, i);
      if (prefs?.getBool('fast_${getDateKey(dt)}') ?? false) fastDays++;
      for (var p in prayers) {
        int s = _st(dt, p);
        if (s > 0 && s < 4) mAda++;
        if (s == 1) mJamaat++;
      }
    }
    int passedDays = math.max(1, now.day);
    double scorePct = ((mAda / (passedDays * 5)) * 100).clamp(0.0, 100.0);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          Text('SPIRITUAL ANALYTICS & STREAK', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kPrimary.withOpacity(0.45))),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(value: scorePct / 100, strokeWidth: 8, backgroundColor: kBg, valueColor: AlwaysStoppedAnimation(kSecondary)),
                      Center(child: Text('${scorePct.toInt()}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text('$mAda Prayers Offered\n$mJamaat in Jamaat • $fastDays Fasted Days', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: kText, height: 1.5))),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
  bool loadingQuran = true;
  String qSearch = '', globalHadithQuery = '';
  int lastSurahNum = 1;
  String lastSurahName = 'Al-Faatiha';
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
    _loadBookmark();
    http.get(Uri.parse('https://api.alquran.cloud/v1/surah')).then((r) {
      if (r.statusCode == 200 && mounted) setState(() { surahs = json.decode(r.body)['data']; loadingQuran = false; });
    });
    _preloadHadiths();
  }

  Future<void> _loadBookmark() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() { lastSurahNum = p.getInt('last_surah_num') ?? 1; lastSurahName = p.getString('last_surah_name') ?? 'Al-Faatiha'; });
  }

  Future<void> _preloadHadiths() async {
    try {
      for (var src in [
        {'b': 'An-Nawawi 40', 'url': 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-nawawi.min.json'},
        {'b': 'Sahih Bukhari', 'url': 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-bukhari.min.json'},
      ]) {
        final r = await http.get(Uri.parse(src['url']!));
        if (r.statusCode == 200) {
          for (var h in (json.decode(r.body)['hadiths'] ?? [])) {
            final t = h['text']?.toString() ?? '';
            if (t.isNotEmpty) globalHadithPool.add({'book': src['b']!, 'num': h['hadithnumber']?.toString() ?? '', 'en': t});
          }
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final fS = surahs.where((s) => s['englishName'].toString().toLowerCase().contains(qSearch.toLowerCase()) || s['number'].toString().contains(qSearch)).toList();
    final bool isSearchingH = globalHadithQuery.trim().isNotEmpty;
    final hResults = isSearchingH
        ? globalHadithPool.where((h) => h['en']!.toLowerCase().contains(globalHadithQuery.toLowerCase()) || h['num']!.contains(globalHadithQuery)).take(120).toList()
        : <Map<String, String>>[];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 85),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: tab == 0 ? kPrimary : kCard), onPressed: () => setState(() => tab = 0), child: Text('AL-QURAN (114)', style: TextStyle(color: tab == 0 ? Colors.black : kText, fontWeight: FontWeight.bold, fontSize: 11)))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: tab == 1 ? kPrimary : kCard), onPressed: () => setState(() => tab = 1), child: Text('10 HADITH BOOKS', style: TextStyle(color: tab == 1 ? Colors.black : kText, fontWeight: FontWeight.bold, fontSize: 11)))),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tab == 0
                  ? Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReaderPage(num: lastSurahNum, name: lastSurahName)));
                            _loadBookmark();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: kPrimary.withOpacity(0.5))),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CONTINUE READING • SURAH ${lastSurahName.toUpperCase()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary)), Icon(Icons.arrow_forward_ios_rounded, size: 13, color: kPrimary)]),
                          ),
                        ),
                        TextField(onChanged: (v) => setState(() => qSearch = v), decoration: InputDecoration(hintText: 'Search Surah...', prefixIcon: Icon(Icons.search, color: kPrimary), filled: true, fillColor: kCard, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                        const SizedBox(height: 10),
                        Expanded(
                          child: loadingQuran
                              ? Center(child: CircularProgressIndicator(color: kPrimary))
                              : ListView.builder(
                                  itemCount: fS.length,
                                  itemBuilder: (_, i) => ListTile(
                                    leading: Text('${fS[i]['number']}', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                                    title: Text(fS[i]['englishName'], style: TextStyle(fontWeight: FontWeight.bold, color: kText)),
                                    trailing: Text(fS[i]['name'], style: TextStyle(fontSize: 20, fontFamily: 'QuranFont', color: kPrimary)),
                                    onTap: () async {
                                      final p = await SharedPreferences.getInstance();
                                      await p.setInt('last_surah_num', fS[i]['number']);
                                      await p.setString('last_surah_name', fS[i]['englishName']);
                                      if (mounted) {
                                        await Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReaderPage(num: fS[i]['number'], name: fS[i]['englishName'])));
                                        _loadBookmark();
                                      }
                                    },
                                  ),
                                ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(onChanged: (v) => setState(() => globalHadithQuery = v), decoration: InputDecoration(hintText: 'Search across ${globalHadithPool.length}+ Hadiths...', prefixIcon: Icon(Icons.search_rounded, color: kPrimary), filled: true, fillColor: kCard, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                        const SizedBox(height: 12),
                        Expanded(
                          child: isSearchingH
                              ? ListView.builder(
                                  itemCount: hResults.length,
                                  itemBuilder: (_, i) {
                                    final h = hResults[i];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kPrimary.withOpacity(0.4))),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${h['book']} • #${h['num']}', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)), const SizedBox(height: 6), Text(h['en']!, style: TextStyle(fontSize: 13.5, color: kText))]),
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
                                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(b['ic'] as IconData, color: c, size: 24), Text(b['count'] as String, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 12))]),
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hadith #${h['hadithnumber']}', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 6), Text(txt, style: TextStyle(color: kText, fontSize: 14, height: 1.5))]),
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
  String qariCode = 'ar.alafasy';
  final player = AudioPlayer();
  int? playingIdx;

  final List<Map<String, String>> qaris = const [
    {'id': 'ar.alafasy', 'name': 'Alafasy'},
    {'id': 'ar.abdurrahmaansudais', 'name': 'Imam Sudais'},
    {'id': 'ar.husary', 'name': 'Al-Husary'},
  ];

  @override
  void initState() { super.initState(); _loadSurah(); }

  Future<void> _loadSurah() async {
    setState(() => loading = true);
    String ed = appLang == 'hi' ? 'hi.hindi' : (appLang == 'ur' ? 'ur.jalandhry' : 'en.asad');
    final r = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah/${widget.num}/editions/$qariCode,$ed'));
    if (r.statusCode == 200 && mounted) {
      final d = json.decode(r.body)['data'];
      setState(() { ar = d[0]['ayahs']; tr = d[1]['ayahs']; loading = false; });
    }
  }

  @override
  void dispose() { player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: kBg,
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: qariCode,
              dropdownColor: kCard,
              items: qaris.map((q) => DropdownMenuItem(value: q['id'], child: Text(q['name']!, style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.bold)))).toList(),
              onChanged: (v) { if (v != null) { player.stop(); setState(() { qariCode = v; playingIdx = null; }); _loadSurah(); } },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
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

  Widget _brandBadge(bool isInsta, String handleOrUrl, String displayLabel) {
    return GestureDetector(
      onTap: () => openSocialProfile(isInsta, handleOrUrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CustomPaint(painter: SocialLogoPainter(isInstagram: isInsta, color: isInsta ? kPrimary : kSecondary))),
            const SizedBox(width: 7),
            Text(displayLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText)),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, size: 11, color: kMuted),
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
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kPrimary.withOpacity(0.45))),
            child: Column(
              children: [
                SizedBox(width: 72, height: 72, child: CustomPaint(painter: SiratLogoPainter())),
                const SizedBox(height: 12),
                Text('SIRAT', style: TextStyle(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.w900, color: kText, letterSpacing: 2.5)),
                Text('The Straight Path • $kInstalledVersion Official', style: TextStyle(fontSize: 11, color: kMuted)),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [_brandBadge(true, adminAppInsta, '@app_sirat'), const SizedBox(width: 10), _brandBadge(false, adminAppFb, 'Facebook')]),
              ],
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
                Text('LANGUAGE & THEME COLOUR', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kPrimary)),
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
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
                      child: Chip(backgroundColor: (pal['primary'] as Color).withOpacity(0.18), avatar: CircleAvatar(backgroundColor: pal['primary'] as Color), label: Text(pal['name'] as String, style: TextStyle(fontSize: 10.5, color: kText))),
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
                CircleAvatar(radius: 40, backgroundColor: kPrimary, backgroundImage: NetworkImage(adminDevImage)),
                const SizedBox(height: 10),
                Text(adminDevName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kText)),
                const SizedBox(height: 4),
                Text(adminDevBio, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: kMuted)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [_brandBadge(true, adminDevInsta, '@just.jahidulx'), const SizedBox(width: 10), _brandBadge(false, adminDevFb, 'Facebook')]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SiratOnboardingFlashcards(onFinish: () => Navigator.pop(context)))),
                      icon: Icon(Icons.style_outlined, size: 15, color: kSecondary),
                      label: Text('Intro Flashcards', style: TextStyle(color: kSecondary, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => showWhatsNewUpdateModal(context),
                      icon: Icon(Icons.system_update_rounded, size: 15, color: kPrimary),
                      label: Text('What\'s New', style: TextStyle(color: kPrimary, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



