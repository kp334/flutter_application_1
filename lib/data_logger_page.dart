import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'data_grafik_page.dart';

class DataLoggerScreen extends StatefulWidget {
  const DataLoggerScreen({super.key});

  @override
  State<DataLoggerScreen> createState() => _DataLoggerScreenState();
}

class _DataLoggerScreenState extends State<DataLoggerScreen> {
  List<ZoneData> zones = [];
  List<ZoneData> filteredZones = [];
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 0;
  final int _zonesPerPage = 5;

  final String apiUrl = 'https://dev.tirtaayu.my.id/api/tekniks/device/';
  final String bearerToken =
      'Bearer 8|3acT1iWYizq86jljp8FGUmQwLHF6fGSqFQ1gXa3T94fd5111';

  // Loading & Error state
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadZones();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadZones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responseZona = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': bearerToken},
      );

      if (responseZona.statusCode == 200) {
        final List<dynamic> zonaList = jsonDecode(responseZona.body)['data'];
        List<Zona> loadedZona =
            zonaList.map((item) => Zona.fromJson(item)).toList();

        List<ZoneData> combined = loadedZona.map((zona) {
          return ZoneData(
            name: zona.nama,
            latitude: zona.lat,
            longitude: zona.long,
            flow: zona.flow,
            bar: zona.bar,
            min: 0.0,
            lastUpdate: zona.tanggal,
            isNormal: zona.isNormal, // sudah mempertimbangkan flow > 0
          );
        }).toList();

        if (!mounted) return;
        setState(() {
          zones = combined;
          filteredZones = combined;
          _currentPage = 0;
        });
      } else {
        _errorMessage = 'Gagal memuat data (HTTP ${responseZona.statusCode}).';
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data dari API.';
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredZones = zones
          .where((zone) => zone.name.toLowerCase().contains(query))
          .toList();
      _currentPage = 0;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final int totalPages =
        filteredZones.isEmpty ? 1 : (filteredZones.length / _zonesPerPage).ceil();

    // Pastikan index halaman valid
    final int safePage = _currentPage.clamp(0, totalPages - 1);
    final int start = safePage * _zonesPerPage;
    final int end = (start + _zonesPerPage) > filteredZones.length
        ? filteredZones.length
        : (start + _zonesPerPage);
    final List<ZoneData> pageZones =
        (filteredZones.isEmpty || start >= filteredZones.length)
            ? const <ZoneData>[]
            : filteredZones.sublist(start, end);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : const Color(0xffd0f0ec),
        title: const Text("Data Logger"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _searchController.clear();
              _loadZones(); // otomatis set _isLoading = true, tampil spinner
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                    (isDark ? Colors.grey[800] : Colors.white),
              ),
            ),
          ),

          // ====== STATE AREA: Loading / Error / Content ======
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadZones,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (filteredZones.isEmpty)
            const Expanded(
              child: Center(child: Text('Tidak ada data zone')),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: pageZones.length,
                itemBuilder: (context, index) {
                  final zone = pageZones[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GrafikPage(zoneName: zone.name),
                        ),
                      );
                    },
                    child: ZoneCard(zone: zone),
                  );
                },
              ),
            ),

          if (totalPages > 1 && filteredZones.isNotEmpty && !_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: List.generate(totalPages, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _currentPage = i),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentPage == i ? Colors.teal : Colors.grey[300],
                        foregroundColor:
                            _currentPage == i ? Colors.white : Colors.black,
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text('${i + 1}'),
                    ),
                  );
                }),
              ),
            )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}

class ZoneCard extends StatelessWidget {
  final ZoneData zone;

  const ZoneCard({required this.zone, super.key});

  void _openMap(BuildContext context) async {
    if (zone.latitude == 0.0 || zone.longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Koordinat tidak valid")),
      );
      return;
    }

    final urlString =
        'https://www.google.com/maps/search/?api=1&query=${zone.latitude},${zone.longitude}';
    final Uri url = Uri.parse(urlString);

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak dapat membuka Google Maps")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal membuka peta")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: zone.isNormal ? Theme.of(context).cardColor : Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  zone.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    Icon(
                      zone.isNormal ? Icons.check_circle : Icons.error,
                      color: zone.isNormal ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      zone.isNormal ? "Normal" : "Error",
                      style: TextStyle(
                        color: zone.isNormal ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 6),
            Text("💧 Flow : ${zone.flow.toStringAsFixed(2)} L/s"),
            Text("📱 Bar : ${zone.bar.toStringAsFixed(2)}"),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 4),
                    Text("Update Terakhir : ${zone.lastUpdate}"),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.location_pin),
                  color: isDark ? Colors.white70 : Colors.black87,
                  onPressed: () => _openMap(context),
                )
              ],
            ),
          ],
        ),
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
    // Ambil nilai flow & pressure dari dynamic (num/String) secara aman
    final flowRaw = json['flow']?['nilai'];
    final pressureRaw = json['pressure']?['nilai'];

    final double flowVal = (flowRaw is num)
        ? flowRaw.toDouble()
        : double.tryParse(flowRaw?.toString() ?? '0') ?? 0.0;

    final double barVal = (pressureRaw is num)
        ? pressureRaw.toDouble()
        : double.tryParse(pressureRaw?.toString() ?? '0') ?? 0.0;

    final String tanggalStr = json['tanggal'] ?? '-';

    DateTime? updateTime;
    try {
      final parts = tanggalStr.split(' ');
      final dateParts = parts[0].split('-');
      final formattedDate =
          '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}T${parts[1]}';
      updateTime = DateTime.parse(formattedDate);
    } catch (_) {
      updateTime = null;
    }

    bool isUpToDate = false;
    if (updateTime != null) {
      final duration = DateTime.now().difference(updateTime);
      isUpToDate = duration.inHours <= 24;
    }

    // Aturan: zona Normal jika data up-to-date DAN flow > 0
    final bool normal = isUpToDate && flowVal > 0;

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
      isNormal: normal,
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
