import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


import 'pressure_logger_page.dart';
import 'grafik_level_air_page.dart';
import 'zona_page.dart';
import 'kualitas_air_page.dart';
import 'data_logger_page.dart';
import 'aduan_terproses.dart';
import 'message_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 1;
  late Timer _timer;
  DateTime _now = DateTime.now();

  List<Map<String, dynamic>> _levelAirData = [];
  bool _isLoadingLevelAir = true;

Future<void> _fetchLevelAirData() async {
  setState(() => _isLoadingLevelAir = true);
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.get(
      Uri.parse('https://dev.tirtaayu.my.id/api/tekniks/device/LEVEL'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Status Code: ${response.statusCode}');
    print('Raw Response: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is Map && decoded.containsKey('data')) {
        final List<dynamic> dataList = decoded['data'];

        setState(() {
          _levelAirData = dataList.map((e) {
  final level = e['level'] ?? {};
  return {
    'nama_reservoir': e['nama'] ?? 'Unknown',
    'value': double.tryParse(level['nilai']?.toString() ?? '0') ?? 0.0,
    'min': double.tryParse(level['min']?.toString() ?? '0') ?? 0.0,
    'max': double.tryParse(level['max']?.toString() ?? '100') ?? 100.0,
    'unit': level['satuan'] ?? '',
    'timestamp': e['tanggal'] ?? '-',
  };
}).toList();

          _isLoadingLevelAir = false;
        });
      } else {
        throw Exception('Format data tidak sesuai');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token tidak valid atau telah kedaluwarsa. Silakan login ulang.');
    } else {
      throw Exception('Gagal memuat data level air: ${response.statusCode}');
    }
  } catch (e) {
    print('Fetch error: $e');
    setState(() => _isLoadingLevelAir = false);
  }
}

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _fetchLevelAirData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width <= 412;
    final vSpacing = isCompact ? 8.0 : 12.0;
    final levelCardWidth = isCompact ? 100.0 : 120.0;

    final dateStr = DateFormat('d/M/yyyy').format(_now);
    final timeStr = DateFormat('HH:mm:ss').format(_now);

    return Scaffold(
      drawer: _SideDrawer(),
      appBar: AppBar(
        title: const Text('Monitoring - SCADA', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ZonaPage()));
                    },
                    child: const _InfoCard(
                      color: Colors.blue,
                      icon: Icons.location_on,
                      label: 'Zona',
                      value: '20',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoCard(
                    color: Colors.blue,
                    icon: Icons.people,
                    label: 'SR',
                    value: '60.213',
                  ),
                ),
              ]),
              SizedBox(height: vSpacing),
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AduanTerprosesPage()));
                    },
                    child: const _InfoCard(
                      color: Colors.amber,
                      icon: Icons.report,
                      label: 'Total Aduan',
                      value: '12',
                      textColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoCard(
                    color: Colors.redAccent,
                    icon: Icons.access_time,
                    label: dateStr,
                    value: timeStr,
                  ),
                ),
              ]),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Level Air', style: TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchLevelAirData,
                    ),
                  ],
                ),

              SizedBox(height: vSpacing),
              SizedBox(
                height: 160,
                child: _isLoadingLevelAir
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _levelAirData.length,
                        itemBuilder: (_, index) {
                          final data = _levelAirData[index];
                          return _LevelCard(
                            title: data['nama_reservoir'],
                            width: levelCardWidth,
                            value: data['value'],
                            timestamp: data['timestamp'],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GrafikLevelAir(zoneName: data['nama_reservoir']),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              SizedBox(height: vSpacing * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Data Logger', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 140,
                    height: 30,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: vSpacing),
              const _FlowLoggerCard(),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DataLoggerScreen()));
                  },
                  child: const Text('Lihat Semua'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 0:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagePage()));
              break;
            case 2:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final Color? textColor;

  const _InfoCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: fg, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String title;
  final double width;
  final double value;
  final String timestamp;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.title,
    required this.width,
    required this.value,
    required this.timestamp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 4),
            Expanded(child: Center(child: _VerticalGauge(value: value))),
            const SizedBox(height: 4),
            const Text('Level Air', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 2),
            Container(
              height: 18,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(timestamp, style: const TextStyle(fontSize: 9)),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalGauge extends StatelessWidget {
  final double value; // 0.0 - 1.0

  const _VerticalGauge({required this.value});

  @override
  Widget build(BuildContext context) {
    final double totalHeight = 80.0;
    final double fillHeight = totalHeight * value.clamp(0.0, 1.0);

    return Container(
      width: 20,
      height: totalHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: fillHeight,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowLoggerCard extends StatelessWidget {
  const _FlowLoggerCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : const Color(0xFFF8F4FA);
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final zoneColor = isDark ? Colors.tealAccent : Colors.teal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ZONA DUKUHSALAM',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: zoneColor)),
              const SizedBox(height: 8),
              _FlowLoggerInfo(
                label: 'Flow',
                value: '2.57 L/s (<= Min: 3.5)',
                icon: Icons.water_drop,
                textColor: textColor,
              ),
              _FlowLoggerInfo(
                label: 'Bar',
                value: '0.00',
                icon: Icons.speed,
                textColor: textColor,
              ),
              _FlowLoggerInfo(
                label: 'Update Terakhir',
                value: '02/07/2025, 11:45',
                icon: Icons.access_time,
                textColor: textColor,
              ),
              const SizedBox(height: 24),
            ],
          ),
          const Positioned(
            right: 4,
            top: 4,
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text('Normal', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: InkWell(
              onTap: () async {
                const url = 'https://www.google.com/maps/search/?api=1&query=-7.425728,109.006385';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              child: const Icon(Icons.place, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowLoggerInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color textColor;

  const _FlowLoggerInfo({
    required this.label,
    required this.value,
    required this.icon,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text('$label : ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColor)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 11, color: textColor))),
        ],
      ),
    );
  }
}

class _SideDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Row(
              children: const [
                CircleAvatar(radius: 30, child: Icon(Icons.person)),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Admin SCADA', style: TextStyle(color: Colors.white)),
                    Text('admin@email.com', style: TextStyle(color: Colors.white70)),
                  ],
                )
              ],
            ),
          ),
          const ListTile(leading: Icon(Icons.dashboard), title: Text('Dashboard')),
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text('Flow Logger'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DataLoggerScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.science),
            title: const Text('Kualitas Air'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const KualitasAirPage()));
            },
          ),
          ListTile(
  leading: const Icon(Icons.speed),
  title: const Text('Pressure Logger'),
  onTap: () {
    Navigator.pop(context); // Menutup drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PressureLoggerPage()),
    );
  },
),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          ),
        ],
      ),
    );
  }
}
