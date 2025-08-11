import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;



import 'data_grafik_page.dart';
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

  List<ZoneData> _allZones = [];
  List<ZoneData> _filteredZones = [];
  
  

  List<Map<String, dynamic>> _levelAirData = [];
  bool _isLoadingLevelAir = true;

  int _totalAduan = 0;
  String _jumlahPelanggan = '0';
  


TextEditingController _searchController = TextEditingController();
String _searchQuery = '';
List _zonaList = []; // hasil dari API
Map? _selectedZona;  // zona yang ditampilkan


  int jumlahZona = 0;
  bool isLoadingZona = true;
  String lastUpdate = "";

Future<void> _fetchJumlahZona() async {
  try {
    final response = await http.get(
      Uri.parse('https://dev.tirtaayu.my.id/api/tekniks/zona'),
      headers: {
        'Authorization': 'Bearer 8|3acT1iWYizq86jljp8FGUmQwLHF6fGSqFQ1gXa3T94fd5111', // ganti $tokenAnda sesuai token login
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['status'] == "success" && jsonData['data'] is List) {
        setState(() {
          jumlahZona = jsonData['data'].length;
        });
      } else {
        print("Format data tidak sesuai");
      }
    } else {
      print('Gagal memuat data zona: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}



Future<void> _fetchJumlahPelanggan() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('https://dev.tirtaayu.my.id/api/tekniks/util'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['status'] == 'success') {
        String totalString = decoded['data']['total_pelanggan_aktif'] ?? '0';

        // Hilangkan titik, lalu ubah ke int
        int totalInt = int.tryParse(totalString.replaceAll('.', '')) ?? 0;

        // Format angka ke ribuan
        String formatted = NumberFormat.decimalPattern('id_ID').format(totalInt);

        setState(() {
          _jumlahPelanggan = formatted; // Contoh: "60.516"
        });
      } else {
        print('Gagal memuat jumlah pelanggan');
      }
    } else {
      print('Status bukan 200: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetchJumlahPelanggan: $e');
  }
}


Future<void> _fetchLevelAirData() async {
  setState(() {
    _isLoadingLevelAir = true;
  });

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('https://dev.tirtaayu.my.id/api/tekniks/device/LEVEL'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> dataList = decoded['data'] ?? [];

      // === GANTI blok setState lama dengan yang ini ===
      setState(() {
  _levelAirData = dataList.map((e) {
    final level = e['level'] ?? {};
    final nilai = double.tryParse(level['nilai']?.toString() ?? '0') ?? 0.0;

    // Ambang bawaan API tetap dipakai untuk flag/warna
    final apiMin = double.tryParse(level['min']?.toString() ?? '0') ?? 0.0;

    // >>> Pakai skala tetap 0–400 cm untuk gauge
    const double gaugeMin = 0.0;
    const double gaugeMax = 400.0;

    return {
      'nama_reservoir': e['nama'] ?? 'Unknown',
      'current': nilai,
      'min': gaugeMin,   // <— min air tabung
      'max': gaugeMax,   // <— max air tabung
      'unit': level['satuan'] ?? '',
      'isLow': nilai < apiMin, // tetap merah bila di bawah ambang API
      'timestamp': e['tanggal'] ?? '-',
    };
  }).toList();

  _isLoadingLevelAir = false;
});

      // === sampai sini ===
    } else {
      throw Exception('Gagal memuat data reservoir');
    }
  } catch (e) {
    print(e);
    setState(() {
      _isLoadingLevelAir = false;
    });
  }
}

Future<void> _fetchTotalAduan() async {
  const url = 'https://app.tirtaayu.com/api/dataaduan';

  try {
    final response = await http.get(Uri.parse(url));
    final decoded = jsonDecode(response.body);

    if (decoded['status'] == 'success') {
      final Map<String, dynamic> data = decoded['data'];
      int total = 0;

      data.forEach((key, value) {
        final jumlah = int.tryParse(value['total'].toString()) ?? 0;
        total += jumlah;
      });

      setState(() {
        _totalAduan = total;
      });
    } else {
      throw Exception('Gagal memuat data aduan');
    }
  } catch (e) {
    print('Error fetchTotalAduan: $e');
  }
}

ZoneData? _singleZone;
bool _isLoadingZone = true;

Future<void> _fetchAllZones() async {
  try {
    final response = await http.get(
      Uri.parse('https://dev.tirtaayu.my.id/api/tekniks/device/'),
      headers: {'Authorization': 'Bearer 8|3acT1iWYizq86jljp8FGUmQwLHF6fGSqFQ1gXa3T94fd5111'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];

      List<ZoneData> allZoneList = data.map((item) {
        final zona = Zona.fromJson(item);
        return ZoneData(
          name: zona.nama,
          latitude: zona.lat,
          longitude: zona.long,
          flow: zona.flow,
          bar: zona.bar,
          min: 0.0,
          lastUpdate: zona.tanggal,
          isNormal: zona.isNormal,
        );
      }).toList();

      setState(() {
        _allZones = allZoneList;
        _filteredZones = allZoneList;
        _isLoadingZone = false;
      });
    }
  } catch (e) {
    print("Error loading all zones: $e");
    setState(() {
      _isLoadingZone = false;
    });
  }
}



double _calculateNormalizedValue(double current, double min, double max) {
  if (max <= min) return 0.0; // untuk menghindari pembagian nol atau nilai tidak masuk akal
  if (current >= max) return 1.0;
  if (current <= min) return 0.0;
  final normalized = (current - min) / (max - min);
  return normalized.clamp(0.0, 1.0);
}



  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _fetchLevelAirData();
    _fetchTotalAduan();
    _fetchAllZones();
    _fetchJumlahPelanggan();
    _fetchJumlahZona();
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
                    child: _InfoCard(
                    color: Colors.blue,
                    icon: Icons.location_on,
                    label: 'Zona',
                    value: '$jumlahZona',
                  ),

                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoCard(
                    color: Colors.blue,
                    icon: Icons.people,
                    label: 'SR',
                    value: _jumlahPelanggan,
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
                    child:  _InfoCard(
                      color: Colors.amber,
                      icon: Icons.report,
                      label: 'Total Aduan',
                      value: _totalAduan.toString(),
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
                            current: data['current'],
                            min: data['min'],
                            max: data['max'],
                            unit: data['unit'],
                            isLow: data['isLow'] ?? false,
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
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                        _filteredZones = _allZones.where((zone) => zone.name.toLowerCase().contains(_searchQuery)).toList();
                      });
                    },

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
              _isLoadingZone
                ? const Center(child: CircularProgressIndicator())
                : _filteredZones.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchQuery.isEmpty ? 1 : _filteredZones.length,
                        itemBuilder: (context, index) {
                          return _SingleZoneCard(zone: _filteredZones[index]);
                        },
                      )
                    : const Text('Tidak ada data zone'),


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
  final double current;
  final double min;
  final double max;
  final String unit;
  final String timestamp;
  final VoidCallback? onTap;
  final bool isLow;

  const _LevelCard({
    required this.title,
    required this.width,
    required this.current,
    required this.min,
    required this.max,
    required this.unit,
    required this.timestamp,
    required this.isLow,
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

            // <<< GANTI BAGIAN GAUGE DI SINI >>>
            Expanded(
              child: Center(
                child: _VerticalGauge(
                  current: current,
                  min: min,
                  max: max,
                  isLow: isLow,
                  width: 26,
                  height: 110,
                ),
              ),
            ),
            // <<< SAMPAI SINI >>>

            const SizedBox(height: 4),
            Text('${current.toStringAsFixed(2)} $unit', style: const TextStyle(fontSize: 10)),
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

class _VerticalGauge extends StatefulWidget {
  final double current;
  final double min;
  final double max;
  final bool isLow;

  // opsional: bisa diubah kalau mau
  final double width;
  final double height;

  const _VerticalGauge({
    required this.current,
    required this.min,
    required this.max,
    required this.isLow,
    this.width = 24,
    this.height = 100,
  });

  @override
  State<_VerticalGauge> createState() => _VerticalGaugeState();
}

class _VerticalGaugeState extends State<_VerticalGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _targetProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // gelombang jalan pelan terus

    _targetProgress = _normalize(widget.current, widget.min, widget.max);
  }

  @override
  void didUpdateWidget(covariant _VerticalGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // jika nilai API berubah, sesuaikan target progress
    _targetProgress = _normalize(widget.current, widget.min, widget.max);
  }

  static double _normalize(double current, double min, double max) {
    if (max <= min) return 0.0;
    return ((current - min) / (max - min)).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    final glassColor = Colors.white;

    final Color fillColor =
        widget.isLow ? Colors.redAccent : Colors.blueAccent;

    return TweenAnimationBuilder<double>(
      // animasi pelan saat ketinggian air berubah
      tween: Tween(begin: 0, end: _targetProgress),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, progress, _) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Tabung / gelas
              Container(
                decoration: BoxDecoration(
                  color: glassColor,
                  border: Border.all(color: Colors.grey),
                  borderRadius: borderRadius,
                ),
              ),

              // Isi air (gelombang)
              Padding(
                padding: const EdgeInsets.all(2), // ruang untuk border
                child: ClipRRect(
                  borderRadius: borderRadius.subtract(
                    const BorderRadius.all(Radius.circular(2)),
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _WavePainter(
                          progress: progress,
                          phase: _controller.value * 2 * 3.1415926535,
                          color: fillColor,
                        ),
                        size: Size(widget.width - 4, widget.height - 4),
                      );
                    },
                  ),
                ),
              ),

              // Highlight kaca tipis di depan (biar lebih “tabung”)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress; // 0.0 - 1.0 (ketinggian air)
  final double phase;    // pergeseran gelombang (animasi)
  final Color color;

  _WavePainter({
    required this.progress,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // tinggi permukaan air (0 = bawah, height = atas)
    final double baseY = height * (1.0 - progress);

    // Parameter gelombang
    final double amplitude = 4.0;        // tinggi gelombang
    final double frequency = 2.0;        // jumlah puncak
    final double secondPhaseShift = 1.2; // untuk gelombang kedua

    // path gelombang pertama
    final Path path1 = Path()..moveTo(0, height);
    for (double x = 0; x <= width; x++) {
      final double y = baseY +
          amplitude *
              Math.sin((x / width * 2 * Math.pi * frequency) + phase);
      path1.lineTo(x, y);
    }
    path1
      ..lineTo(width, height)
      ..close();

    // path gelombang kedua (lebih halus, sedikit transparan)
    final Path path2 = Path()..moveTo(0, height);
    for (double x = 0; x <= width; x++) {
      final double y = baseY +
          (amplitude * 0.6) *
              Math.sin(
                  (x / width * 2 * Math.pi * (frequency * 1.2)) + phase + secondPhaseShift);
      path2.lineTo(x, y);
    }
    path2
      ..lineTo(width, height)
      ..close();

    // cat isi
    final Paint p1 = Paint()..color = color.withOpacity(0.85);
    final Paint p2 = Paint()..color = color.withOpacity(0.55);

    // gambar dari belakang ke depan
    canvas.drawPath(path1, p1);
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    // repaint saat tinggi/phase berubah
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color;
  }
}

// util sin/cos untuk CustomPainter
class Math {
  static const double pi = 3.1415926535897932;
  static double sin(double x) => Math._tableSin(x);
  static double _tableSin(double x) => Math._sin(x);
  static double _sin(double x) => Math._dartSin(x);
  static double _dartSin(double x) => math.sin(x);
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

class _SingleZoneCard extends StatelessWidget {
  final ZoneData zone;

  const _SingleZoneCard({required this.zone});

  void _openMap(BuildContext context) async {
    final lat = zone.latitude;
    final lon = zone.longitude;

    // Validasi sederhana koordinat
    if ((lat == 0.0 && lon == 0.0) || lat.isNaN || lon.isNaN) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koordinat tidak valid')),
        );
      }
      return;
    }

    // Web Google Maps (aman & ter-encode)
    final Uri url = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': '$lat,$lon'},
    );

    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps Web')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka peta')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final zoneColor = isDark ? Colors.tealAccent : Colors.teal;

    return InkWell(
      // Klik kartu: menuju halaman grafik
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GrafikPage(zoneName: zone.name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : const Color(0xFFF8F4FA),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: zoneColor,
                  ),
                ),
                const SizedBox(height: 8),
                _FlowLoggerInfo(
                  label: 'Flow',
                  value: '${zone.flow.toStringAsFixed(2)} L/s',
                  icon: Icons.water_drop,
                  textColor: textColor,
                ),
                _FlowLoggerInfo(
                  label: 'Bar',
                  value: zone.bar.toStringAsFixed(2),
                  icon: Icons.speed,
                  textColor: textColor,
                ),
                _FlowLoggerInfo(
                  label: 'Update Terakhir',
                  value: zone.lastUpdate,
                  icon: Icons.access_time,
                  textColor: textColor,
                ),
                const SizedBox(height: 24),
              ],
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Row(
                children: [
                  Icon(
                    zone.isNormal ? Icons.check_circle : Icons.error,
                    color: zone.isNormal ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    zone.isNormal ? 'Normal' : 'Error',
                    style: TextStyle(
                      color: zone.isNormal ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton(
                tooltip: 'Buka di Google Maps',
                icon: const Icon(Icons.place, size: 20),
                onPressed: () => _openMap(context),
              ),
            ),
          ],
        ),
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
            title: const Text('Data Logger'),
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
class Zona {
  final String tipe;
  final int deviceId;
  final String serial;
  final String nama;
  final double lat;
  final double long;
  final double flow;
  final double bar;
  final String tanggal;
  final bool isNormal;

  Zona({
    required this.tipe,
    required this.deviceId,
    required this.serial,
    required this.nama,
    required this.lat,
    required this.long,
    required this.flow,
    required this.bar,
    required this.tanggal,
    required this.isNormal,
  });

  factory Zona.fromJson(Map<String, dynamic> json) {
    double flowVal = double.tryParse(json['flow']?['nilai'] ?? '0') ?? 0.0;
    double barVal = double.tryParse(json['pressure']?['nilai'] ?? '0') ?? 0.0;
    String tanggalStr = json['tanggal'] ?? '-';

    DateTime? updateTime;
    try {
      final parts = tanggalStr.split(' ');
      final dateParts = parts[0].split('-');
      final formattedDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}T${parts[1]}';
      updateTime = DateTime.parse(formattedDate);
    } catch (_) {
      updateTime = null;
    }

    bool isUpToDate = false;
    if (updateTime != null) {
      final duration = DateTime.now().difference(updateTime);
      isUpToDate = duration.inHours <= 24;
    }

    return Zona(
      tipe: json['tipe'],
      deviceId: json['device_id'],
      serial: json['serial'],
      nama: json['nama'],
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
      flow: flowVal,
      bar: barVal,
      tanggal: tanggalStr,
      isNormal: isUpToDate,
    );
  }
}

class ZoneData {
  final String name;
  final double latitude;
  final double longitude;
  final double flow;
  final double bar;
  final double min;
  final String lastUpdate;
  final bool isNormal;

  ZoneData({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.flow,
    required this.bar,
    required this.min,
    required this.lastUpdate,
    required this.isNormal,
  });
}
