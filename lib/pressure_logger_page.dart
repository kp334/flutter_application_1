import 'package:flutter/material.dart';
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

  static const Color backgroundColor = Color(0xFFDBF2EF);
  static const Color tableHeaderColor = Color(0xFF333333);
  static const Color tableRowColor = Color(0xFF444444);

  final int _rowsPerPage = 6;

  final List<Map<String, dynamic>> _data = [
    {'nama': 'Zona Lebaksiu', 'pressure': 4.43, 'waktu': '15/07/2025 23:04'},
    {'nama': 'Zona Pengerbarang', 'pressure': 0.0, 'waktu': '15/07/2025 22:59'},
    {'nama': 'Zona Balapulang', 'pressure': 10.42, 'waktu': '15/07/2025 23:00'},
    {'nama': 'DMA Bongkok', 'pressure': 0.42, 'waktu': '15/07/2025 22:56'},
    {'nama': 'DMA Margasari', 'pressure': 0.00, 'waktu': '15/07/2025 22:29'},
    {'nama': 'DMA Randusari', 'pressure': 5.83, 'waktu': '15/07/2025 22:27'},
    {'nama': 'PDAB Ujungrusi Barat', 'pressure': 0.00, 'waktu': '15/07/2025 00:00'},
    {'nama': 'Jatimulya', 'pressure': 4.54, 'waktu': '15/07/2025 22:31'},
    {'nama': 'Dukuhwringin II', 'pressure': 0.84, 'waktu': '29/11/2024 21:28'},
  ];

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filteredData = _data.where((item) {
      return item['nama'].toString().toLowerCase().contains(query);
    }).toList();

    final pagedData = filteredData
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    final totalPages = (filteredData.length / _rowsPerPage).ceil();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pressure Logger',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _currentPage = 1),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            color: tableHeaderColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text(
                    "Nama",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Pressure (bar)",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Waktu",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          Expanded(
            child: ListView.builder(
              itemCount: pagedData.length,
              itemBuilder: (context, index) {
                final item = pagedData[index];
                return Container(
                  color: tableRowColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(item['nama'],
                            style: const TextStyle(color: Colors.white)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(item['pressure'].toString(),
                            style: const TextStyle(color: Colors.white)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(item['waktu'],
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Pagination
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Wrap(
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
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: backgroundColor,
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MessagePage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
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
