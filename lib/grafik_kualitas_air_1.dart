import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GrafikKualitasAir1 extends StatefulWidget {
  const GrafikKualitasAir1({super.key});

  @override
  State<GrafikKualitasAir1> createState() => _GrafikKualitasAir1State();
}

class _GrafikKualitasAir1State extends State<GrafikKualitasAir1> {
  final startDateController = TextEditingController(text: '24-05-2025 13:34');
  final endDateController = TextEditingController(text: '10-07-2025 03:29');

  List<Map<String, dynamic>> grafikData = [
    {"datetime": "2025-05-24 13:34", "ph": 0.0, "klor": 0.0},
    {"datetime": "2025-06-26 01:34", "ph": 5.8, "klor": 2.7},
    {"datetime": "2025-07-10 03:32", "ph": 0.0, "klor": 0.0},
  ];

  DateFormat dateFormat = DateFormat("dd-MM-yyyy HH:mm");

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
        title: const Text('Chlorine Analyzer Res.Timbangreja'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.menu),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Update 24/05/2025, 13:34',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Grafik Line Chart
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(show: true),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: grafikData.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value['ph']);
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                        ),
                        LineChartBarData(
                          spots: grafikData.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value['klor']);
                          }).toList(),
                          isCurved: true,
                          color: Colors.purple,
                          barWidth: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.show_chart, color: Colors.blue, size: 16),
                    SizedBox(width: 4),
                    Text('pH Air'),
                    SizedBox(width: 20),
                    Icon(Icons.show_chart, color: Colors.purple, size: 16),
                    SizedBox(width: 4),
                    Text('Sisa Klor'),
                  ],
                ),

                const SizedBox(height: 16),

                // Filter Tanggal
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Tanggal Awal"),
                          TextFormField(
                            controller: startDateController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Tanggal Akhir"),
                          TextFormField(
                            controller: endDateController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () {
                    // Tambahkan logika filter di sini jika diperlukan
                  },
                  child: const Text("Filter"),
                ),

                const SizedBox(height: 24),

                const Text(
                  "DATA GRAFIK\nCHLORINE ANALYSIS RES",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                // Tabel Data
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTableTheme(
                    data: DataTableThemeData(
                      headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                      dataRowColor: MaterialStateProperty.all(Colors.white),
                      dividerThickness: 1.2,
                    ),
                    child: DataTable(
                      columnSpacing: 24,
                      horizontalMargin: 12,
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columns: const [
                        DataColumn(label: Text('DateTime')),
                        DataColumn(label: Text('pH Air')),
                        DataColumn(label: Text('Sisa Klor')),
                      ],
                      rows: grafikData
                          .map(
                            (row) => DataRow(
                              cells: [
                                DataCell(Text(row['datetime'])),
                                DataCell(Text(row['ph'].toString())),
                                DataCell(Text(row['klor'].toString())),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.lightBlue[100],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[700],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.email), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
        ],
      ),
    );
  }
}
