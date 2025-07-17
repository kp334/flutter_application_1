import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

class GrafikKualitasAir2 extends StatefulWidget {
  const GrafikKualitasAir2({super.key});

  @override
  State<GrafikKualitasAir2> createState() => _GrafikKualitasAir2State();
}

class _GrafikKualitasAir2State extends State<GrafikKualitasAir2> {
  final startDateController = TextEditingController(text: '24-05-2025 13:34');
  final endDateController = TextEditingController(text: '10-07-2025 03:29');
  final DateFormat dateFormat = DateFormat("dd-MM-yyyy HH:mm");

  final List<Map<String, dynamic>> allData = [
    {"datetime": "2025-05-24 13:34", "ph": 0.0, "klor": 0.0},
    {"datetime": "2025-06-26 01:34", "ph": 5.8, "klor": 2.7},
    {"datetime": "2025-07-10 03:32", "ph": 0.0, "klor": 0.0},
  ];

  List<Map<String, dynamic>> filteredData = [];

  @override
  void initState() {
    super.initState();
    filterData();
  }

  void filterData() {
    DateTime startDate = dateFormat.parse(startDateController.text);
    DateTime endDate = dateFormat.parse(endDateController.text);

    setState(() {
      filteredData = allData.where((data) {
        DateTime dataTime =
            DateFormat("yyyy-MM-dd HH:mm").parse(data['datetime']);
        return dataTime.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            dataTime.isBefore(endDate.add(const Duration(seconds: 1)));
      }).toList();
    });
  }

  Future<void> selectDateTime(TextEditingController controller) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );

      if (time != null) {
        final combined = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        controller.text = dateFormat.format(combined);
      }
    }
  }

  Future<void> handleExportOption(String value) async {
    switch (value) {
      case 'print':
        showDialog(
          context: context,
          builder: (_) =>
              const AlertDialog(content: Text("Fitur Print belum tersedia.")),
        );
        break;
      case 'pdf':
        showDialog(
          context: context,
          builder: (_) =>
              const AlertDialog(content: Text("Export PDF belum tersedia.")),
        );
        break;
      case 'image':
        showDialog(
          context: context,
          builder: (_) =>
              const AlertDialog(content: Text("Download PNG, JPEG belum tersedia.")),
        );
        break;
      case 'csv':
        await exportCSV();
        break;
    }
  }

  Future<void> exportCSV() async {
    List<List<dynamic>> rows = [
      ['DateTime', 'pH Air', 'Sisa Klor'],
      ...filteredData.map((row) => [
            row['datetime'],
            row['ph'],
            row['klor'],
          ])
    ];

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/data_export.csv';
    final file = File(path)..writeAsStringSync(csvData);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported Data CSV');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
        title: const Text('Chlorine Analyzer Res.Tegalsari'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => handleExportOption(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'print', child: Text('Print Chart')),
              const PopupMenuItem(value: 'pdf', child: Text('Download PDF')),
              const PopupMenuItem(value: 'image', child: Text('Download PNG, JPEG')),
              const PopupMenuItem(value: 'csv', child: Text('Download CSV, XLS')),
            ],
            icon: const Icon(Icons.menu),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Update 24/05/2025, 13:34',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Chart
            SizedBox(
              height: screenHeight * 0.25,
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: screenWidth * 0.9,
                  height: screenHeight * 0.25,
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(show: true),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: filteredData.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value['ph']);
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                        ),
                        LineChartBarData(
                          spots: filteredData.asMap().entries.map((e) {
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
              ),
            ),

            const SizedBox(height: 12),

            // Legend
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 8,
              children: const [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart, color: Colors.blue, size: 16),
                    SizedBox(width: 4),
                    Text('pH Air'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart, color: Colors.purple, size: 16),
                    SizedBox(width: 4),
                    Text('Sisa Klor'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Filter Date
            Column(
              children: [
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
                            onTap: () => selectDateTime(startDateController),
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
                            onTap: () => selectDateTime(endDateController),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: filterData,
                  child: const Text("Filter"),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "DATA CHLORINE ANALYZER\nBEDUG",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTableTheme(
                data: DataTableThemeData(
                  headingRowColor:
                      MaterialStateProperty.all(Colors.blue.shade50),
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
                  rows: filteredData
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
      ),
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
