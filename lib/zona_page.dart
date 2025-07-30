import 'package:flutter/material.dart';

class ZonaPage extends StatefulWidget {
  const ZonaPage({super.key});

  @override
  State<ZonaPage> createState() => _ZonaPageState();
}

class _ZonaPageState extends State<ZonaPage> {
  List<Map<String, dynamic>> data = [
    {"zona": "Pagerbarang", "pelanggan": 10},
    {"zona": "DMA Bongkok", "pelanggan": 0},
    {"zona": "Spam Pantura", "pelanggan": 2},
    {"zona": "DMA Kampung Moci", "pelanggan": 0},
    {"zona": "Margasari", "pelanggan": 0},
    {"zona": "DMA Randusari", "pelanggan": 0},
    {"zona": "DMA Singkil Timur", "pelanggan": 0},
    {"zona": "Dukuhsalam", "pelanggan": 1},
    {"zona": "PDAB Ujungsusi Barat", "pelanggan": 1},
    {"zona": "Jatimulya", "pelanggan": 1},
  ];

  List<Map<String, dynamic>> filteredData = [];
  bool isAscending = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredData = [...data];
  }

  void _search(String query) {
    final lower = query.toLowerCase();
    setState(() {
      filteredData = data
          .where((zone) => zone['zona'].toLowerCase().contains(lower))
          .toList();
    });
  }

  void _sortByJumlahPelanggan() {
    setState(() {
      isAscending = !isAscending;
      filteredData.sort((a, b) => isAscending
          ? a['pelanggan'].compareTo(b['pelanggan'])
          : b['pelanggan'].compareTo(a['pelanggan']));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zona / DMA'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _sortByJumlahPelanggan,
                  icon: const Icon(Icons.sort),
                  tooltip: 'Urutkan berdasarkan jumlah pelanggan',
                )
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor:
                      MaterialStateColor.resolveWith((_) => Colors.grey.shade800),
                  headingTextStyle:
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  columns: const [
                    DataColumn(label: Text('Zona / DMA')),
                    DataColumn(label: Text('Jumlah Pelanggan')),
                  ],
                  rows: filteredData.map((zone) {
                    return DataRow(
                      cells: [
                        DataCell(Text(zone['zona'])),
                        DataCell(Text(zone['pelanggan'].toString())),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 