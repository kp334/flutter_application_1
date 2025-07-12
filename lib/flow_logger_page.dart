import 'package:flutter/material.dart';

void main() {
  runApp(const FlowLoggerApp());
}

class FlowLoggerApp extends StatelessWidget {
  const FlowLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flow Logger App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const FlowLoggerScreen(),
    );
  }
}

class FlowLoggerScreen extends StatefulWidget {
  const FlowLoggerScreen({super.key});

  @override
  State<FlowLoggerScreen> createState() => _FlowLoggerScreenState();
}

class _FlowLoggerScreenState extends State<FlowLoggerScreen> {
  List<ZoneData> zones = [];
  List<ZoneData> filteredZones = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadZones(); // pertama kali load
    _searchController.addListener(_onSearchChanged);
  }

  void _loadZones() {
    // Simulasi data 6 zona (bisa tambah sampai 30+)
    final loadedZones = [
      ZoneData("ZONA DUKUHSALAM", "2.57", 3.5, 0.0, "02/07/2025, 11:45", true),
      ZoneData("DMA KAMPUNG MOCI", "5.21", 5.5, 0.0, "03/07/2025, 07:13", true),
      ZoneData("DMA MARGASARI", "2.37", 3.0, 0.0, "03/07/2025, 07:05", true),
      ZoneData("ZONA PDAB UJUNGRUSI BARAT", "598.98", 50.0, 0.0, "02/07/2025, 12:00", true),
      ZoneData("ZONA BALAPULANG", "13.00", 13.0, 9.36, "02/07/2025, 07:18", true),
      ZoneData("ZONA DUKUHRWRINGIN II", "0.17", 1.5, 0.0, "03/07/2025, 07:15", false),
    ];

    setState(() {
      zones = loadedZones;
      filteredZones = loadedZones;
    });
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredZones = zones
          .where((zone) => zone.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _refreshZones() {
    _loadZones(); // simulasi refresh data
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
    return Scaffold(
      backgroundColor: const Color(0xffe0f6f4),
      appBar: AppBar(
        backgroundColor: const Color(0xffd0f0ec),
        title: const Text("Flow Logger"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // aktifkan tombol kembali
          },
        ),
        actions: [
          IconButton(
            onPressed: _refreshZones,
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
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredZones.length,
              itemBuilder: (context, index) {
                final zone = filteredZones[index];
                return ZoneCard(zone: zone);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Home aktif
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Nama & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                Column(
                  children: [
                    Icon(
                      zone.isNormal ? Icons.check_circle : Icons.error,
                      color: zone.isNormal ? Colors.green : Colors.red,
                    ),
                    Text(
                      zone.isNormal ? "Normal" : "ERROR",
                      style: TextStyle(
                        color: zone.isNormal ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("💧 Flow : ${zone.flow} L/s (<= Min: ${zone.min})"),
            Text("🛢️ Bar : ${zone.bar.toStringAsFixed(2)}"),
            Row(
              children: [
                const Icon(Icons.timer, size: 16),
                const SizedBox(width: 4),
                Text("Update Terakhir : ${zone.lastUpdate}"),
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

  ZoneData(this.name, this.flow, this.min, this.bar, this.lastUpdate, this.isNormal);
}
