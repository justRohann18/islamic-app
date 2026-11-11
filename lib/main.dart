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
String adminBannerTitle = '🌙 Noor Official Reminder';
String adminBannerMsg = 'Recite Surah Al-Mulk before sleeping & track your 5 daily prayers!';
bool adminShowPopup = false;
String adminPopupTitle = '✨ Special Islamic Broadcast';
String adminPopupBody = 'Assalamu Alaikum! May Allah accept your prayers and good deeds today.';
bool adminUpdateAvailable = false;
String adminLatestVer = 'v12.0 Pro';
String adminUpdateUrl = 'https://github.com/';

String adminAppInsta = '@noor.islamic.app';
String adminAppFb = 'fb.com/NoorIslamicApp';
String adminDevName = 'Lead Creator & Developer';
String adminDevBio = 'Building modern, ad-free & authentic Islamic digital experiences as Sadaqah Jariyah.';
String adminDevImage = '';
String adminDevInsta = '@developer.noor';
String adminDevFb = 'fb.com/developer.noor';

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

String liveDuaRef = 'Quranic Dua • 2:201';
String liveDuaArab = 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ';
String liveDuaTrans = '"Our Lord! Grant us good in this world and good in the Hereafter."';

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

    await p.setString('wq_ref', '✨ $liveAyahRef');
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
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = p.getBool('dark') ?? true;
      accentIndex = p.getInt('accent') ?? 0;
      appLang = p.getString('lang') ?? 'en';
      use12Hour = p.getBool('use12') ?? true;
      globalUserName = p.getString('user_name') ?? 'Mumin';
      adminPinCode = p.getString('adm_pin') ?? '7860';
      adminShowBanner = p.getBool('adm_show_ban') ?? true;
      adminBannerTitle = p.getString('adm_ban_t') ?? adminBannerTitle;
      adminBannerMsg = p.getString('adm_ban_m') ?? adminBannerMsg;
      adminShowPopup = p.getBool('adm_show_pop') ?? false;
      adminPopupTitle = p.getString('adm_pop_t') ?? adminPopupTitle;
      adminPopupBody = p.getString('adm_pop_b') ?? adminPopupBody;
      adminUpdateAvailable = p.getBool('adm_upd_on') ?? false;
      adminLatestVer = p.getString('adm_upd_v') ?? adminLatestVer;
      adminUpdateUrl = p.getString('adm_upd_u') ?? adminUpdateUrl;
      adminDevName = p.getString('adm_dev_n') ?? adminDevName;
      adminDevBio = p.getString('adm_dev_b') ?? adminDevBio;
      adminDevImage = p.getString('adm_dev_img') ?? '';
      adminDevInsta = p.getString('adm_dev_ig') ?? adminDevInsta;
      adminDevFb = p.getString('adm_dev_fb') ?? adminDevFb;
    });
    await fetchLiveDailyAyahAndDua();
    if (mounted) setState(() {});
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
  int idx = 0;
  int kitSub = 0;
  bool popShown = false;

  void _nav(int i, {int sub = 0}) => setState(() { idx = i; kitSub = sub; });

  @override
  Widget build(BuildContext context) {
    if (adminShowPopup && !popShown) {
      popShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: kCard,
            title: Text(adminPopupTitle, style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
            content: Text(adminPopupBody, style: TextStyle(color: kText)),
            actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kPrimary), onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: Colors.black)))],
          ),
        );
      });
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
        decoration: BoxDecoration(color: kCard.withOpacity(0.96), borderRadius: BorderRadius.circular(28), border: Border.all(color: kBorder)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navPill(0, Icons.wb_twilight_rounded, tr('Today', 'आज', 'آج', 'Today')),
            _navPill(1, Icons.local_fire_department_rounded, tr('Streak', 'स्ट्रीक', 'اسٹریک', 'Streak')),
            _navPill(2, Icons.menu_book_rounded, tr('Kitab', 'किताब', 'کتاب', 'Kitab')),
            _navPill(3, Icons.settings_rounded, tr('Settings', 'सेटिंग्स', 'ترتیبات', 'Settings')),
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
        decoration: BoxDecoration(color: sel ? kPrimary : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(ic, size: 19, color: sel ? Colors.black : kMuted),
            if (sel) ...[const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900))],
          ],
        ),
      ),
    );
  }
}






// ---------------- 1. HOMEPAGE & LIVE ANIMATED WIDGET STUDIO ----------------
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
  String nextP = 'Dhuhr', countdown = '02h 14m 30s';

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
    _tick();
    final p = await SharedPreferences.getInstance();
    await p.setString('wp_loc', '⚡ NOOR LIVE • ${loc.toUpperCase()}');
    await p.setString('wp_user', 'SALAH RADAR • ${globalUserName.toUpperCase()}');
    await p.setString('wp_next_name', nextP);
    await p.setString('wp_next', formatClock(times[nextP]!));
    await p.setInt('wp_rem_sec', remSeconds);
    await p.setString('wp_strip', 'Fajr ${formatClock(times['Fajr']!).split(' ')[0]} • Dhuhr ${formatClock(times['Dhuhr']!).split(' ')[0]} • Asr ${formatClock(times['Asr']!).split(' ')[0]} • Mag ${formatClock(times['Maghrib']!).split(' ')[0]} • Isha ${formatClock(times['Isha']!).split(' ')[0]}');
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
          if (adminUpdateAvailable)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kSecondary.withOpacity(0.2), borderRadius: BorderRadius.circular(14), border: Border.all(color: kSecondary)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🚀 Update $adminLatestVer Live!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kText)),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kSecondary), onPressed: () => Clipboard.setData(ClipboardData(text: adminUpdateUrl)), child: const Text('Copy Link', style: TextStyle(color: Colors.black, fontSize: 11))),
                ],
              ),
            ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📍 $loc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                  Text('🌙 $hijri • Salam, $globalUserName', style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600)),
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

          // Hero Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kPrimary.withOpacity(0.24), kCardAlt, kCard], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kPrimary.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              children: [
                Text('UPCOMING SALAH • ${nextP.toUpperCase()}', style: TextStyle(color: kPrimary, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(formatClock(times[nextP]!), style: TextStyle(fontSize: 40, fontFamily: 'serif', fontWeight: FontWeight.w900, color: kText)),
                const SizedBox(height: 4),
                Text('Starts in $countdown', style: TextStyle(color: kSecondary, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('🌙 Suhur: ${formatClock(times['Fajr']!)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText)),
                    Text('🌅 Sunrise: ${formatClock(sunrise)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText)),
                    Text('🌇 Iftar: ${formatClock(times['Maghrib']!)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kText)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🕌 Daily Salah Check-In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kText)),
              Text('$salahDone/5 Offered • Hold Time to Edit', style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: prayers.map((pr) {
              bool isN = pr == nextP;
              int st = status[pr] ?? 0;
              final stCols = [kMuted, kSecondary, const Color(0xFF38BDF8), kPrimary, const Color(0xFFEF4444)];
              final stTags = ['Tap +', 'Jamaat', 'OnTime', 'Late', 'Missed'];
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
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: st > 0 ? stCols[st] : (isN ? kPrimary : kBorder), width: 1.4),
                    ),
                    child: Column(
                      children: [
                        Text(pr, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: isN ? kPrimary : kText)),
                        const SizedBox(height: 3),
                        Text(formatClock(times[pr]!).split(' ')[0], style: TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(stTags[st], style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: stCols[st])),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Live Ayah Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kPrimary.withOpacity(0.4))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('✨ LIVE AYAH • $liveAyahRef', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kPrimary)),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (isPlayingAyah) { await audioPlayer.stop(); setState(() => isPlayingAyah = false); }
                            else { setState(() => isPlayingAyah = true); await audioPlayer.play(UrlSource(liveAyahAudio)); }
                          },
                          child: Icon(isPlayingAyah ? Icons.stop_circle : Icons.volume_up_rounded, size: 18, color: kSecondary),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async { await fetchLiveDailyAyahAndDua(forceRandom: true); if (mounted) setState(() {}); },
                          child: Text('New ↻', style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.bold)),
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

          // Live Dua Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kSecondary.withOpacity(0.4))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('🤲 $liveDuaRef', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kSecondary)),
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

// ---------------- 2. LIVE ANIMATED RADAR & COUNTDOWN WIDGET STUDIO ----------------
class RadarSweepPainter extends CustomPainter {
  final double angle;
  final Color col;
  RadarSweepPainter(this.angle, this.col);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.82, size.height * 0.45);
    final p = Paint()..color = col.withOpacity(0.16)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawCircle(c, 30, p);
    canvas.drawCircle(c, 50, p);
    canvas.drawCircle(Offset(c.dx + 50 * math.cos(angle), c.dy + 50 * math.sin(angle)), 5, Paint()..color = col);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LiveAnimatedWidgetStudioPage extends StatefulWidget {
  const LiveAnimatedWidgetStudioPage({super.key});
  @override
  State<LiveAnimatedWidgetStudioPage> createState() => _LiveAnimatedWidgetStudioPageState();
}

class _LiveAnimatedWidgetStudioPageState extends State<LiveAnimatedWidgetStudioPage> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  Timer? _clockTimer;
  String loc = '⚡ NOOR LIVE • BARPAKA', nextP = 'Dhuhr', nextTime = '12:15 PM';
  String stripText = 'Fajr 04:15 • Dhuhr 12:15 • Asr 03:25 • Mag 04:45 • Isha 06:15';
  int remSec = 5420;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
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
  void dispose() { _animCtrl.dispose(); _clockTimer?.cancel(); super.dispose(); }

  String _fmt(int s) => '- ${(s ~/ 3600).toString().padLeft(2, '0')}:${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('⚡ $globalUserName\'s Live Widgets'), backgroundColor: kBg),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('1. LIVE ANIMATED SALAH RADAR WIDGET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kSecondary)),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (_, __) {
              double pulse = 0.5 + 0.5 * math.sin(_animCtrl.value * 2 * math.pi);
              return ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0F2922), Color(0xFF091512), Color(0xFF050807)]),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.5 + pulse * 0.4), width: 2),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: RadarSweepPainter(_animCtrl.value * 2 * math.pi, const Color(0xFF2DD4BF)))),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(loc, style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.w900)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF132A24), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF59E0B))),
                                child: Text(_fmt(remSec), style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12.5, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('SALAH RADAR • ${globalUserName.toUpperCase()}', style: const TextStyle(color: Colors.white60, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(nextP, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                              Text(nextTime, style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 24, fontFamily: 'serif', fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const LinearProgressIndicator(value: 0.68, minHeight: 6, backgroundColor: Color(0xFF1E352F), valueColor: AlwaysStoppedAnimation(Color(0xFFF59E0B))),
                          const SizedBox(height: 10),
                          Text(stripText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          Text('2. LIVE STREAMING AYAH WIDGET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F2922), Color(0xFF091512), Color(0xFF050807)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF2DD4BF), width: 1.8),
            ),
            child: Column(
              children: [
                Text('✨ $liveAyahRef', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(liveAyahArab, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(liveAyahTrans, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontFamily: 'serif')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kSecondary, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () async {
              final p = await SharedPreferences.getInstance();
              await p.setString('wp_user', 'SALAH RADAR • ${globalUserName.toUpperCase()}');
              await p.setInt('wp_rem_sec', remSec);
              await triggerNativeWidgetBroadcast();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kSecondary, content: const Text('⚡ Live Countdown Widget Synced to Phone!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))));
            },
            icon: const Icon(Icons.bolt_rounded, color: Colors.black),
            label: const Text('SYNC LIVE WIDGETS TO PHONE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}







// ---------------- 3. STREAK TAB & 4. KITAB TAB (TOP HADITH SEARCH!) ----------------
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
    int mAda = 0, mJamaat = 0;
    for (int i = 1; i <= daysInM; i++) {
      final dt = DateTime(now.year, now.month, i);
      for (var p in prayers) {
        int s = _st(dt, p);
        if (s > 0 && s < 4) mAda++;
        if (s == 1) mJamaat++;
      }
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          Text('🔥 SPIRITUAL STREAK & BADGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kPrimary.withOpacity(0.5))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$mAda Prayers Offered This Month', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kText)),
                const SizedBox(height: 4),
                Text('🟢 $mJamaat Offered in Congregation (Jamaat)', style: TextStyle(fontSize: 13, color: kSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
  List<Map<String, String>> globalHadithPool = [];

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

  final List<Map<String, String>> masterHadithIndex = [
    {'book': 'Sahih al-Bukhari', 'num': '1', 'ar': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ', 'en': 'Actions are judged only by intentions, and every person will have only what they intended.'},
    {'book': 'Sahih al-Bukhari', 'num': '5027', 'ar': 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ', 'en': 'The best among you (Muslims) are those who learn the Glorious Qur\'an and teach it to others.'},
    {'book': 'Sahih Muslim', 'num': '223', 'ar': 'الطُّهُورُ شَطْرُ الإِيمَانِ', 'en': 'Cleanliness (Wudu/Purity) is half of faith (Iman), and saying Alhamdulillah fills the scale of good deeds, and Prayer (Salah) is a light (Noor), and Charity (Sadaqah) is a proof.'},
    {'book': 'Sahih Muslim', 'num': '2564', 'ar': 'إِنَّ اللَّهَ لاَ يَنْظُرُ إِلَى صُوَرِكُمْ', 'en': 'Verily, Allah does not look at your appearances or your wealth, rather He looks at your hearts and your deeds.'},
    {'book': 'Jami\' at-Tirmidhi', 'num': '1956', 'ar': 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ', 'en': 'Your smiling in the face of your brother is a charity (Sadaqah) for you.'},
    {'book': 'Sunan an-Nasa\'i', 'num': '3104', 'ar': 'الْجَنَّةُ تَحْتَ أَقْدَامِ الأُمَّهَاتِ', 'en': 'Stay with your mother, for indeed Paradise (Jannah) lies beneath her feet.'},
  ];

  @override
  void initState() {
    super.initState();
    tab = widget.initTab;
    globalHadithPool = List.from(masterHadithIndex);
    http.get(Uri.parse('https://api.alquran.cloud/v1/surah')).then((r) {
      if (r.statusCode == 200 && mounted) setState(() { surahs = json.decode(r.body)['data']; loadingQuran = false; });
    });
    _preloadHadiths();
  }

  Future<void> _preloadHadiths() async {
    try {
      for (var u in [
        {'b': 'An-Nawawi 40', 'url': 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-nawawi.json'},
        {'b': 'Sahih Bukhari', 'url': 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-bukhari/sections/1.json'},
        {'b': 'Sahih Muslim', 'url': 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-muslim/sections/1.json'},
      ]) {
        final r = await http.get(Uri.parse(u['url']!));
        if (r.statusCode == 200) {
          for (var h in (json.decode(r.body)['hadiths'] ?? [])) {
            final t = h['text']?.toString() ?? '';
            if (t.isNotEmpty) globalHadithPool.add({'book': u['b']!, 'num': h['hadithnumber']?.toString() ?? '', 'ar': '', 'en': t});
          }
        }
      }
    } catch (_) {}
  }

  void _openFullHadithModal(Map<String, String> h) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('📜 ${h['book']} • Hadith #${h['num']}', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900, fontSize: 13)),
                IconButton(icon: Icon(Icons.copy_rounded, color: kSecondary), onPressed: () { Clipboard.setData(ClipboardData(text: '${h['ar']}\n\n${h['en']}')); Navigator.pop(ctx); }),
              ],
            ),
            const SizedBox(height: 12),
            if ((h['ar'] ?? '').isNotEmpty) ...[
              Text(h['ar']!, textAlign: TextAlign.right, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kText)),
              Divider(color: kBorder, height: 22),
            ],
            Text(h['en']!, style: TextStyle(fontSize: 15, fontFamily: 'serif', color: kText, height: 1.55)),
            const SizedBox(height: 16),
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
        ? globalHadithPool.where((h) => h['en']!.toLowerCase().contains(globalHadithQuery.toLowerCase()) || h['book']!.toLowerCase().contains(globalHadithQuery.toLowerCase()) || h['num']!.contains(globalHadithQuery)).toList()
        : <Map<String, String>>[];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 85),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
              child: Row(children: [_segBtn('📖 AL-QURAN (114)', 0), _segBtn('📚 10 HADITH BOOKS', 1)]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tab == 0
                  ? Column(
                      children: [
                        TextField(onChanged: (v) => setState(() => qSearch = v), decoration: InputDecoration(hintText: 'Search Surah...', prefixIcon: Icon(Icons.search, color: kPrimary), filled: true, fillColor: kCard, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                        const SizedBox(height: 10),
                        Expanded(
                          child: loadingQuran
                              ? Center(child: CircularProgressIndicator(color: kPrimary))
                              : ListView.builder(
                                  itemCount: fS.length,
                                  itemBuilder: (_, i) => ListTile(
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
                        // SEARCH BAR DIRECTLY ABOVE HADITH BOOKS!
                        TextField(
                          onChanged: (v) => setState(() => globalHadithQuery = v),
                          decoration: InputDecoration(
                            hintText: '🔍 Search Hadith topic, word or # (e.g. prayer, charity, mother)...',
                            prefixIcon: Icon(Icons.search_rounded, color: kPrimary),
                            suffixIcon: isSearchingH ? IconButton(icon: Icon(Icons.clear, color: kMuted), onPressed: () => setState(() => globalHadithQuery = '')) : null,
                            filled: true,
                            fillColor: kCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                                                Text('📜 ${h['book']} • #${h['num']}', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                                                Text('Tap for full →', style: TextStyle(color: kSecondary, fontSize: 10.5, fontWeight: FontWeight.bold)),
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
                                        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.withOpacity(0.35))),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Icon(b['ic'] as IconData, color: c, size: 26),
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
          decoration: BoxDecoration(color: sel ? kCardAlt : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(lb, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: sel ? kPrimary : kMuted))),
        ),
      ),
    );
  }
}









// ---------------- READERS, SETTINGS (WITH WIDGET ABOVE LANGUAGE!) & ADMIN PANEL ----------------
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
              Text(txt, style: TextStyle(fontSize: 15, fontFamily: 'serif', color: kText, height: 1.5)),
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
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hadith #$num', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 12)), Text('Tap for full →', style: TextStyle(color: kSecondary, fontSize: 10.5))]),
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
  final feedbackCtrl = TextEditingController();

  void _openUserNameAndWidgets() {
    final ctrl = TextEditingController(text: globalUserName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('👤 Enter Username for Widget', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Your Name')),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              String n = ctrl.text.trim();
              if (n.isNotEmpty) {
                final p = await SharedPreferences.getInstance();
                await p.setString('user_name', n);
                await p.setString('wp_user', 'SALAH RADAR • ${n.toUpperCase()}');
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
            child: const Text('Save & Open Live Widgets', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: Text('🔐 Admin PIN (Default: 7860)', style: TextStyle(color: kPrimary)),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        children: [
          // 1. TOP APP LOGO & HANDLES
          GestureDetector(
            onLongPress: _openAdminPin,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kPrimary.withOpacity(0.45))),
              child: Column(
                children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.mosque_rounded, size: 32, color: Colors.black)),
                  const SizedBox(height: 10),
                  Text('NOOR ISLAMIC PRO', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: kText)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📸 $adminAppInsta', style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 14),
                      Text('📘 $adminAppFb', style: TextStyle(fontSize: 11, color: kSecondary, fontWeight: FontWeight.bold)),
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
              title: Text(isDarkMode ? '🌙 Dark Theme' : '☀️ Light Theme', style: TextStyle(fontWeight: FontWeight.bold, color: kText)),
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

          // 🌟 3. USERNAME & LIVE WIDGET STUDIO (DIRECTLY ABOVE LANGUAGE AS REQUESTED!) 🌟
          GestureDetector(
            onTap: _openUserNameAndWidgets,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kSecondary.withOpacity(0.22), kCard]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kSecondary, width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: kSecondary, child: const Icon(Icons.widgets_rounded, color: Colors.black)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚡ User: $globalUserName • Live Widgets', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kText)),
                        Text('Tap to set Username & view Live Animated Widgets', style: TextStyle(fontSize: 11, color: kSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: kSecondary),
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
                Text('🌐 APP LANGUAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary)),
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

          // 5. THEME COLOR PICKER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎨 THEME COLOUR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary)),
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
                        backgroundColor: (pal['primary'] as Color).withOpacity(0.2),
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

          // 6. FEEDBACK & DEVELOPER PROFILE
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
            child: Column(
              children: [
                CircleAvatar(radius: 34, backgroundColor: kPrimary, child: const Icon(Icons.person_rounded, size: 36, color: Colors.black)),
                const SizedBox(height: 8),
                Text(adminDevName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                const SizedBox(height: 4),
                Text(adminDevBio, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: kMuted)),
                const SizedBox(height: 8),
                Text('📸 $adminDevInsta  •  📘 $adminDevFb', style: TextStyle(fontSize: 11, color: kSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: _openAdminPin, icon: Icon(Icons.admin_panel_settings, size: 16, color: kPrimary), label: Text('Owner Admin Panel', style: TextStyle(color: kPrimary))),
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
      appBar: AppBar(title: const Text('👑 Admin Control Panel'), backgroundColor: kBg),
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





