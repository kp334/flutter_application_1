import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ZonaPage extends StatefulWidget {
  const ZonaPage({super.key});

  @override
  State<ZonaPage> createState() => _ZonaPageState();
}

class _ZonaPageState extends State<ZonaPage> {
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredData = [];
  bool isAscending = true;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchZonaData();
  }

  Future<void> _fetchZonaData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception("Token tidak ditemukan. Silakan login ulang.");
      }

      final response = await http.get(
        Uri.parse("https://dev.tirtaayu.my.id/api/tekniks/zona"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          List<dynamic> apiData = jsonResponse['data'];

          setState(() {
            data = apiData
                .map((item) => {
                      'zona': item['zona'] ?? '',
                      'pelanggan': item['total'] ?? item['jml'] ?? 0,
                    })
                .toList();

            // Urutkan alfabetis, "Belum Ditentukan" taruh paling bawah
            data.sort((a, b) {
              const belum = 'belum ditentukan';
              final zonaA = a['zona'].toString().toLowerCase();
              final zonaB = b['zona'].toString().toLowerCase();

              if (zonaA == belum && zonaB != belum) return 1;
              if (zonaB == belum && zonaA != belum) return -1;
              return zonaA.compareTo(zonaB);
            });

            filteredData = [...data];
            isLoading = false;
          });
        } else {
          throw Exception("Gagal mengambil data: ${jsonResponse['message']}");
        }
      } else {
        throw Exception(
            "Gagal koneksi ke server (status ${response.statusCode})");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                            (_) => Colors.grey.shade800),
                        headingTextStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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
