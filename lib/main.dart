import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IslamicApp());
}

// ---------------- GLOBAL LANGUAGE & 12H/24H HELPERS ----------------
String appLang = 'en'; // 'en'=English, 'hi'=Hindi, 'ur'=Urdu, 'ro'=Hinglish
bool use12HourFormat = true;

const Map<String, Map<String, String>> _dict = {
  'greeting': {
    'en': 'Assalamu Alaikum 👋',
    'hi': 'अस्सलामु अलैकुम 👋',
    'ur': 'السلام علیکم 👋',
    'ro': 'Assalamu Alaikum 👋'
  },
  'next_prayer_in': {
    'en': 'Time remaining for next prayer:',
    'hi': 'अगली नमाज़ में बाकी समय:',
    'ur': 'اگلی نماز میں باقی وقت:',
    'ro': 'Agli Namaz mein baqi waqt:'
  },
  'sunrise': {'en': 'Sunrise', 'hi': 'सूर्योदय', 'ur': 'طلوع آفتاب', 'ro': 'Sunrise'},
  'sunset': {'en': 'Sunset', 'hi': 'सूर्यास्त', 'ur': 'غروب آفتاب', 'ro': 'Sunset'},
  'soul_care': {
    'en': '💖 Soul Care (How are you feeling today?)',
    'hi': '💖 रूहानी सुकून (आज आप कैसा महसूस कर रहे हैं?)',
    'ur': '💖 روحانی سکون (آج آپ کیسا محسوس کر رہے ہیں؟)',
    'ro': '💖 Soul Care (Aaj kaisa mehsoos kar rahe ho?)'
  },
  'todays_prayers': {
    'en': '🕌 Today\'s Prayers',
    'hi': '🕌 आज की नमाज़ें',
    'ur': '🕌 آج کی نمازیں',
    'ro': '🕌 Aaj ki Namazein'
  },
  'set_times_btn': {
    'en': '⏰ Set Time / 12h-24h',
    'hi': '⏰ समय सेट करें',
    'ur': '⏰ وقت سیٹ کریں',
    'ro': '⏰ Set Time / 12h'
  },
  'sunnah_habits': {
    'en': '🔥 Daily Sunnah Habits',
    'hi': '🔥 रोज़ाना की सुन्नतें',
    'ur': '🔥 روزانہ کی سنتیں',
    'ro': '🔥 Daily Sunnah Habits'
  },
  'log_btn': {'en': 'Log ➕', 'hi': 'दर्ज करें ➕', 'ur': 'درج کریں ➕', 'ro': 'Log ➕'},
  'jamaat': {'en': '🟢 Jamaat', 'hi': '🟢 जमात', 'ur': '🟢 جماعت', 'ro': '🟢 Jamaat'},
  'ontime': {'en': '🔵 On Time', 'hi': '🔵 समय पर', 'ur': '🔵 وقت پر', 'ro': '🔵 On Time'},
  'qaza': {'en': '🟠 Qaza', 'hi': '🟠 क़ज़ा', 'ur': '🟠 قضا', 'ro': '🟠 Qaza'},
  'missed': {'en': '🔴 Missed', 'hi': '🔴 छूट गई', 'ur': '🔴 قضا باقی', 'ro': '🔴 Missed'},
};

String tr(String key) => _dict[key]?[appLang] ?? _dict[key]?['en'] ?? key;

String trPrayerName(String p) {
  const names = {
    'Fajr': {'en': 'Fajr', 'hi': 'फ़ज्र (Fajr)', 'ur': 'فجر', 'ro': 'Fajr (फज्र)'},
    'Dhuhr': {'en': 'Dhuhr', 'hi': 'ज़ुहर (Dhuhr)', 'ur': 'ظہر', 'ro': 'Dhuhr (ज़ुहर)'},
    'Asr': {'en': 'Asr', 'hi': 'अस्र (Asr)', 'ur': 'عصر', 'ro': 'Asr (अस्र)'},
    'Maghrib': {'en': 'Maghrib', 'hi': 'मग़रिब (Maghrib)', 'ur': 'مغرب', 'ro': 'Maghrib (मग़रिब)'},
    'Isha': {'en': 'Isha', 'hi': 'ईशा (Isha)', 'ur': 'عشاء', 'ro': 'Isha (ईशा)'},
  };
  return names[p]?[appLang] ?? p;
}

// Converts "17:50" -> "05:50 PM" when use12HourFormat is true
String formatClock(String raw24) {
  if (!raw24.contains(':')) return raw24;
  try {
    final clean = raw24.split(' ')[0];
    final parts = clean.split(':');
    int h = int.parse(parts[0]);
    int m = int.parse(parts[1]);
    String mm = m.toString().padLeft(2, '0');
    if (!use12HourFormat) {
      return '${h.toString().padLeft(2, '0')}:$mm';
    }
    String period = h >= 12 ? 'PM' : 'AM';
    int h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '${h12.toString().padLeft(2, '0')}:$mm $period';
  } catch (_) {
    return raw24;
  }
}

String getDateKey(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

int getPrayerStatus(SharedPreferences? prefs, DateTime date, String prayer) {
  if (prefs == null) return 0;
  String k = 'status_${getDateKey(date)}_$prayer';
  if (prefs.containsKey(k)) return prefs.getInt(k) ?? 0;
  return (prefs.getBool('track_${getDateKey(date)}_$prayer') ?? false) ? 1 : 0;
}

bool isPrayerOffered(int status) => status == 1 || status == 2 || status == 3;

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noor Super App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF061014),
        primaryColor: const Color(0xFF10B981),
        cardColor: const Color(0xFF10242D),
        fontFamily: 'Roboto',
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadGlobalPrefs();
  }

  Future<void> _loadGlobalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      appLang = prefs.getString('app_lang') ?? 'en';
      use12HourFormat = prefs.getBool('use_12h') ?? true;
    });
  }

  void _refreshApp() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onGlobalChange: _refreshApp),
      const PrayerAnalyticsScreen(),
      const LiveQuranScreen(),
      const QiblaCompassScreen(),
      const IslamicToolsHubScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E3A44), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF09171E),
          selectedItemColor: const Color(0xFFFFD700),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'Prayer'),
            BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Tracker'),
            BottomNavigationBarItem(icon: Icon(Icons.headphones), label: 'Audio Quran'),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Qibla'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Hub & Zakat'),
          ],
        ),
      ),
    );
  }
}

// ---------------- CARTOON MOSQUE ART PAINTER ----------------
class CartoonMosquePainter extends CustomPainter {
  final bool isDayTime;
  CartoonMosquePainter({required this.isDayTime});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    if (!isDayTime) {
      paint.color = Colors.white70;
      for (var s in [
        Offset(size.width * 0.15, size.height * 0.18),
        Offset(size.width * 0.35, size.height * 0.12),
        Offset(size.width * 0.55, size.height * 0.22),
      ]) {
        canvas.drawCircle(s, 2.2, paint);
      }
      paint.color = const Color(0xFFFFE066);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.24), 20, paint);
      paint.color = const Color(0xFF1A1245);
      canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.21), 18, paint);
    } else {
      paint.color = const Color(0xFFFFD700).withOpacity(0.25);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.26), 34, paint);
      paint.color = const Color(0xFFFFEA79);
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.26), 20, paint);
    }

    paint.color = isDayTime ? const Color(0xFF06322D).withOpacity(0.85) : const Color(0xFF091224).withOpacity(0.92);
    final hill = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.92, size.width * 0.72, size.height * 0.74)
      ..quadraticBezierTo(size.width * 0.90, size.height * 0.66, size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill, paint);

    final mCol = isDayTime ? const Color(0xFF04221F) : const Color(0xFF050A14);
    double mx = size.width * 0.75, my = size.height * 0.78;
    paint.color = mCol;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mx, my + 12), width: 74, height: 32), const Radius.circular(6)), paint);
    paint.color = const Color(0xFFFFD700).withOpacity(0.85);
    canvas.drawArc(Rect.fromCenter(center: Offset(mx, my - 4), width: 44, height: 40), 3.14159, 3.14159, true, paint);
    paint.color = mCol;
    canvas.drawRect(Rect.fromLTWH(mx - 44, my - 48, 8, 74), paint);
    canvas.drawRect(Rect.fromLTWH(mx + 36, my - 48, 8, 74), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------- 1. HOME SCREEN ----------------
class DashboardScreen extends StatefulWidget {
  final VoidCallback onGlobalChange;
  const DashboardScreen({super.key, required this.onGlobalChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String locationName = 'Rupahi';
  double lat = 26.4167, lon = 92.7333;
  String hijriDate = '1448 AH', sunriseTime = '05:45', sunsetTime = '17:50';
  bool isLoading = true;
  int asrSchool = 0;
  bool isManualTimingMode = false;

  Timer? _countdownTimer;
  String nextPrayerName = 'Fajr', countdownText = '00 : 00 : 00';

  final List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, String> apiTimes = {'Fajr': '04:45', 'Dhuhr': '12:05', 'Asr': '15:30', 'Maghrib': '17:50', 'Isha': '19:10'};
  Map<String, String> manualTimes = {'Fajr': '05:00', 'Dhuhr': '13:00', 'Asr': '16:15', 'Maghrib': '17:55', 'Isha': '19:30'};
  Map<String, int> todayStatus = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};
  Map<String, bool> sunnahDoneMap = {'s1': false, 's2': false, 's3': false, 's4': false};

  String _activeTime(String p) => isManualTimingMode ? (manualTimes[p] ?? '05:00') : (apiTimes[p] ?? '05:00');

  List<Map<String, String>> _getMoods() {
    return [
      {
        'emoji': '😔',
        'label': appLang == 'hi' ? 'परेशान / उदास' : (appLang == 'ur' ? 'پریشان / اداس' : (appLang == 'ro' ? 'Pareshan / Sad' : 'Sad / Anxious')),
        'arabic': 'لَا تُحْزَنْ إِنَّ اللَّهَ مَعَنَا',
        'ayah': appLang == 'en'
            ? '"Do not grieve; indeed Allah is with us." (Quran 9:40)'
            : '"Gham na karo, beshak Allah humare sath hai." (Quran 9:40)',
        'dua': 'Dua: Yaa Hayyu Yaa Qayyum, birahmatika astagheeth.'
      },
      {
        'emoji': '💸',
        'label': appLang == 'hi' ? 'रिज़्क़ की तंगी' : (appLang == 'ur' ? 'رزق کی تنگی' : (appLang == 'ro' ? 'Rizq / Tension' : 'Financial Stress')),
        'arabic': 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
        'ayah': appLang == 'en'
            ? '"Whoever fears Allah, He will make a way out for him and provide from where he does not expect." (65:2-3)'
            : '"Jo Allah se darta hai, Allah uske liye rasta nikal deta hai aur ghaib se Rizq deta hai." (65:2-3)',
        'dua': 'Dua: Allahumma inni as\'aluka \'ilman nafi\'an, wa rizqan tayyiban.'
      },
      {
        'emoji': '😠',
        'label': appLang == 'hi' ? 'गुस्सा' : (appLang == 'ur' ? 'غصہ' : (appLang == 'ro' ? 'Gussa / Angry' : 'Angry')),
        'arabic': 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
        'ayah': appLang == 'en'
            ? 'Prophet ﷺ said: "When angry, say A\'udhu billah, sit down, or perform Wudu with cold water."'
            : 'Nabi ﷺ ne farmaya: "Jab gussa aaye toh A\'udhu billah padho, baith jao ya Wudu kar lo!"',
        'dua': 'Sunnah Cure: Drink water and change your posture.'
      },
      {
        'emoji': '🤒',
        'label': appLang == 'hi' ? 'बीमार' : (appLang == 'ur' ? 'بیمار' : (appLang == 'ro' ? 'Bimar / Sick' : 'Sick / Unwell')),
        'arabic': 'وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ',
        'ayah': appLang == 'en'
            ? '"And when I am ill, it is He (Allah) who cures me." (Quran 26:80)'
            : '"Aur jab main bimar hota hoon toh Wahi (Allah) mujhe shifa deta hai." (Quran 26:80)',
        'dua': 'Dua: Allahumma Rabban-naas, adh-hibil-ba\'s, ishfi Antash-Shafi.'
      },
      {
        'emoji': '🥰',
        'label': appLang == 'hi' ? 'शुक्रगुज़ार' : (appLang == 'ur' ? 'شکر گزار' : (appLang == 'ro' ? 'Shukr / Happy' : 'Grateful')),
        'arabic': 'لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ',
        'ayah': appLang == 'en'
            ? '"If you are grateful, I will surely increase you!" (Quran 14:7)'
            : '"Agar tum mera Shukr ada karoge, toh main tumhe aur zyada dunga!" (Quran 14:7)',
        'dua': 'Zikr: Alhamdulillah \'ala kulli haal.'
      },
    ];
  }

  Map<String, String> _getSunnahLabels() {
    if (appLang == 'hi') {
      return {
        's1': '🦷 वुज़ू से पहले मिस्वाक / ब्रश करना',
        's2': '📖 हर फ़र्ज़ नमाज़ के बाद आयतुल कुर्सी पढ़ना',
        's3': '😊 घर वालों को मुस्कुरा कर सलाम करना',
        's4': '🌙 रात को बा-वुज़ू होकर सोना',
      };
    } else if (appLang == 'ur') {
      return {
        's1': '🦷 وضو سے پہلے مسواک کرنا',
        's2': '📖 ہر فرض نماز کے بعد آیت الکرسی پڑھنا',
        's3': '😊 مسکرا کر سلام کرنا',
        's4': '🌙 باوضو ہو کر سونا',
      };
    } else if (appLang == 'ro') {
      return {
        's1': '🦷 Wudu se pehle Miswak / Brush karna',
        's2': '📖 Farz Namaz ke baad Ayat-ul-Kursi padhna',
        's3': '😊 Muskura kar Salam karna (Sadqah)',
        's4': '🌙 Raat ko Ba-Wudu hokar sona',
      };
    }
    return {
      's1': '🦷 Use Miswak / Brush before Wudu',
      's2': '📖 Recite Ayat-ul-Kursi after every Salah',
      's3': '😊 Greet Family & Friends with a Smile & Salam',
      's4': '🌙 Sleep in a state of Wudu & read Surah Mulk',
    };
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  DateTime? _parseTime(String t, DateTime ref) {
    if (!t.contains(':')) return null;
    try {
      final p = t.split(' ')[0].split(':');
      return DateTime(ref.year, ref.month, ref.day, int.parse(p[0]), int.parse(p[1]));
    } catch (_) {
      return null;
    }
  }

  void _updateCountdown() {
    final now = DateTime.now();
    DateTime? nextT;
    String found = 'Fajr';
    for (var p in prayerNames) {
      DateTime? pt = _parseTime(_activeTime(p), now);
      if (pt != null && pt.isAfter(now)) {
        nextT = pt;
        found = p;
        break;
      }
    }
    if (nextT == null) {
      DateTime? ft = _parseTime(_activeTime('Fajr'), now);
      if (ft != null) nextT = ft.add(const Duration(days: 1));
    }
    if (nextT != null && mounted) {
      final d = nextT.difference(now);
      setState(() {
        nextPrayerName = found;
        countdownText =
            '${d.inHours.toString().padLeft(2, '0')} : ${(d.inMinutes % 60).toString().padLeft(2, '0')} : ${(d.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final tKey = getDateKey(today);
    setState(() {
      locationName = prefs.getString('loc_name') ?? 'Rupahi';
      lat = prefs.getDouble('lat') ?? 26.4167;
      lon = prefs.getDouble('lon') ?? 92.7333;
      asrSchool = prefs.getInt('asr_school') ?? 0;
      isManualTimingMode = prefs.getBool('manual_mode') ?? false;
      for (var p in prayerNames) {
        todayStatus[p] = getPrayerStatus(prefs, today, p);
        manualTimes[p] = prefs.getString('manual_time_$p') ?? manualTimes[p]!;
      }
      for (var k in sunnahDoneMap.keys.toList()) {
        sunnahDoneMap[k] = prefs.getBool('sunnah_${tKey}_$k') ?? false;
      }
    });
    await _fetchTimings();
  }

  Future<void> _fetchTimings() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
          'https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=1&school=$asrSchool');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        final t = data['timings'];
        final h = data['date']['hijri'];
        setState(() {
          for (var p in prayerNames) {
            apiTimes[p] = t[p].toString().split(' ')[0];
          }
          sunriseTime = t['Sunrise'].toString().split(' ')[0];
          sunsetTime = t['Sunset'].toString().split(' ')[0];
          hijriDate = '${h['day']} ${h['month']['en']} ${h['year']}';
          isLoading = false;
        });
        _updateCountdown();
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _openLanguageSheet() {
    final langs = [
      {'code': 'en', 'title': '🇬🇧 English (International)', 'sub': 'Clean English interface for everyone'},
      {'code': 'hi', 'title': '🇮🇳 हिंदी (Hindi)', 'sub': 'आसान हिंदी भाषा में पूरा ऐप'},
      {'code': 'ur', 'title': '🇵🇰 اردو (Urdu)', 'sub': 'مکمل ایپ آسان اردو زبان میں'},
      {'code': 'ro', 'title': '💬 Roman Urdu / Hinglish', 'sub': 'Aasan bol-chal wali bhasha'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D212A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🌐 Select App Language / भाषा चुनें',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 14),
            ...langs.map((l) {
              bool sel = appLang == l['code'];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: sel ? const Color(0xFF10B981).withOpacity(0.25) : Colors.transparent,
                title: Text(l['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(l['sub']!, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                trailing: sel ? const Icon(Icons.check_circle, color: Color(0xFFFFD700)) : null,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('app_lang', l['code']!);
                  setState(() => appLang = l['code']!);
                  widget.onGlobalChange();
                  if (mounted) Navigator.pop(ctx);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _openTimeCustomizationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D212A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⏰ Clock Format & Manual Prayer Times',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF142E3A), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🕒 12-Hour Clock (AM / PM)', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Turn OFF for 24-Hour clock (17:50)', style: TextStyle(fontSize: 11, color: Colors.white60)),
                          ],
                        ),
                        Switch(
                          activeColor: const Color(0xFFFFD700),
                          activeTrackColor: const Color(0xFF10B981),
                          value: use12HourFormat,
                          onChanged: (val) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('use_12h', val);
                            setState(() => use12HourFormat = val);
                            setModalState(() {});
                            widget.onGlobalChange();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF142E3A), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('✍️ Manual Masjid Timing Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Set your local Masjid times manually', style: TextStyle(fontSize: 11, color: Colors.white60)),
                            ],
                          ),
                        ),
                        Switch(
                          activeColor: const Color(0xFFFFD700),
                          activeTrackColor: const Color(0xFF10B981),
                          value: isManualTimingMode,
                          onChanged: (val) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('manual_mode', val);
                            setState(() => isManualTimingMode = val);
                            setModalState(() {});
                            _updateCountdown();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...prayerNames.map((p) {
                    String currentRaw = _activeTime(p);
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      title: Text(trPrayerName(p), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(isManualTimingMode ? 'Custom Manual Time' : 'Live Auto GPS Time',
                          style: TextStyle(fontSize: 11, color: isManualTimingMode ? const Color(0xFFFFD700) : Colors.white54)),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16323F)),
                        icon: const Icon(Icons.edit_calendar, size: 15, color: Color(0xFFFFD700)),
                        label: Text(formatClock(currentRaw),
                            style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final parts = currentRaw.split(':');
                          TimeOfDay initTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: initTime,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: !use12HourFormat),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            String formatted24 =
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('manual_time_$p', formatted24);
                            await prefs.setBool('manual_mode', true);
                            setState(() {
                              manualTimes[p] = formatted24;
                              isManualTimingMode = true;
                            });
                            setModalState(() {});
                            _updateCountdown();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openLocationPicker() {
    TextEditingController ctrl = TextEditingController(text: locationName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10242D),
        title: const Text('📍 Location Setup', style: TextStyle(color: Color(0xFFFFD700))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => isLoading = true);
                try {
                  final res = await http.get(Uri.parse('http://ip-api.com/json'));
                  if (res.statusCode == 200) {
                    final d = json.decode(res.body);
                    String city = d['city'] ?? 'Rupahi';
                    lat = (d['lat'] as num).toDouble();
                    lon = (d['lon'] as num).toDouble();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('loc_name', city);
                    await prefs.setDouble('lat', lat);
                    await prefs.setDouble('lon', lon);
                    setState(() => locationName = city);
                    await _fetchTimings();
                  }
                } catch (_) {
                  setState(() => isLoading = false);
                }
              },
              icon: const Icon(Icons.my_location, color: Colors.white),
              label: const Text('Auto-Detect My Location', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'Enter City/Town (e.g. Rupahi, Delhi)',
                filled: true,
                fillColor: Color(0xFF16323F),
              ),
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
                setState(() => isLoading = true);
                try {
                  final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$place&format=json&limit=1');
                  final res = await http.get(url, headers: {'User-Agent': 'NoorSuperApp/8.0'});
                  if (res.statusCode == 200) {
                    final list = json.decode(res.body) as List;
                    if (list.isNotEmpty) {
                      lat = double.parse(list[0]['lat']);
                      lon = double.parse(list[0]['lon']);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('loc_name', place);
                      await prefs.setDouble('lat', lat);
                      await prefs.setDouble('lon', lon);
                      setState(() => locationName = place);
                      await _fetchTimings();
                      return;
                    }
                  }
                } catch (_) {}
                setState(() => isLoading = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _setPrayerStatus(String prayer, int status) async {
    final prefs = await SharedPreferences.getInstance();
    final tKey = getDateKey(DateTime.now());
    await prefs.setInt('status_${tKey}_$prayer', status);
    await prefs.setBool('track_${tKey}_$prayer', isPrayerOffered(status));
    setState(() => todayStatus[prayer] = status);
    HapticFeedback.lightImpact();
  }

  void _showMoodCureModal(Map<String, String> mood) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D212A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${mood['emoji']} ${mood['label']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const Divider(color: Colors.white12, height: 24),
            Text(mood['arabic']!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(mood['ayah']!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)),
              child: Text(mood['dua']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(String prayer) {
    int curr = todayStatus[prayer] ?? 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D212A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🕌 ${trPrayerName(prayer)} (${formatClock(_activeTime(prayer))})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 14),
            _statusBtn(ctx, prayer, 1, '${tr('jamaat')} (Masjid • 27x Reward)', const Color(0xFF10B981), curr),
            _statusBtn(ctx, prayer, 2, '${tr('ontime')} (Offered On Time)', const Color(0xFF3B82F6), curr),
            _statusBtn(ctx, prayer, 3, '${tr('qaza')} (Offered Late)', const Color(0xFFF59E0B), curr),
            _statusBtn(ctx, prayer, 4, '${tr('missed')} (Missed)', const Color(0xFFEF4444), curr),
          ],
        ),
      ),
    );
  }

  Widget _statusBtn(BuildContext ctx, String p, int val, String label, Color col, int curr) {
    return GestureDetector(
      onTap: () {
        _setPrayerStatus(p, val);
        Navigator.pop(ctx);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: curr == val ? col.withOpacity(0.3) : const Color(0xFF142E3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _statusBadge(int st) {
    final labels = [tr('log_btn'), tr('jamaat'), tr('ontime'), tr('qaza'), tr('missed')];
    final cols = [Colors.white24, const Color(0xFF10B981), const Color(0xFF3B82F6), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: cols[st].withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: cols[st])),
      child: Text(labels[st], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDay = (nextPrayerName == 'Dhuhr' || nextPrayerName == 'Asr' || nextPrayerName == 'Maghrib');
    final moods = _getMoods();
    final sunnahLabels = _getSunnahLabels();
    int sunnahDone = sunnahDoneMap.values.where((v) => v).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('greeting'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('🌙 $hijriDate', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openLanguageSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16323F),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.language, size: 14, color: Color(0xFFFFD700)),
                            const SizedBox(width: 4),
                            Text(appLang.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('use_12h', !use12HourFormat);
                        setState(() => use12HourFormat = !use12HourFormat);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF16323F), borderRadius: BorderRadius.circular(14)),
                        child: Text(use12HourFormat ? '12H' : '24H',
                            style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _openLocationPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 13, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(locationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 225,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDay
                        ? [const Color(0xFF0F766E), const Color(0xFF064E3B)]
                        : [const Color(0xFF1E1B4B), const Color(0xFF0F172A)],
                  ),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.45)),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: CartoonMosquePainter(isDayTime: isDay))),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14)),
                                child: Text(
                                  'NEXT: ${trPrayerName(nextPrayerName)} (${formatClock(_activeTime(nextPrayerName))})',
                                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              if (isManualTimingMode)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                                  child: const Text('MANUAL TIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(tr('next_prayer_in'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('- $countdownText',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('🌅 ${tr('sunrise')}: ${formatClock(sunriseTime)}', style: const TextStyle(fontSize: 11)),
                                Text('🌇 ${tr('sunset')}: ${formatClock(sunsetTime)}', style: const TextStyle(fontSize: 11)),
                                GestureDetector(
                                  onTap: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    setState(() => asrSchool = asrSchool == 0 ? 1 : 0);
                                    await prefs.setInt('asr_school', asrSchool);
                                    _fetchTimings();
                                  },
                                  child: Text(asrSchool == 0 ? 'SHAFI' : 'HANAFI',
                                      style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11)),
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
            const SizedBox(height: 18),

            Text(tr('soul_care'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: moods.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showMoodCureModal(moods[index]),
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF16323F), Color(0xFF10242D)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(moods[index]['emoji']!, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(moods[index]['label']!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr('todays_prayers'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16323F),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: _openTimeCustomizationSheet,
                  child: Text(tr('set_times_btn'), style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...prayerNames.map((String key) {
              int st = todayStatus[key] ?? 0;
              bool isNext = (key == nextPrayerName);
              return GestureDetector(
                onTap: () => _showStatusPicker(key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isNext ? const Color(0xFF153832) : const Color(0xFF10242D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isNext ? const Color(0xFFFFD700) : Colors.white10, width: isNext ? 1.5 : 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trPrayerName(key), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 3),
                          GestureDetector(
                            onTap: _openTimeCustomizationSheet,
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: isNext ? const Color(0xFFFFD700) : Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  formatClock(_activeTime(key)),
                                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit, size: 12, color: Colors.white38),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _statusBadge(st),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr('sunnah_habits'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                      Text('$sunnahDone/4 ✅', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...sunnahLabels.keys.map((String k) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: const Color(0xFF10B981),
                      title: Text(sunnahLabels[k]!, style: const TextStyle(fontSize: 13)),
                      value: sunnahDoneMap[k],
                      onChanged: (val) async {
                        final prefs = await SharedPreferences.getInstance();
                        final tKey = getDateKey(DateTime.now());
                        await prefs.setBool('sunnah_${tKey}_$k', val ?? false);
                        setState(() => sunnahDoneMap[k] = val ?? false);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
