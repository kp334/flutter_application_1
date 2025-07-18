import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'data_table_page.dart'; // <--- Tambahkan ini

class GrafikPage extends StatefulWidget {
  final String zoneName;
  const GrafikPage({super.key, required this.zoneName});

  @override
  State<GrafikPage> createState() => _GrafikPageState();
}

class _GrafikPageState extends State<GrafikPage> {
  final DateFormat dateTimeFormat = DateFormat("dd-MM-yyyy HH:mm");
  final TextEditingController startController = TextEditingController(text: "02-07-2025 00:00");
  final TextEditingController endController = TextEditingController(text: "02-07-2025 23:59");

  final allTableData = [
    {"datetime": "2025-07-02 00:12", "flow": "3.93", "pressure": "0", "totalizer": "382347"},
    {"datetime": "2025-07-02 01:17", "flow": "3.89", "pressure": "0", "totalizer": "382351"},
    {"datetime": "2025-07-02 03:23", "flow": "3.92", "pressure": "0", "totalizer": "382355"},
    {"datetime": "2025-07-02 10:10", "flow": "3.75", "pressure": "0", "totalizer": "382360"},
    {"datetime": "2025-07-02 22:00", "flow": "3.70", "pressure": "0", "totalizer": "382370"},
  ];

  List<Map<String, String>> filteredData = [];

  List<FlSpot> flowSpots = [];
  List<FlSpot> totalizerSpots = [];

  @override
  void initState() {
    super.initState();
    filteredData = allTableData;
    flowSpots = generateFlowSpots(filteredData);
    totalizerSpots = generateTotalizerSpots(filteredData);
  }

  void filterData() {
    try {
      final startDate = dateTimeFormat.parseStrict(startController.text);
      final endDate = dateTimeFormat.parseStrict(endController.text);

      setState(() {
        filteredData = allTableData.where((entry) {
          final entryDate = DateTime.parse(entry['datetime']!.replaceFirst(' ', 'T'));
          return entryDate.isAfter(startDate.subtract(const Duration(minutes: 1))) &&
                 entryDate.isBefore(endDate.add(const Duration(minutes: 1)));
        }).toList();

        flowSpots = generateFlowSpots(filteredData);
        totalizerSpots = generateTotalizerSpots(filteredData);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format tanggal salah. Gunakan: dd-MM-yyyy HH:mm")),
      );
    }
  }

  List<FlSpot> generateFlowSpots(List<Map<String, String>> data) {
    return data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), double.tryParse(e.value['flow']!) ?? 0);
    }).toList();
  }

  List<FlSpot> generateTotalizerSpots(List<Map<String, String>> data) {
    return data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (double.tryParse(e.value['totalizer']!) ?? 0) / 100000);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final latestFlow = flowSpots.isNotEmpty ? flowSpots.last.y.toStringAsFixed(2) : "0.00";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ZONA ${widget.zoneName}".toUpperCase(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flow Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(latestFlow, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      const Text("L/s", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: const [
                      Text("0.00", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(width: 6),
                      Text("Bar", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text("Update 02/07/2025, 11:45", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Grafik
            SizedBox(
              height: 260,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (filteredData.length - 1).toDouble().clamp(0, 6),
                    minY: 0,
                    maxY: 6,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text('Totalizer'),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (value, meta) {
                            final val = (382320 + value * 64).toInt();
                            return Text('$val', style: const TextStyle(fontSize: 10));
                          },
                          interval: 1,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        axisNameWidget: const Text('Flow'),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            return Text((1.8 + value * 0.4).toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10));
                          },
                          interval: 1,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < filteredData.length) {
                              final time = filteredData[value.toInt()]['datetime']!.split(' ')[1];
                              return Text(time, style: const TextStyle(fontSize: 10));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: flowSpots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: totalizerSpots,
                        isCurved: true,
                        color: Colors.purple,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                LegendItem(color: Colors.blue, text: 'Flow'),
                SizedBox(width: 16),
                LegendItem(color: Colors.purple, text: 'Totalizer'),
              ],
            ),

            const SizedBox(height: 12),

            // Filter Tanggal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(child: Text("Tanggal Awal")),
                      Expanded(child: Text("Tanggal Akhir")),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startController,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: endController,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: filterData,
                      icon: const Icon(Icons.filter_alt),
                      label: const Text("Filter"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade300,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text("DATA GRAFIK", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),

            // Tabel Data (Filtered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Table(
                border: TableBorder.all(color: Colors.black54, width: 1),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(2),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFFE0F2F1)),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("DateTime", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Flow", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Pressure", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Totalizer", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  for (var data in filteredData)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(data["datetime"]!, textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(data["flow"]!, textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(data["pressure"]!, textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(data["totalizer"]!, textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DataTablePage(zoneName: widget.zoneName),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("Tampilkan Semua"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.show_chart, color: color, size: 16),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
