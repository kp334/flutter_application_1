import 'package:flutter/material.dart';
import 'data_grafik_page.dart'; // file ini harus ada dan isinya sudah diperbarui

class DetailZonePage extends StatelessWidget {
  final String zoneName;

  const DetailZonePage({super.key, required this.zoneName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe0f6f4),
      appBar: AppBar(
        backgroundColor: const Color(0xffd0f0ec),
        title: Text(zoneName, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FLOW dan PRESSURE - sampingan satu baris masing-masing
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text("2.57", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    SizedBox(width: 6),
                    Text("L/s", style: TextStyle(fontSize: 18)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text("0.00", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(width: 6),
                    Text("Bar", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Text("Update 02/07/2025, 11:45", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            /// Grafik
            Container(
              height: 260,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.teal.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const GrafikPage(zoneName: '',),
            ),

            const SizedBox(height: 12),

            /// Keterangan
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.show_chart, color: Colors.blue, size: 16),
                  SizedBox(width: 4),
                  Text("Flow", style: TextStyle(fontSize: 12)),
                  SizedBox(width: 16),
                  Icon(Icons.show_chart, color: Colors.purple, size: 16),
                  SizedBox(width: 4),
                  Text("Totalizer", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Filter Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Tanggal Awal"),
                Text("Tanggal Akhir"),
              ],
            ),
            Row(
              children: const [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "02-07-2025 00:00",
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "02-07-2025 23:59",
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_alt),
                label: const Text("Filter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade300,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Data Tabel
            const Text("DATA GRAFIK", style: TextStyle(fontWeight: FontWeight.bold)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("DateTime")),
                  DataColumn(label: Text("Flow")),
                  DataColumn(label: Text("Pressure")),
                  DataColumn(label: Text("Totalizer")),
                ],
                rows: const [
                  DataRow(cells: [
                    DataCell(Text("2025-07-02 00:12")),
                    DataCell(Text("3.93")),
                    DataCell(Text("0")),
                    DataCell(Text("382347")),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("2025-07-02 01:26")),
                    DataCell(Text("3.89")),
                    DataCell(Text("0")),
                    DataCell(Text("382351")),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("2025-07-02 03:29")),
                    DataCell(Text("3.92")),
                    DataCell(Text("0")),
                    DataCell(Text("382355")),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Tampilkan Semua"),
              ),
            ),
          ],
        ),
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