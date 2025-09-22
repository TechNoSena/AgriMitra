import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'farm_data_provider.dart';
import 'searchpage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'rover_page.dart';
import 'market_prices_page.dart';
import 'aboutpage.dart';
import 'ai_assistant_screen.dart';
import 'profile_page.dart';

// Global Providers for sharing data across the app
final predictionProvider = StateProvider<String>((ref) => "Initialize Sensor");
final geminiRecommendationProvider = StateProvider<BreedingRecommendation?>(
  (ref) => null,
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late PageController _pageController;

  final List<FarmArea> _farmAreas = [
    const FarmArea(name: 'Area A', acres: 5.2, icon: Icons.grass),
    const FarmArea(name: 'Area B', acres: 2.5, icon: Icons.park),
    const FarmArea(name: 'Area C', acres: 12.0, icon: Icons.spa_outlined),
    const FarmArea(name: 'Area D', acres: 1.8, icon: Icons.deck),
  ];

  void _addArea(String name, double acres) {
    setState(() {
      _farmAreas.add(
        FarmArea(
          name: name,
          acres: acres,
          icon: Icons.add_location_alt_outlined,
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePageContent(onNavigate: _onItemTapped),
      RoverPage(farmAreas: _farmAreas, onAddArea: _addArea),
      const MarketPricesPage(),
      const AboutPage(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Color(0xFF2C3E50)),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.agriculture),
              label: 'Rover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront),
              label: 'Market Rate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              label: 'About',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}

class HomePageContent extends ConsumerStatefulWidget {
  final Function(int) onNavigate;
  const HomePageContent({super.key, required this.onNavigate});

  @override
  ConsumerState<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends ConsumerState<HomePageContent> {
  bool isLoading = true;
  String errorMessage = "";
  String currentCity = "Amaravati";
  String currentWeather = "Loading...";
  String temperature = "--°C";
  String dateText = "";
  double humidityPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    // App khulte hi memory se purana farm data load karo
    ref.read(farmDataProvider.notifier).loadDataFromPrefs();
  }

  Future<void> _fetchWeather() async {
    const apiKey = "apikey";
    final url =
        "https://api.tomorrow.io/v4/weather/realtime?location=$currentCity&apikey=$apiKey";

    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) _updateWeatherData(json.decode(response.body));
      } else {
        if (mounted) {
          setState(
            () => errorMessage =
                "Error: ${json.decode(response.body)['message']}",
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => errorMessage = "Connection error.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _updateWeatherData(Map<String, dynamic> data) {
    setState(() {
      final values = data['data']['values'];
      final location = data['location'];
      currentCity = location['name']?.split(',').first ?? currentCity;
      temperature = "${(values['temperature'] as num).round()}°C";
      humidityPercent = (values['humidity'] as num).toDouble() / 100.0;
      currentWeather = _mapWeatherCondition(values['weatherCode']);
      final now = DateTime.now();
      const weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      dateText =
          "${weekdays[now.weekday % 7]} | ${now.day} ${months[now.month - 1]}";
    });
  }

  String _mapWeatherCondition(int? code) {
    switch (code) {
      case 1000:
        return "SUNNY";
      case 1100:
      case 1101:
      case 1102:
        return "PARTLY CLOUDY";
      case 1001:
        return "OVERCAST";
      case 2000:
      case 2100:
        return "FOGGY";
      case 4000:
      case 4001:
      case 4200:
      case 4201:
        return "LIGHT RAIN";
      case 8000:
        return "THUNDERSTORM";
      default:
        return "SUNNY";
    }
  }

  @override
  Widget build(BuildContext context) {
    final prediction = ref.watch(predictionProvider);
    final allFarmData = ref.watch(farmDataProvider);
    final FarmData? defaultFarmData = allFarmData['Area A'];
    final geminiAdvice = ref.watch(geminiRecommendationProvider);

    return SafeArea(
      child: Column(
        children: [
          _buildHeaderControls(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your Stats',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildWeatherCard(),
                    const SizedBox(height: 20),
                    _buildStatsDetailsCard(prediction, defaultFarmData),
                    const SizedBox(height: 20),
                    _buildGeminiAdviceCard(geminiAdvice),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.local_hospital_outlined,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Plant Doctor",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3E50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlantDoctorPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderControls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchPage(onNavigate: widget.onNavigate),
                  ),
                );
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'hello farmer...',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(Icons.search, color: Colors.grey.shade600),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            alignment: Alignment.topRight,
            children: [
              const Icon(
                Icons.notifications_none_outlined,
                color: Colors.black54,
                size: 30,
              ),
              Container(
                margin: const EdgeInsets.only(top: 2.0, right: 2.0),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/images/pfp.png'),
              backgroundColor: Color(0xFFE0E0E0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    final weatherImages = {
      "SUNNY": "assets/images/sunnyday.jpeg",
      "THUNDERSTORM": "assets/images/THUNDERSTORM.jpg",
      "FOGGY": "assets/images/FOGGY.jpg",
      "PARTLY CLOUDY": "assets/images/PARTLY CLOUDY.jpg",
      "OVERCAST": "assets/images/OVERCAST.jpg",
      "LIGHT RAIN": "assets/images/LIGHT RAIN.jpg",
    };
    String bgImage =
        weatherImages[currentWeather] ?? "assets/images/sunnyday.jpeg";

    return Container(
      padding: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: DecorationImage(image: AssetImage(bgImage), fit: BoxFit.cover),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : errorMessage.isNotEmpty
          ? Center(
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black54,
                ),
              ),
            )
          : Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        temperature,
                        style: GoogleFonts.poppins(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        currentWeather,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Text(
                    dateText,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: CircularPercentIndicator(
                    radius: 35.0,
                    lineWidth: 8.0,
                    percent: humidityPercent,
                    center: Text(
                      "${(humidityPercent * 100).toInt()}%",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    progressColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsDetailsCard(String prediction, FarmData? farmData) {
    String soilTemp = farmData != null
        ? '${farmData.temp1.toStringAsFixed(1)}°C'
        : '--°C';
    String humidity = farmData != null
        ? '${farmData.humidity.toStringAsFixed(1)}%'
        : '--%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF0FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Checked',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A4750),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '16:03',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A4750),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _fetchWeather,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDFF0FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh,
                        size: 18,
                        color: Color(0xFF3A4750),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  'Soil Temp',
                  soilTemp,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile('Humidity', humidity, Icons.arrow_upward),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Crop AI :',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A4750),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prediction,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3A4750),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiAdviceCard(BreedingRecommendation? advice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Text(
                'AI Agronomist Advice',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (advice == null)
            Text(
              "Press refresh on Control Panel to get breeding advice.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdviceRow(
                  '🧬 Recommended Breeding / Mutation',
                  advice.recommendedbreedingmutation,
                ),
                const SizedBox(height: 12),
                _buildAdviceRow(
                  '🧬 Recommended Trait',
                  advice.recommendedTrait,
                ),
                const SizedBox(height: 12),
                _buildAdviceRow('🤔 Reason', advice.reason),
                const SizedBox(height: 12),
                _buildAdviceRow('🌱 Suggested Action', advice.suggestedAction),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAdviceRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A4750),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 18, color: const Color(0xFF3A4750)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3A4750),
            ),
          ),
        ],
      ),
    );
  }
}
