import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GrafikPage extends StatelessWidget {
  final String zoneName;
  const GrafikPage({super.key, required this.zoneName});

  @override
  Widget build(BuildContext context) {
    final flowSpots = [
      FlSpot(0, 3.6),
      FlSpot(1, 4.0),
      FlSpot(2, 3.8),
      FlSpot(3, 3.7),
      FlSpot(4, 3.0),
      FlSpot(5, 2.5),
      FlSpot(6, 3.3),
    ];

    final totalizerSpots = [
      FlSpot(0, 0.5),
      FlSpot(1, 1.0),
      FlSpot(2, 1.8),
      FlSpot(3, 2.5),
      FlSpot(4, 3.3),
      FlSpot(5, 4.0),
      FlSpot(6, 4.8),
    ];

    final latestFlow = flowSpots.last.y.toStringAsFixed(2);

    final List<Map<String, String>> tableData = [
      {
        "datetime": "2025-07-02 00:12:03",
        "flow": "3.93",
        "pressure": "0",
        "totalizer": "382347"
      },
      {
        "datetime": "2025-07-02 01:17:26",
        "flow": "3.89",
        "pressure": "0",
        "totalizer": "382351"
      },
      {
        "datetime": "2025-07-02 03:23:29",
        "flow": "3.92",
        "pressure": "0",
        "totalizer": "382355"
      },
    ];

    final TextEditingController startController =
        TextEditingController(text: "02-07-2025 00:00");
    final TextEditingController endController =
        TextEditingController(text: "02-07-2025 23:59");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Nilai Terbaru
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
  crossAxisAlignment: CrossAxisAlignment.baseline,
  textBaseline: TextBaseline.alphabetic,
  children: [
    Text(
      latestFlow,
      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    ),
    SizedBox(width: 6),
    Text("L/s", style: TextStyle(fontSize: 18)),
  ],
),

              SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text("0.00",
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(width: 6),
                  Text("Bar", style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Text("Update 02/07/2025, 11:45",
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // Grafik
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
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
                        final totalizerValue =
                            (382320 + value * 64).toInt();
                        return Text('$totalizerValue',
                            style: const TextStyle(fontSize: 10));
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
                        final flowValue =
                            (1.8 + value * 0.4).toStringAsFixed(1);
                        return Text(flowValue,
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
                        const labels = [
                          '00:00',
                          '03:00',
                          '06:00',
                          '09:00',
                          '12:00',
                          '15:00',
                          '17:00'
                        ];
                        return Text(labels[value.toInt()],
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
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
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              Row(
                children: const [
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement filter logic
                  },
                  icon: const Icon(Icons.filter_alt),
                  label: const Text("Filter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade300,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Tabel Data
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text("DATA GRAFIK",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DataTable(
              columns: const [
                DataColumn(label: Text("DateTime")),
                DataColumn(label: Text("Flow")),
                DataColumn(label: Text("Pressure")),
                DataColumn(label: Text("Totalizer")),
              ],
              rows: tableData.map((data) {
                return DataRow(cells: [
                  DataCell(Text(data["datetime"]!)),
                  DataCell(Text(data["flow"]!)),
                  DataCell(Text(data["pressure"]!)),
                  DataCell(Text(data["totalizer"]!)),
                ]);
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Center(
          child: ElevatedButton(
            onPressed: () {
              // TODO: Tampilkan semua data
            },
            child: const Text("Tampilkan Semua"),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
