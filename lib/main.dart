import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noor - Islamic Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF071318),
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
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DashboardScreen(),
      const QuranScreen(),
      const TasbeehScreen(),
      const DuasScreen(),
      const AsmaUlHusnaScreen(),
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
          backgroundColor: const Color(0xFF0A1920),
          selectedItemColor: const Color(0xFFFFD700),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: 'Quran'),
            BottomNavigationBarItem(icon: Icon(Icons.touch_app), label: 'Tasbeeh'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Duas'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: '99 Names'),
          ],
        ),
      ),
    );
  }
}

// ---------------- 1. LIVE DASHBOARD SCREEN ----------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedCity = 'Mumbai';
  String hijriDate = 'Loading...';
  bool isLoading = true;

  final List<String> cities = [
    'Mumbai', 'Delhi', 'Hyderabad', 'Lucknow', 'Kolkata', 
    'Bangalore', 'Bhopal', 'Patna', 'Srinagar', 'Makkah', 'Madinah', 'Dubai'
  ];

  Map<String, Map<String, dynamic>> prayers = {
    'Fajr': {'time': '--:--', 'done': false, 'hindi': 'फज्र'},
    'Dhuhr': {'time': '--:--', 'done': false, 'hindi': 'ज़ुहर'},
    'Asr': {'time': '--:--', 'done': false, 'hindi': 'अस्र'},
    'Maghrib': {'time': '--:--', 'done': false, 'hindi': 'मग़रिब'},
    'Isha': {'time': '--:--', 'done': false, 'hindi': 'ईशा'},
  };

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCity = prefs.getString('city') ?? 'Mumbai';
      for (var key in prayers.keys) {
        prayers[key]!['done'] = prefs.getBool('prayer_$key') ?? false;
      }
    });
    _fetchPrayerTimes(selectedCity);
  }

  Future<void> _fetchPrayerTimes(String city) async {
    setState(() => isLoading = true);
    try {
      String country = (city == 'Makkah' || city == 'Madinah') ? 'Saudi Arabia' : (city == 'Dubai' ? 'UAE' : 'India');
      final url = Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final timings = data['timings'];
        final hijri = data['date']['hijri'];

        setState(() {
          prayers['Fajr']!['time'] = timings['Fajr'];
          prayers['Dhuhr']!['time'] = timings['Dhuhr'];
          prayers['Asr']!['time'] = timings['Asr'];
          prayers['Maghrib']!['time'] = timings['Maghrib'];
          prayers['Isha']!['time'] = timings['Isha'];
          hijriDate = '${hijri['day']} ${hijri['month']['en']} ${hijri['year']}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hijriDate = '1448 Hijri';
        isLoading = false;
      });
    }
  }

  Future<void> _togglePrayer(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_$key', val);
    setState(() {
      prayers[key]!['done'] = val;
    });
  }

  Future<void> _changeCity(String? newCity) async {
    if (newCity == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', newCity);
    setState(() => selectedCity = newCity);
    _fetchPrayerTimes(newCity);
  }

  @override
  Widget build(BuildContext context) {
    int completed = prayers.values.where((e) => e['done'] == true).length;
    double progress = completed / 5.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar with City Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assalamu Alaikum 👋', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('🌙 $hijriDate', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                // City Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16323F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCity,
                      dropdownColor: const Color(0xFF10242D),
                      icon: const Icon(Icons.location_on, color: Color(0xFFFFD700), size: 18),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      onChanged: _changeCity,
                      items: cities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text('$city '),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hero Progress Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF064E3B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF047857).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6)),
                ],
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📍 LIVE TIMINGS: ${selectedCity.toUpperCase()}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      if (isLoading)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      else
                        const Icon(Icons.cloud_done, color: Colors.white70, size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('$completed of 5 Prayers Offered', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(completed == 5 ? 'MashaAllah! Aaj ki saari namazein mukammal!' : 'Data phone mein auto-save ho raha hai', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.black38,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Prayer Tracker Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Aaj ki Namazein', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                TextButton(
                  onPressed: () async {
                    for (var k in prayers.keys) {
                      await _togglePrayer(k, false);
                    }
                  },
                  child: const Text('Reset All', style: TextStyle(color: Color(0xFFFFD700), fontSize: 13)),
                )
              ],
            ),
            const SizedBox(height: 6),

            // Prayer Cards
            ...prayers.keys.map((String key) {
              bool isDone = prayers[key]!['done'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFF064E3B).withOpacity(0.5) : const Color(0xFF10242D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDone ? const Color(0xFF10B981) : Colors.white10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDone ? const Color(0xFF10B981) : const Color(0xFF16323F),
                    child: Icon(
                      isDone ? Icons.check : Icons.access_time,
                      color: isDone ? Colors.white : const Color(0xFFFFD700),
                    ),
                  ),
                  title: Text('$key (${prayers[key]!['hindi']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('Waqt: ${prayers[key]!['time']}', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w500)),
                  trailing: Switch(
                    activeColor: const Color(0xFFFFD700),
                    activeTrackColor: const Color(0xFF10B981),
                    value: isDone,
                    onChanged: (val) => _togglePrayer(key, val),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ---------------- 2. QURAN MINI READER SCREEN ----------------
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  final List<Map<String, String>> surahs = const [
    {
      'name': '1. Surah Al-Fatiha (सूरह अल-फ़ातिहा)',
      'ayahs': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۝ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ ۝',
      'translation': 'Shuru Allah ke naam se jo bada meherban nihayat reham wala hai. Sab tareef Allah Ta\'ala ke liye hai jo tamam jahanon ka palne wala hai. Bada meherban nihayat reham karne wala. Badle ke din (Qayamat) ka malik hai. Hum sirf teri hi ibadat karte hain aur sirf tujhi se madad chahte hain. Humein seedha rasta dikha. Un logon ka rasta jin par tu ne in\'aam kiya, un ka nahi jin par ghazab kiya gaya aur na gumrahon ka.'
    },
    {
      'name': '2. Ayat-ul-Kursi (आयतुल कुर्सी)',
      'ayahs': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ ۝',
      'translation': 'Allah wo hai jiske siwa koi ma\'bood nahi, wo hamesha zinda rehne wala aur sab ko thamne wala hai. Use na oongh aati hai na neend. Jo kuch aasmano aur zameen mein hai sab usi ka hai...'
    },
    {
      'name': '3. Surah Al-Ikhlas (सूरह अल-इख़लास)',
      'ayahs': 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ ۝',
      'translation': 'Keh dijiye ki wo Allah ek hai. Allah be-niyaz hai (sab uske mohtaj hain). Na uski koi aulad hai aur na wo kisi ki aulad hai. Aur na koi uske barabar ka hai.'
    },
    {
      'name': '4. Surah Al-Falaq (सूरह अल-फ़लक़)',
      'ayahs': 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِنْ شَرِّ مَا خَلَقَ ۝ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ ۝',
      'translation': 'Keh dijiye ki main subah ke Rab ki panah mein aata hoon. Har us cheez ke shar se jo usne paida ki. Aur andheri raat ki burai se jab uska andhera phail jaye. Aur girahon (knots) mein phoonkne waliyon ke shar se. Aur hasad (jalan) karne wale ke shar se jab wo hasad kare.'
    },
    {
      'name': '5. Surah An-Nas (सूरह अन-नास)',
      'ayahs': 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ ۝',
      'translation': 'Keh dijiye ki main insano ke Rab ki panah mangta hoon. Insano ke Badshah ki. Insano ke Ma\'bood ki. Waswasa dalne wale peeche hat jane wale ke shar se. Jo logon ke seeno mein waswasa dalta hai. (Chahe wo) Jinnat mein se ho ya insano mein se.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📖 Al-Quran (Rozana Tilawat)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 6),
            const Text('Namaz aur hifazat ke liye zaroori Suratein', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: surahs.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10242D),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(surahs[index]['name']!, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(color: Colors.white12, height: 24),
                        Text(
                          surahs[index]['ayahs']!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 24, color: Colors.white, height: 1.8, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            surahs[index]['translation']!,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 3. TASBEEH COUNTER (WITH MEMORY) ----------------
class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int count = 0;
  int totalAllTime = 0;
  int target = 33;
  int selectedZikr = 0;

  final List<Map<String, String>> azkar = [
    {'arabic': 'سُبْحَانَ اللَّهِ', 'roman': 'SubhanAllah', 'meaning': 'Allah Paak hai'},
    {'arabic': 'الْحَمْدُ لِلَّهِ', 'roman': 'Alhamdulillah', 'meaning': 'Sab tareef Allah ke liye hai'},
    {'arabic': 'اللَّهُ أَكْبَرُ', 'roman': 'Allahu Akbar', 'meaning': 'Allah sabse bada hai'},
    {'arabic': 'أَسْتَغْفِرُ اللَّهَ', 'roman': 'Astaghfirullah', 'meaning': 'Main Allah se maafi mangta hoon'},
    {'arabic': 'صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ', 'roman': 'Durood Shareef', 'meaning': 'Allah ki rehmat ho Nabi ﷺ par'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTasbeeh();
  }

  Future<void> _loadTasbeeh() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      count = prefs.getInt('tasbeeh_count') ?? 0;
      totalAllTime = prefs.getInt('tasbeeh_total') ?? 0;
    });
  }

  Future<void> _increment() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      count++;
      totalAllTime++;
    });
    await prefs.setInt('tasbeeh_count', count);
    await prefs.setInt('tasbeeh_total', totalAllTime);
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => count = 0);
    await prefs.setInt('tasbeeh_count', 0);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📿 Digital Tasbeeh', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF16323F), borderRadius: BorderRadius.circular(15)),
                  child: Text('Total Zikr: $totalAllTime', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Zikr Selector Chips
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: azkar.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedZikr == index;
                  return GestureDetector(
                    onTap: () => setState(() => selectedZikr = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF10242D),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: isSelected ? const Color(0xFFFFD700) : Colors.white24),
                      ),
                      child: Text(azkar[index]['roman']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Zikr Display Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10242D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(azkar[selectedZikr]['arabic']!, style: const TextStyle(fontSize: 32, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(azkar[selectedZikr]['roman']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(azkar[selectedZikr]['meaning']!, style: const TextStyle(fontSize: 13, color: Colors.white60)),
                ],
              ),
            ),
            const Spacer(),

            // Giant Glowing Tap Button
            GestureDetector(
              onTap: _increment,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 25, spreadRadius: 5),
                  ],
                  border: Border.all(color: const Color(0xFFFFD700), width: 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$count', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Target: $target', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 6),
                    const Text('TAP TO COUNT', style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // Reset & Target Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16323F)),
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
                  label: const Text('Reset Counter', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16323F)),
                  onPressed: () => setState(() => target = target == 33 ? 99 : (target == 99 ? 1000 : 33)),
                  icon: const Icon(Icons.flag, color: Color(0xFFFFD700)),
                  label: Text('Goal: $target', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 4. DAILY DUAS SCREEN ----------------
class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  final List<Map<String, String>> duas = const [
    {
      'title': '1. Sone se pehle ki Dua',
      'arabic': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      'roman': 'Bismika Allahumma amootu wa ahya',
      'meaning': 'Aye Allah! Main tere hi naam se marta (sota) hoon aur jeeta (jagta) hoon.'
    },
    {
      'title': '2. Neend se jagne ki Dua',
      'arabic': 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      'roman': 'Alhamdu lillahil-ladhi ahyana ba\'da ma amatana wa ilayhin-nushoor',
      'meaning': 'Tamam tareefein Allah ke liye hain jisne humein maut (neend) dene ke baad zindagi bakshi.'
    },
    {
      'title': '3. Ghar se nikalne ki Dua',
      'arabic': 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      'roman': 'Bismillahi, tawakkaltu \'alallahi, la hawla wa la quwwata illa billah',
      'meaning': 'Allah ke naam ke sath, maine Allah par bharosa kiya, gunahon se bachne aur neki karne ki taqat Allah hi ki taraf se hai.'
    },
    {
      'title': '4. Ilm mein izafe ki Dua',
      'arabic': 'رَبِّ زِدْنِي عِلْمًا',
      'roman': 'Rabbi zidni \'ilma',
      'meaning': 'Aye mere Rab! Mere ilm (knowledge) mein izafa farma.'
    },
    {
      'title': '5. Walidain (Parents) ke liye Dua',
      'arabic': 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      'roman': 'Rabbir-hamhuma kama rabbayani sagheera',
      'meaning': 'Aye mere Rab! Un dono par reham farma jaisa ki unhone bachpan mein meri parwarish ki.'
    },
  ];
              @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🤲 Masnoon Duayein', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 6),
            const Text('Rozmarra ki zindagi mein parhi jane wali zaroori duayein', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: duas.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10242D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(duas[index]['title']!, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(color: Colors.white12, height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            duas[index]['arabic']!,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 24, color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(duas[index]['roman']!, style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(duas[index]['meaning']!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 5. 99 NAMES OF ALLAH SCREEN ----------------
class AsmaUlHusnaScreen extends StatelessWidget {
  const AsmaUlHusnaScreen({super.key});

  final List<Map<String, String>> names = const [
    {'arabic': 'اللَّهُ', 'name': 'Allah', 'meaning': 'The Greatest Name'},
    {'arabic': 'الرَّحْمَنُ', 'name': 'Ar-Rahman', 'meaning': 'Bada Meherban'},
    {'arabic': 'الرَّحِيمُ', 'name': 'Ar-Raheem', 'meaning': 'Nihayat Reham Wala'},
    {'arabic': 'الْمَلِكُ', 'name': 'Al-Malik', 'meaning': 'Haqeeqi Badshah'},
    {'arabic': 'الْقُدُّوسُ', 'name': 'Al-Quddus', 'meaning': 'Har Aib se Paak'},
    {'arabic': 'السَّلَامُ', 'name': 'As-Salam', 'meaning': 'Salamati Dene Wala'},
    {'arabic': 'الْمُؤْمِنُ', 'name': 'Al-Mu\'min', 'meaning': 'Aman Dene Wala'},
    {'arabic': 'الْمُهَيْمِنُ', 'name': 'Al-Muhaymin', 'meaning': 'Nigrani Karne Wala'},
    {'arabic': 'الْعَزِيزُ', 'name': 'Al-Aziz', 'meaning': 'Sab par Ghalib'},
    {'arabic': 'الْجَبَّارُ', 'name': 'Al-Jabbar', 'meaning': 'Sab se Zabardast'},
    {'arabic': 'الْخَالِقُ', 'name': 'Al-Khaliq', 'meaning': 'Paida Karne Wala'},
    {'arabic': 'الْغَفَّارُ', 'name': 'Al-Ghaffar', 'meaning': 'Bada Bakshne Wala'},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✨ Asma-ul-Husna', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 6),
            const Text('Allah Ta\'ala ke Mubarak aur Paak Naam', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: names.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10242D), Color(0xFF0A1920)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const 
                                         Color(0xFFFFD700).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(names[index]['arabic']!, style: const TextStyle(fontSize: 28, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(names[index]['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(names[index]['meaning']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
