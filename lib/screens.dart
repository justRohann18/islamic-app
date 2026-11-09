import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'main.dart';

// ---------------- 2. ULTRA-UNIQUE IMAN ANALYTICS & TRACKER TAB ----------------
class PrayerAnalyticsScreen extends StatefulWidget {
  const PrayerAnalyticsScreen({super.key});

  @override
  State<PrayerAnalyticsScreen> createState() => _PrayerAnalyticsScreenState();
}

class _PrayerAnalyticsScreenState extends State<PrayerAnalyticsScreen> {
  SharedPreferences? _prefs;
  int selectedPeriod = 0; // 0=Weekly, 1=Monthly, 2=Yearly
  DateTime selectedDate = DateTime.now();
  final List<String> prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, int> qazaBank = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var p in prayers) {
        qazaBank[p] = _prefs!.getInt('qazabank_$p') ?? 0;
      }
    });
  }

  int _getCountForDate(DateTime date) {
    int c = 0;
    for (var p in prayers) {
      if (isPrayerOffered(getPrayerStatus(_prefs, date, p))) c++;
    }
    return c;
  }

  int _calculateActiveStreak() {
    int streak = 0;
    DateTime d = DateTime.now();
    for (int i = 0; i < 60; i++) {
      int c = _getCountForDate(d.subtract(Duration(days: i)));
      if (c > 0) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  Future<void> _cycleStatusOnDate(DateTime date, String prayer) async {
    if (_prefs == null) return;
    int current = getPrayerStatus(_prefs, date, prayer);
    int next = (current + 1) % 5;
    String key = getDateKey(date);
    await _prefs!.setInt('status_${key}_$prayer', next);
    await _prefs!.setBool('track_${key}_$prayer', isPrayerOffered(next));
    HapticFeedback.lightImpact();
    setState(() {});
  }

  Future<void> _updateQazaBank(String prayer, int delta) async {
    if (_prefs == null) return;
    int next = math.max(0, (qazaBank[prayer] ?? 0) + delta);
    await _prefs!.setInt('qazabank_$prayer', next);
    setState(() => qazaBank[prayer] = next);
  }

  Future<void> _addMonthsToQazaBank(int months) async {
    if (_prefs == null) return;
    int days = months * 30;
    for (var p in prayers) {
      int next = (qazaBank[p] ?? 0) + days;
      await _prefs!.setInt('qazabank_$p', next);
      qazaBank[p] = next;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    int mAda = 0, mJamaat = 0, mQaza = 0;
    Map<String, int> prayerStrength = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

    for (int d = 1; d <= daysInMonth; d++) {
      DateTime dt = DateTime(now.year, now.month, d);
      for (var p in prayers) {
        int st = getPrayerStatus(_prefs, dt, p);
        if (isPrayerOffered(st)) {
          mAda++;
          prayerStrength[p] = (prayerStrength[p] ?? 0) + 1;
        }
        if (st == 1) mJamaat++;
        if (st == 3 || st == 4) mQaza++;
      }
    }

    int passedDays = math.max(1, now.day);
    double imanScore = ((mAda / (passedDays * 5)) * 100).clamp(0.0, 100.0);
    int streak = _calculateActiveStreak();
    String rank = imanScore >= 85
        ? '👑 Jamaat Champion'
        : (imanScore >= 60 ? '🌟 Istiqamah Star' : (imanScore >= 30 ? '🕌 Growing Musalli' : '🌱 Beginner'));
    int totalQazaRemaining = qazaBank.values.fold(0, (a, b) => a + b);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2932), Color(0xFF064E3B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 85,
                    height: 85,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: imanScore / 100.0,
                          strokeWidth: 9,
                          backgroundColor: Colors.black38,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${imanScore.toInt()}%',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                              const Text('Iman Score', style: TextStyle(fontSize: 9, color: Color(0xFFFFD700))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                          child: Text(rank, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        const SizedBox(height: 8),
                        Text('🔥 $streak Day Active Streak',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('🟢 $mJamaat Jamaat • ✅ $mAda Ada • 🟠 $mQaza Qaza',
                            style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  _periodTab('Weekly (7D)', 0),
                  _periodTab('Monthly (${now.month}/${now.year})', 1),
                  _periodTab('Yearly (${now.year})', 2),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (selectedPeriod == 0) _buildWeeklyChart(now),
            if (selectedPeriod == 1) _buildMonthlyCalendar(now, daysInMonth),
            if (selectedPeriod == 2) _buildYearlyOverview(now),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📅 Edit Date: ${getDateKey(selectedDate)}',
                          style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14)),
                      const Text('Tap box to cycle status', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: prayers.map((p) {
                      int st = getPrayerStatus(_prefs, selectedDate, p);
                      final cols = [const Color(0xFF16323F), const Color(0xFF10B981), const Color(0xFF3B82F6), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
                      final tags = ['None', 'Jamaat', 'OnTime', 'Qaza', 'Missed'];
                      return GestureDetector(
                        onTap: () => _cycleStatusOnDate(selectedDate, p),
                        child: Container(
                          width: 58,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: cols[st],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            children: [
                              Text(p, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(tags[st], style: const TextStyle(fontSize: 9, color: Colors.white)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🕌 Prayer-by-Prayer Strength (This Month)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  const SizedBox(height: 12),
                  ...prayers.map((p) {
                    int count = prayerStrength[p] ?? 0;
                    double ratio = (count / passedDays).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(trPrayerName(p), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('$count / $passedDays Days (${(ratio * 100).toInt()}%)',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 7,
                              backgroundColor: Colors.black38,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            ),
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
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A2639), Color(0xFF10242D)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🏦 Qaza-e-Umri Bank',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                      Text('Pending: $totalQazaRemaining',
                          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16323F)),
                        onPressed: () => _addMonthsToQazaBank(1),
                        child: const Text('+1 Month Qaza', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16323F)),
                        onPressed: () => _addMonthsToQazaBank(12),
                        child: const Text('+1 Year Qaza', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...prayers.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$p Qaza:', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Text('${qazaBank[p]}',
                                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                onPressed: () => _updateQazaBank(p, -1),
                                child: const Text('-1 Paid ✅', style: TextStyle(fontSize: 11, color: Colors.white)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.white54, size: 20),
                                onPressed: () => _updateQazaBank(p, 1),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _periodTab(String label, int idx) {
    bool active = selectedPeriod == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPeriod = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: active ? const Color(0xFF10B981) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Center(
            child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white60, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(DateTime now) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 7-Day Performance (Tap any bar to edit day)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700), fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                DateTime d = now.subtract(Duration(days: 6 - i));
                int c = _getCountForDate(d);
                bool sel = getDateKey(d) == getDateKey(selectedDate);
                double h = math.max(10.0, (c / 5.0) * 95.0);
                return GestureDetector(
                  onTap: () => setState(() => selectedDate = d),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('$c/5', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                      const SizedBox(height: 5),
                      Container(
                        width: 28,
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: c == 5
                                ? [const Color(0xFFFFD700), const Color(0xFF10B981)]
                                : [const Color(0xFF10B981), const Color(0xFF047857)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: sel ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(days[d.weekday - 1],
                          style: TextStyle(fontSize: 11, color: sel ? const Color(0xFFFFD700) : Colors.white60, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar(DateTime now, int daysInMonth) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
        itemCount: daysInMonth,
        itemBuilder: (ctx, idx) {
          DateTime d = DateTime(now.year, now.month, idx + 1);
          int c = _getCountForDate(d);
          bool sel = getDateKey(d) == getDateKey(selectedDate);
          Color col = c == 5 ? const Color(0xFF10B981) : (c >= 1 ? const Color(0xFF047857) : const Color(0xFF16323F));
          return GestureDetector(
            onTap: () => setState(() => selectedDate = d),
            child: Container(
              decoration: BoxDecoration(
                color: col,
                borderRadius: BorderRadius.circular(8),
                border: sel ? Border.all(color: const Color(0xFFFFD700), width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('$c/5', style: const TextStyle(fontSize: 8, color: Colors.white70)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearlyOverview(DateTime now) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(18)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.5),
        itemCount: 12,
        itemBuilder: (ctx, mIdx) {
          int m = mIdx + 1;
          int days = DateUtils.getDaysInMonth(now.year, m);
          int total = 0;
          for (int d = 1; d <= days; d++) {
            total += _getCountForDate(DateTime(now.year, m, d));
          }
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF16323F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: m == now.month ? const Color(0xFFFFD700) : Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(months[mIdx], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                Text('$total / ${days * 5}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------- 3. QURAN (114 SURAHS + HINDI/URDU/EN) & HADITH BOOKS ----------------
class LiveQuranScreen extends StatefulWidget {
  const LiveQuranScreen({super.key});

  @override
  State<LiveQuranScreen> createState() => _LiveQuranScreenState();
}

class _LiveQuranScreenState extends State<LiveQuranScreen> {
  int mainSection = 0; // 0 = Al-Quran (114 Surahs), 1 = Sahih Hadith Books
  List<dynamic> surahList = [];
  bool isLoading = true;
  String searchQuery = '';
  int selectedHadithCategory = 0;

  final List<String> hadithCategories = [
    '📚 All Sahih Hadiths',
    '📗 Sahih Al-Bukhari',
    '📘 Sahih Muslim',
    '🌟 40 Hadith Nawawi',
    '💖 Riyad-us-Saliheen (Manners)',
  ];

  final List<Map<String, String>> hadithCollection = const [
    {
      'book': 'Sahih Al-Bukhari • Hadith 1',
      'cat': '1',
      'arabic': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
      'en': 'Narrated Umar bin Al-Khattab (RA): The Prophet ﷺ said, "Actions are judged only by intentions, and every person will have only what they intended."',
      'hi': 'हज़रत उमर बिन ख़त्ताब (रज़ि.) से रिवायत है कि नबी करीम ﷺ ने फ़रमाया: "तमाम आमाल का दारोमदार नीयतों पर है, और हर इंसान को वही मिलेगा जिसकी उसने नीयत की।"',
      'ur': 'امیر المومنین عمر بن خطاب رضی اللہ عنہ سے روایت ہے کہ نبی کریم ﷺ نے فرمایا: ”اعمال کا دارومدار نیتوں پر ہے اور ہر شخص کے لیے وہی ہے جس کی اس نے نیت کی۔“',
      'ro': 'Nabi Kareem ﷺ ne farmaya: "Aamaal ka daromadar niyaton par hai, aur har insaan ko wahi milega jiski usne niyat ki."'
    },
    {
      'book': 'Sahih Al-Bukhari • Hadith 5027',
      'cat': '1',
      'arabic': 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
      'en': 'Narrated Uthman (RA): The Prophet ﷺ said, "The best among you (Muslims) are those who learn the Qur\'an and teach it to others."',
      'hi': 'हज़रत उस्मान (रज़ि.) से रिवायत है कि रसूलुल्लाह ﷺ ने फ़रमाया: "तुम में सबसे बेहतरीन इंसान वह है जो क़ुरआन सीखे और दूसरों को सिखाए।"',
      'ur': 'حضرت عثمان رضی اللہ عنہ سے روایت ہے کہ نبی اکرم ﷺ نے فرمایا: ”تم میں سب سے بہترین شخص وہ ہے جو قرآن سیکھے اور سکھائے۔“',
      'ro': 'Rasoolullah ﷺ ne farmaya: "Tum mein sabse behtareen wo hai jo Quran seekhe aur doosron ko sikhaye."'
    },
    {
      'book': 'Sahih Muslim • Hadith 223',
      'cat': '2',
      'arabic': 'الطُّهُورُ شَطْرُ الإِيمَانِ وَالْحَمْدُ لِلَّهِ تَمْلأُ الْمِيزَانَ',
      'en': 'The Messenger of Allah ﷺ said: "Cleanliness (Purity/Wudu) is half of faith (Iman), and saying Alhamdulillah fills the scale of good deeds."',
      'hi': 'रसूलुल्लाह ﷺ ने फ़रमाया: "पाकीज़गी (वुज़ू/सफ़ाई) आधा ईमान है, और अलहम्दुलिल्लाह कहना नेकियों के तराज़ू को भर देता है।"',
      'ur': 'رسول اللہ ﷺ نے فرمایا: ”پاکیزگی نصف ایمان ہے اور الحمد للہ میزان (اعمال کے ترازو) کو بھر دیتا ہے۔“',
      'ro': 'Rasoolullah ﷺ ne farmaya: "Pakeezgi (Wudu/Safai) aadha Iman hai, aur Alhamdulillah kehna Mizan (tarazu) ko bhar deta hai."'
    },
    {
      'book': 'Sahih Muslim • Hadith 2564',
      'cat': '2',
      'arabic': 'إِنَّ اللَّهَ لاَ يَنْظُرُ إِلَى صُوَرِكُمْ وَأَمْوََالِكُمْ وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ وَأَعْمَالِكُمْ',
      'en': 'The Prophet ﷺ said: "Verily, Allah does not look at your appearances or your wealth, rather He looks at your hearts and your deeds."',
      'hi': 'नबी करीम ﷺ ने फ़रमाया: "बेशक अल्लाह तुम्हारी सूरतों और तुम्हारे माल को नहीं देखता, बल्कि वह तुम्हारे दिलों और तुम्हारे आमाल (कर्मों) को देखता है।"',
      'ur': 'نبی کریم ﷺ نے فرمایا: ”بے شک اللہ تمہاری صورتوں اور تمہارے مالوں کو نہیں دیکھتا، بلکہ وہ تمہارے دلوں اور تمہارے اعمال کو دیکھتا ہے۔“',
      'ro': 'Nabi ﷺ ne farmaya: "Beshak Allah tumhari soorton aur maal ko nahi dekhta, balki tumhare dilon aur aamaal ko dekhta hai."'
    },
    {
      'book': '40 Hadith Nawawi • Hadith 13',
      'cat': '3',
      'arabic': 'لاَ يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
      'en': 'Anas (RA) reported that the Prophet ﷺ said: "None of you truly believes until he loves for his brother what he loves for himself."',
      'hi': 'हज़रत अनस (रज़ि.) से रिवायत है कि नबी ﷺ ने फ़रमाया: "तुम में से कोई शख़्स उस वक़्त तक कामिल मोमिन नहीं हो सकता जब तक वह अपने भाई के लिए भी वही पसंद न करे जो अपने लिए पसंद करता है।"',
      'ur': 'نبی اکرم ﷺ نے فرمایا: ”تم میں سے کوئی شخص اس وقت تک کامل مومن نہیں ہو سکتا جب تک کہ وہ اپنے بھائی کے لیے وہی پسند نہ کرے جو اپنے نفس کے لیے پسند کرتا ہے۔“',
      'ro': 'Nabi ﷺ ne farmaya: "Tum mein se koi us waqt tak kamil Momin nahi ho sakta jab tak apne bhai ke liye wahi pasand na kare jo apne liye karta hai."'
    },
    {
      'book': '40 Hadith Nawawi • Hadith 18',
      'cat': '3',
      'arabic': 'اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا',
      'en': 'The Prophet ﷺ said: "Fear Allah wherever you are, follow up a bad deed with a good deed and it will wipe it out, and behave with people with good character."',
      'hi': 'नबी ﷺ ने फ़रमाया: "तुम जहाँ कहीं भी हो अल्लाह से डरो, और अगर कोई गुनाह हो जाए तो उसके बाद नेकी कर लो, वह नेकी उस गुनाह को मिटा देगी।"',
      'ur': 'نبی ﷺ نے فرمایا: ”تم جہاں کہیں بھی ہو اللہ سے ڈرو، اور برائی کے بعد نیکی کرو وہ اس کو مٹا دے گی، اور لوگوں کے ساتھ اچھے اخلاق سے پیش آؤ۔“',
      'ro': 'Nabi ﷺ ne farmaya: "Jahan kahin bhi ho Allah se daro, aur burai ke baad neki kar lo, wo neki us burai ko mita degi."'
    },
    {
      'book': 'Riyad-us-Saliheen • Hadith 601',
      'cat': '4',
      'arabic': 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
      'en': 'Messenger of Allah ﷺ said: "Your smiling in the face of your brother is a charity (Sadaqah) for you." (Jami at-Tirmidhi)',
      'hi': 'रसूलुल्लाह ﷺ ने फ़रमाया: "अपने भाई से मुस्कुरा कर मिलना भी तुम्हारे लिए सदक़ा (नेकी) है।"',
      'ur': 'رسول اللہ ﷺ نے فرمایا: ”تمہارا اپنے بھائی کے سامنے مسکرانا بھی تمہارے لیے صدقہ ہے۔“',
      'ro': 'Rasoolullah ﷺ ne farmaya: "Apne bhai se muskura kar milna bhi tumhare liye Sadqah hai."'
    },
    {
      'book': 'Riyad-us-Saliheen • Hadith 1388',
      'cat': '4',
      'arabic': 'مَنْ صَلَّى الْبَرْدَيْنِ دَخَلَ الْجَنَّةَ',
      'en': 'Abu Musa (RA) reported: The Messenger of Allah ﷺ said, "Whoever prays the two cool prayers (Fajr and Asr on time) will enter Paradise (Jannah)."',
      'hi': 'रसूलुल्लाह ﷺ ने फ़रमाया: "जो शख़्स दो ठंडी नमाज़ें (यानी फ़ज्र और अस्र वक़्त पर) पढ़ता है, वह जन्नत में दाख़िल होगा।"',
      'ur': 'رسول اللہ ﷺ نے فرمایا: ”جو شخص دو ٹھنڈی نمازیں (فجر اور عصر) پابندی سے پڑھے گا وہ جنت میں داخل ہوگا۔“',
      'ro': 'Rasoolullah ﷺ ne farmaya: "Jo shaks Fajr aur Asr ki namaz pabandi se padhega, wo Jannat mein dakhil hoga."'
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchAll114Surahs();
  }

  Future<void> _fetchAll114Surahs() async {
    try {
      final res = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
      if (res.statusCode == 200) {
        setState(() {
          surahList = json.decode(res.body)['data'];
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Switcher: Al-Quran vs Sahih Hadith Books
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => mainSection = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: mainSection == 0 ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]) : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('📖 Al-Quran (114)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => mainSection = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: mainSection == 1 ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]) : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('📜 Sahih Hadith', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: mainSection == 0 ? _buildQuranSection() : _buildHadithSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuranSection() {
    final filtered = surahList.where((s) => s['englishName'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => setState(() => searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search 114 Surahs (e.g. Yaseen, Mulk, Kahf, Baqarah)...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
            filled: true,
            fillColor: const Color(0xFF10242D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final s = filtered[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10242D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF16323F),
                          child: Text('${s['number']}', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(s['englishName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s['englishNameTranslation']} • ${s['numberOfAyahs']} Ayahs (${s['revelationType']})',
                            style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        trailing: Text(s['name'], style: const TextStyle(fontSize: 20, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SurahDetailAudioPage(surahNumber: s['number'], surahName: s['englishName']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHadithSection() {
    final filteredHadiths = hadithCollection.where((h) {
      if (selectedHadithCategory == 0) return true;
      return h['cat'] == selectedHadithCategory.toString();
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hadith Book Filter Chips
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hadithCategories.length,
            itemBuilder: (ctx, idx) {
              bool sel = selectedHadithCategory == idx;
              return GestureDetector(
                onTap: () => setState(() => selectedHadithCategory = idx),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFFFD700) : const Color(0xFF10242D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hadithCategories[idx],
                    style: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            itemCount: filteredHadiths.length,
            itemBuilder: (ctx, i) {
              final h = filteredHadiths[i];
              String transText = h[appLang] ?? h['en']!;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF10242D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF16323F), borderRadius: BorderRadius.circular(10)),
                          child: Text('📜 ${h['book']}',
                              style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: Color(0xFF10B981)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${h['arabic']}\n\n$transText\n(${h['book']})'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ Hadith copied to share on WhatsApp!')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      h['arabic']!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 23, color: Colors.white, height: 1.7, fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Colors.white12, height: 22),
                    Text(
                      transText,
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SurahDetailAudioPage extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  const SurahDetailAudioPage({super.key, required this.surahNumber, required this.surahName});

  @override
  State<SurahDetailAudioPage> createState() => _SurahDetailAudioPageState();
}

class _SurahDetailAudioPageState extends State<SurahDetailAudioPage> {
  List<dynamic> arabicAyahs = [];
  List<dynamic> transAyahs = [];
  bool isLoading = true;
  String quranEdition = 'en.asad'; // 'en.asad'=English, 'hi.hindi'=Hindi, 'ur.jalandhry'=Urdu
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? playingIndex;

  @override
  void initState() {
    super.initState();
    if (appLang == 'hi') quranEdition = 'hi.hindi';
    if (appLang == 'ur') quranEdition = 'ur.jalandhry';
    _loadSurahContent();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playingIndex = null);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSurahContent() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('https://api.alquran.cloud/v1/surah/${widget.surahNumber}/editions/ar.alafasy,$quranEdition');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        setState(() {
          arabicAyahs = data[0]['ayahs'];
          transAyahs = data[1]['ayahs'];
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _playAyahAudio(int index, String audioUrl) async {
    if (playingIndex == index) {
      await _audioPlayer.stop();
      setState(() => playingIndex = null);
    } else {
      setState(() => playingIndex = index);
      await _audioPlayer.play(UrlSource(audioUrl));
    }
  }

  Widget _langBtn(String label, String editionCode) {
    bool sel = quranEdition == editionCode;
    return GestureDetector(
      onTap: () {
        setState(() => quranEdition = editionCode);
        _loadSurahContent();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFD700) : const Color(0xFF0A1920),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Surah ${widget.surahName}', style: const TextStyle(fontSize: 17)),
        backgroundColor: const Color(0xFF047857),
        actions: [
          Center(child: _langBtn('EN', 'en.asad')),
          Center(child: _langBtn('हिंदी', 'hi.hindi')),
          Center(child: _langBtn('اردو', 'ur.jalandhry')),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: arabicAyahs.length,
              itemBuilder: (ctx, i) {
                final ar = arabicAyahs[i];
                final tr = transAyahs[i];
                bool isPlaying = (playingIndex == i);
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10242D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isPlaying ? const Color(0xFFFFD700) : Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF16323F),
                            child: Text('${ar['numberInSurah']}', style: const TextStyle(fontSize: 11, color: Color(0xFFFFD700))),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: isPlaying ? const Color(0xFFFFD700) : const Color(0xFF10B981)),
                            onPressed: () => _playAyahAudio(i, ar['audio']),
                            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow, color: Colors.black, size: 18),
                            label: Text(isPlaying ? 'Stop' : 'Listen Tilawat',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(ar['text'],
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 25, color: Colors.white, height: 1.8, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(tr['text'], style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- 4. 3D QIBLA DIRECTION FINDER ----------------
class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  double qiblaAngle = 277.0;
  double manualRotation = 0.0;
  String locationName = 'Rupahi';

  @override
  void initState() {
    super.initState();
    _initQibla();
  }

  Future<void> _initQibla() async {
    final prefs = await SharedPreferences.getInstance();
    double lat = prefs.getDouble('lat') ?? 26.4167;
    double lon = prefs.getDouble('lon') ?? 92.7333;
    const double kLat = 21.422487 * math.pi / 180.0;
    const double kLon = 39.826206 * math.pi / 180.0;
    double phi = lat * math.pi / 180.0, lam = lon * math.pi / 180.0;
    double y = math.sin(kLon - lam);
    double x = math.cos(phi) * math.tan(kLat) - math.sin(phi) * math.cos(kLon - lam);
    setState(() {
      locationName = prefs.getString('loc_name') ?? 'Rupahi';
      qiblaAngle = ((math.atan2(y, x) * 180.0 / math.pi) + 360.0) % 360.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    double diff = (qiblaAngle - manualRotation + 360.0) % 360.0;
    bool aligned = diff < 10.0 || diff > 350.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧭 3D Qibla Direction Finder',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 8),
            Text('📍 $locationName • Bearing: ${qiblaAngle.toStringAsFixed(1)}° W-NW',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: aligned ? const Color(0xFF064E3B) : const Color(0xFF10242D),
                    border: Border.all(color: aligned ? const Color(0xFF10B981) : const Color(0xFFFFD700), width: 4),
                  ),
                ),
                Transform.rotate(
                  angle: -manualRotation * (math.pi / 180.0),
                  child: const SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(top: 8, child: Text('N', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 18))),
                        Positioned(bottom: 8, child: Text('S', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        Positioned(right: 8, child: Text('E', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        Positioned(left: 8, child: Text('W', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: (qiblaAngle - manualRotation) * (math.pi / 180.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🕋', style: TextStyle(fontSize: 34)),
                      Container(width: 6, height: 80, color: const Color(0xFFFFD700)),
                      const SizedBox(height: 55),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text('Rotate dial below to align North (N):', style: TextStyle(fontSize: 12, color: Colors.white60)),
            Slider(
              activeColor: const Color(0xFFFFD700),
              min: 0,
              max: 360,
              value: manualRotation,
              onChanged: (v) => setState(() => manualRotation = v),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 5. ISLAMIC HUB: TASBEEH + DUAS + 99 NAMES + ZAKAT ----------------
class IslamicToolsHubScreen extends StatefulWidget {
  const IslamicToolsHubScreen({super.key});

  @override
  State<IslamicToolsHubScreen> createState() => _IslamicToolsHubScreenState();
}

class _IslamicToolsHubScreenState extends State<IslamicToolsHubScreen> {
  int tasbeehCount = 0;
  final TextEditingController goldCtrl = TextEditingController();
  final TextEditingController silverCtrl = TextEditingController();
  final TextEditingController cashCtrl = TextEditingController();
  double calculatedZakat = 0.0;

  final List<Map<String, String>> dailyDuas = const [
    {
      'title': '1. Dua Before Sleeping (सोने से पहले की दुआ)',
      'arabic': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      'trans': 'In Your name O Allah, I die (sleep) and I live (wake up).'
    },
    {
      'title': '2. Dua Leaving Home (घर से निकलने की दुआ)',
      'arabic': 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      'trans': 'In the name of Allah, I place my trust in Allah; there is no power and no strength except with Allah.'
    },
    {
      'title': '3. Dua for Parents (वालिदैन के लिए दुआ)',
      'arabic': 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      'trans': 'My Lord! Have mercy upon them as they brought me up when I was small. (Quran 17:24)'
    },
    {
      'title': '4. Dua for Knowledge (इल्म में इज़ाफ़े की दुआ)',
      'arabic': 'رَبِّ زِدْنِي عِلْمًا',
      'trans': 'My Lord, increase me in knowledge. (Quran 20:114)'
    },
  ];

  void _calculateZakat() {
    double g = double.tryParse(goldCtrl.text) ?? 0;
    double s = double.tryParse(silverCtrl.text) ?? 0;
    double c = double.tryParse(cashCtrl.text) ?? 0;
    setState(() => calculatedZakat = (g + s + c) * 0.025);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✨ Islamic Hub (Tasbeeh, Duas & Zakat)',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 16),

            // Digital Tasbeeh
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text('📿 Digital Tasbeeh Counter', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => tasbeehCount++);
                    },
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF10B981),
                      child: Text('$tasbeehCount', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  TextButton(onPressed: () => setState(() => tasbeehCount = 0), child: const Text('Reset Counter')),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Masnoon Duas Section
            const Text('🤲 Essential Masnoon Duas (Hisnul Muslim)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 10),
            ...dailyDuas.map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF10242D), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(d['title']!, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(d['arabic']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 22, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(d['trans']!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),

            // Zakat Calculator
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧮 Smart Zakat Calculator (2.5%)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  const SizedBox(height: 12),
                  _zakatInput(goldCtrl, 'Gold Value (₹)'),
                  const SizedBox(height: 10),
                  _zakatInput(silverCtrl, 'Silver Value (₹)'),
                  const SizedBox(height: 10),
                  _zakatInput(cashCtrl, 'Cash / Bank Savings (₹)'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      onPressed: _calculateZakat,
                      child: const Text('Calculate Zakat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Total Payable Zakat: ₹ ${calculatedZakat.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
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

  Widget _zakatInput(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF16323F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
