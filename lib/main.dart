import 'package:flutter/material.dart';

void main() {
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noor - Islamic App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A191E), // Deep Royal Dark
        primaryColor: const Color(0xFF10B981), // Emerald Green
        cardColor: const Color(0xFF122830),
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

  // Shared state for Prayer Tracker
  Map<String, Map<String, dynamic>> prayers = {
    'Fajr': {'time': '05:15 AM', 'done': false, 'hindi': 'फज्र'},
    'Dhuhr': {'time': '01:30 PM', 'done': false, 'hindi': 'ज़ुहर'},
    'Asr': {'time': '04:45 PM', 'done': false, 'hindi': 'अस्र'},
    'Maghrib': {'time': '06:20 PM', 'done': false, 'hindi': 'मग़रिब'},
    'Isha': {'time': '08:00 PM', 'done': false, 'hindi': 'ईशा'},
  };

  void togglePrayer(String key, bool val) {
    setState(() {
      prayers[key]!['done'] = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(prayers: prayers, onToggle: togglePrayer),
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
          backgroundColor: const Color(0xFF0D2128),
          selectedItemColor: const Color(0xFFFFD700), // Gold
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.touch_app), label: 'Tasbeeh'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Duas'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: '99 Names'),
          ],
        ),
      ),
    );
  }
}

// ---------------- 1. DASHBOARD SCREEN ----------------
class DashboardScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> prayers;
  final Function(String, bool) onToggle;

  const DashboardScreen({super.key, required this.prayers, required this.onToggle});

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
            // Top Greeting & Hijri Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assalamu Alaikum 👋', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Noor Islamic Pro', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A44),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                  ),
                  child: const Text('🌙 1448 Hijri', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hero Banner - Next Prayer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF064E3B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DAILY TRACKER STATUS', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
                      Icon(Icons.query_builder, color: Color(0xFFFFD700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$completed of 5 Prayers Completed', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.black26,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ayah of the Day Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF122830),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18),
                      SizedBox(width: 8),
                      Text('Ayah of the Day', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
                      style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      '"Beshak, har mushkil ke sath aasani hai." (Surah Ash-Sharh 94:5)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Prayer Tracker List
            const Text('Aaj ki Namazein (Prayer Tracker)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            ...prayers.keys.map((String key) {
              bool isDone = prayers[key]!['done'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFF064E3B).withOpacity(0.6) : const Color(0xFF122830),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDone ? const Color(0xFF10B981) : Colors.white10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDone ? const Color(0xFF10B981) : const Color(0xFF1E3A44),
                    child: Icon(
                      isDone ? Icons.check : Icons.access_time,
                      color: isDone ? Colors.white : const Color(0xFFFFD700),
                    ),
                  ),
                  title: Text('$key (${prayers[key]!['hindi']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(prayers[key]!['time'], style: const TextStyle(color: Colors.white60)),
                  trailing: Switch(
                    activeColor: const Color(0xFFFFD700),
                    activeTrackColor: const Color(0xFF10B981),
                    value: isDone,
                    onChanged: (val) => onToggle(key, val),
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

// ---------------- 2. TASBEEH COUNTER SCREEN ----------------
class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int count = 0;
  int target = 33;
  int selectedZikr = 0;

  final List<Map<String, String>> azkar = [
    {'arabic': 'سُبْحَانَ اللَّهِ', 'roman': 'SubhanAllah', 'meaning': 'Allah Paak hai'},
    {'arabic': 'الْحَمْدُ لِلَّهِ', 'roman': 'Alhamdulillah', 'meaning': 'Sab tareef Allah ke liye hai'},
    {'arabic': 'اللَّهُ أَكْبَرُ', 'roman': 'Allahu Akbar', 'meaning': 'Allah sabse bada hai'},
    {'arabic': 'أَسْتَغْفِرُ اللَّهَ', 'roman': 'Astaghfirullah', 'meaning': 'Main Allah se maafi mangta hoon'},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('📿 Digital Tasbeeh', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 20),

            // Zikr Selector Chips
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: azkar.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedZikr == index;
                  return GestureDetector(
                    onTap: () => setState(() {
                      selectedZikr = index;
                      count = 0;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF122830),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: isSelected ? const Color(0xFFFFD700) : Colors.white24),
                      ),
                      child: Text(azkar[index]['roman']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Zikr Display Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF122830),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(azkar[selectedZikr]['arabic']!, style: const TextStyle(fontSize: 36, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(azkar[selectedZikr]['roman']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(azkar[selectedZikr]['meaning']!, style: const TextStyle(fontSize: 14, color: Colors.white60)),
                ],
              ),
            ),
            const Spacer(),

            // Giant Glowing Tap Button
            GestureDetector(
              onTap: () {
                setState(() {
                  count++;
                });
              },
              child: Container(
                width: 210,
                height: 210,
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
                    Text('$count', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Target: $target', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 6),
                    const Text('TAP HERE', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A44)),
                  onPressed: () => setState(() => count = 0),
                  icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
                  label: const Text('Reset', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A44)),
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

// ---------------- 3. DAILY DUAS SCREEN ----------------
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
                      color: const Color(0xFF122830),
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

// ---------------- 4. 99 NAMES OF ALLAH SCREEN ----------------
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
                        colors: [Color(0xFF122830), Color(0xFF0D2128)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
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
   
