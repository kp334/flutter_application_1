import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadZones();
    _searchController.addListener(_onSearchChanged);
  }

  void _loadZones() {
    final loadedZones = [
      ZoneData("ZONA DUKUHSALAM", "2.57", 3.5, 0.0, "02/07/2025, 11:45", true, -7.4212, 109.2345),
      ZoneData("DMA KAMPUNG MOCI", "5.21", 5.5, 0.0, "03/07/2025, 07:13", true, -7.4500, 109.2500),
      ZoneData("DMA MARGASARI", "2.37", 3.0, 0.0, "03/07/2025, 07:05", true, -7.4600, 109.2700),
      ZoneData("ZONA PDAB UJUNGRUSI BARAT", "598.98", 50.0, 0.0, "02/07/2025, 12:00", true, -7.4700, 109.2800),
      ZoneData("ZONA BALAPULANG", "13.00", 13.0, 9.36, "02/07/2025, 07:18", false, -7.4800, 109.2900),
      ZoneData("ZONA DUKUHRWRINGIN II", "0.17", 1.5, 0.0, "03/07/2025, 07:15", false, -7.4900, 109.3000),
    ];

    setState(() {
      zones = loadedZones;
      filteredZones = loadedZones;
      _currentPage = 0;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredZones = zones.where((zone) => zone.name.toLowerCase().contains(query)).toList();
      _currentPage = 0;
    });
  }

  void _refreshZones() {
    _loadZones();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data berhasil diperbarui")),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (filteredZones.length / _zonesPerPage).ceil();
    final start = _currentPage * _zonesPerPage;
    final end = start + _zonesPerPage;
    final pageZones = filteredZones.sublist(
      start,
      end > filteredZones.length ? filteredZones.length : end,
    );

    return Scaffold(
      backgroundColor: const Color(0xffe0f6f4),
      appBar: AppBar(
        backgroundColor: const Color(0xffd0f0ec),
        title: const Text("Data Logger"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(onPressed: _refreshZones, icon: const Icon(Icons.refresh)),
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
                fillColor: Colors.white,
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
                        backgroundColor: _currentPage == i ? Colors.teal : Colors.grey[300],
                        foregroundColor: _currentPage == i ? Colors.white : Colors.black,
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
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${zone.latitude},${zone.longitude}');
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xfff6f2fa),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(zone.name, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
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
            Text("🛁 Bar : ${zone.bar.toStringAsFixed(2)}"),
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
                  color: Colors.black87,
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

class ZoneData {
  final String name;
  final String flow;
  final double min;
  final double bar;
  final String lastUpdate;
  final bool isNormal;
  final double latitude;
  final double longitude;

  ZoneData(
    this.name,
    this.flow,
    this.min,
    this.bar,
    this.lastUpdate,
    this.isNormal,
    this.latitude,
    this.longitude,
  );
}
