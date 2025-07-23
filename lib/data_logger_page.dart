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
  final String apiLogger = 'https://dev.tirtaayu.my.id/api/tekniks/logger/';
  final String bearerToken =
      'Bearer 8|3acT1iWYizq86jljp8FGUmQwLHF6fGSqFQ1gXa3T94fd5111';

  @override
  void initState() {
    super.initState();
    _loadZones();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadZones() async {
    try {
      final responseZona = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': bearerToken},
      );

      final responseLogger = await http.get(
        Uri.parse(apiLogger),
        headers: {'Authorization': bearerToken},
      );

      if (responseZona.statusCode == 200 && responseLogger.statusCode == 200) {
        final List<dynamic> zonaList = jsonDecode(responseZona.body)['data'];
        final List<dynamic> loggerList = jsonDecode(responseLogger.body)['data'];

        List<Zona> loadedZona =
            zonaList.map((item) => Zona.fromJson(item)).toList();
        List<LoggerData> loadedLogger =
            loggerList.map((item) => LoggerData.fromJson(item)).toList();

        final Map<String, LoggerData> loggerMap = {
          for (var logger in loadedLogger) logger.serial: logger
        };

        List<ZoneData> combined = loadedZona.map((zona) {
          final logger = loggerMap[zona.serial];
          return ZoneData(
            name: zona.nama,
            latitude: zona.lat,
            longitude: zona.long,
            flow: logger?.flow ?? 0.0,
            bar: logger?.bar ?? 0.0,
            min: logger?.min ?? 0.0,
            lastUpdate: logger?.updatedAt ?? '-',
            isNormal: (logger?.flow ?? 0) > (logger?.min ?? 0),
          );
        }).toList();

        setState(() {
          zones = combined;
          filteredZones = combined;
          _currentPage = 0;
        });
      } else {
        throw Exception(
            'Failed to fetch data: ${responseZona.statusCode} / ${responseLogger.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat data dari API")),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredZones =
          zones.where((zone) => zone.name.toLowerCase().contains(query)).toList();
      _currentPage = 0;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPages = (filteredZones.length / _zonesPerPage).ceil();
    final start = _currentPage * _zonesPerPage;
    final end = start + _zonesPerPage;
    final pageZones = filteredZones.sublist(
      start,
      end > filteredZones.length ? filteredZones.length : end,
    );

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
          IconButton(onPressed: _loadZones, icon: const Icon(Icons.refresh)),
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
          if (totalPages > 1)
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
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${zone.latitude},${zone.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak dapat membuka Google Maps")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
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
                    Icon(zone.isNormal ? Icons.check_circle : Icons.error,
                        color: zone.isNormal ? Colors.green : Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      zone.isNormal ? "Normal" : "ERROR",
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
            Text("💧 Flow : ${zone.flow} L/s (<= Min: ${zone.min})"),
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

class LoggerData {
  final String serial;
  final double flow;
  final double bar;
  final double min;
  final String updatedAt;

  LoggerData({
    required this.serial,
    required this.flow,
    required this.bar,
    required this.min,
    required this.updatedAt,
  });

  factory LoggerData.fromJson(Map<String, dynamic> json) {
    return LoggerData(
      serial: json['serial'],
      flow: (json['flow'] as num?)?.toDouble() ?? 0.0,
      bar: (json['pressure'] as num?)?.toDouble() ?? 0.0,
      min: (json['totalizer'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] ?? '-',
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

  Zona({
    required this.tipe,
    required this.deviceId,
    required this.serial,
    required this.nama,
    required this.lat,
    required this.long,
  });

  factory Zona.fromJson(Map<String, dynamic> json) {
    return Zona(
      tipe: json['tipe'],
      deviceId: json['device_id'],
      serial: json['serial'],
      nama: json['nama'],
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
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
