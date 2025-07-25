import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'message_page.dart';
import 'profile_page.dart';

class PressureLoggerPage extends StatefulWidget {
  const PressureLoggerPage({super.key});

  @override
  State<PressureLoggerPage> createState() => _PressureLoggerPageState();
}

class _PressureLoggerPageState extends State<PressureLoggerPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _rowsPerPage = 6;

  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPressureData();
  }

  Future<void> fetchPressureData() async {
    const String apiUrl = 'https://dev.tirtaayu.my.id/api/tekniks/device/PRESSURE'; // Ganti URL
    const String token = '8|3acT1iWYizq86jljp8FGUmQwLHF6fGSqFQ1gXa3T94fd5111'; // Ganti dengan token

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final List rawData = result['data'];

        setState(() {
          _data = rawData
              .where((item) => item['tipe'] == 'PRESSURE')
              .map((item) => {
                    'nama': item['nama'],
                    'pressure': double.tryParse(item['pressure']['nilai']) ?? 0.0,
                    'waktu': item['tanggal'],
                  })
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filteredData = _data
        .where((item) => item['nama'].toString().toLowerCase().contains(query))
        .toList();

    final pagedData = filteredData
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    final totalPages = (filteredData.length / _rowsPerPage).ceil();

    return Scaffold(
      backgroundColor: const Color(0xFFDBF2EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDBF2EF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pressure Logger', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() => _currentPage = 1),
                    decoration: InputDecoration(
                      hintText: 'Cari zona...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Table(
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: Colors.black26, width: 1),
                        outside: BorderSide(color: Colors.black26, width: 1),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(3),
                        2: FlexColumnWidth(3),
                      },
                      children: [
                        _buildTableHeader(),
                        ...pagedData.map((item) => _buildTableRow(
                              item['nama'],
                              item['pressure'].toStringAsFixed(2),
                              item['waktu'],
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: List.generate(totalPages, (index) {
                    final pageNumber = index + 1;
                    final isSelected = _currentPage == pageNumber;
                    return GestureDetector(
                      onTap: () => setState(() => _currentPage = pageNumber),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Text(
                          '$pageNumber',
                          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFDBF2EF),
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MessagePage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
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

  TableRow _buildTableHeader() {
    return const TableRow(
      decoration: BoxDecoration(color: Color(0xFF333333)),
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text('Nama', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text('Pressure (bar)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text('Waktu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String nama, String pressure, String waktu) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFF444444)),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(nama, style: const TextStyle(color: Colors.white)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(pressure, style: const TextStyle(color: Colors.white)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(waktu, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
