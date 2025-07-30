import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'data_table_page.dart';

class GrafikPage extends StatefulWidget {
  final String zoneName;
  const GrafikPage({super.key, required this.zoneName});

  @override
  State<GrafikPage> createState() => _GrafikPageState();
}

class _GrafikPageState extends State<GrafikPage> {
  // Format input yang dipakai di UI
  final DateFormat inputFormat = DateFormat("dd-MM-yyyy HH:mm");

  // Controller tanggal awal/akhir
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  // Data mentah tabel (tanpa filter) & data setelah difilter
  List<Map<String, String>> allTableData = [];
  List<Map<String, String>> filteredData = [];

  // Titik-titik untuk chart
  List<FlSpot> flowSpots = [];
  List<FlSpot> totalizerSpots = [];

  // State UI
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startController.text =
        inputFormat.format(DateTime(now.year, now.month, now.day, 0, 0));
    endController.text =
        inputFormat.format(DateTime(now.year, now.month, now.day, 23, 59));
    fetchChartData();
  }

  // Helper agar hasil clamp bertipe double
  double _clampToDouble(num value, num lower, num upper) {
    return value.clamp(lower, upper).toDouble();
  }

  /// Parser tanggal yang lebih robust.
  DateTime? tryParseServerDate(String raw) {
    final candidates = <DateFormat>[
      DateFormat('dd-MM-yyyy HH:mm'),
      DateFormat('dd-MM-yyyy HH:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm'),
      DateFormat('yyyy-MM-dd HH:mm:ss'),
    ];

    // ISO 8601
    try {
      if (raw.contains('T')) return DateTime.parse(raw);
    } catch (_) {}

    for (final fmt in candidates) {
      try {
        return fmt.parseStrict(raw);
      } catch (_) {}
    }

    // Normalisasi "dd-MM-yyyy HH:mm(:ss)?" -> "yyyy-MM-ddTHH:mm(:ss)?"
    try {
      if (raw.contains(' ')) {
        final parts = raw.split(' ');
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          final normalized =
              '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}T${parts[1]}';
          return DateTime.parse(normalized);
        }
      }
    } catch (_) {}

    try {
      return DateTime.parse(raw);
    } catch (_) {}

    return null;
  }

  Future<void> fetchChartData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final encodedZone = Uri.encodeComponent(widget.zoneName.trim());
    final url = 'https://dev.tirtaayu.my.id/api/tekniks/device/$encodedZone';
    const token = 'Bearer 8|3acT1iWYizq86jljp8FGUmQwLHF6fGSqFQ1gXa3T94fd5111';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': token},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body is Map && body['data'] is List) {
          final List<dynamic> rawData = body['data'];

          allTableData = rawData.map<Map<String, String>>((entry) {
            final tanggal = entry["tanggal"]?.toString() ?? '';
            final flow = entry["flow"]?["nilai"]?.toString() ?? '0';
            final pressure = entry["pressure"]?["nilai"]?.toString() ?? '0';
            final totalizer = entry["totalizer"]?["nilai"]?.toString() ?? '0';
            return {
              "datetime": tanggal,
              "flow": flow,
              "pressure": pressure,
              "totalizer": totalizer,
            };
          }).toList();

          filterData();
        } else {
          errorMessage = 'Format respons tidak sesuai.';
        }
      } else {
        errorMessage = 'Gagal memuat data (HTTP ${response.statusCode}).';
      }
    } catch (e) {
      errorMessage = 'Terjadi kesalahan jaringan: $e';
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void filterData() {
    try {
      final startDate = inputFormat.parseStrict(startController.text);
      final endDate = inputFormat.parseStrict(endController.text);
      final endInclusive = endDate.add(const Duration(minutes: 1));

      final filtered = <Map<String, String>>[];

      for (final entry in allTableData) {
        final raw = entry['datetime'] ?? '';
        final parsed = tryParseServerDate(raw);
        if (parsed == null) continue;

        if (parsed.isAfter(startDate.subtract(const Duration(minutes: 1))) &&
            parsed.isBefore(endInclusive)) {
          filtered.add(entry);
        }
      }

      // Urutkan berdasarkan waktu
      filtered.sort((a, b) {
        final da = tryParseServerDate(a['datetime'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = tryParseServerDate(b['datetime'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });

      final newFlowSpots = <FlSpot>[];
      final newTotalizerSpots = <FlSpot>[];

      for (var i = 0; i < filtered.length; i++) {
        final f = double.tryParse(filtered[i]['flow'] ?? '0') ?? 0;
        final t = double.tryParse(filtered[i]['totalizer'] ?? '0') ?? 0;
        newFlowSpots.add(FlSpot(i.toDouble(), f));
        newTotalizerSpots.add(FlSpot(i.toDouble(), t / 100000)); // scaling
      }

      setState(() {
        filteredData = filtered;
        flowSpots = newFlowSpots;
        totalizerSpots = newTotalizerSpots;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Format tanggal salah. Gunakan: dd-MM-yyyy HH:mm"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestFlow =
        flowSpots.isNotEmpty ? flowSpots.last.y.toStringAsFixed(2) : "0.00";
    final latestPressure =
        filteredData.isNotEmpty ? (filteredData.last['pressure'] ?? '0.00') : '0.00';
    final latestTime =
        filteredData.isNotEmpty ? (filteredData.last['datetime'] ?? '') : '';

    // Hitung sumbu X & Y sebagai double murni (hindari num)
    final double maxX =
        _clampToDouble((filteredData.length - 1).toDouble(), 0.0, double.infinity);

    final double flowMax = flowSpots.isEmpty
        ? 1.0
        : flowSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final double flowMin = flowSpots.isEmpty
        ? 0.0
        : flowSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b);

    final double yMin = _clampToDouble(flowMin * 0.9, 0.0, double.infinity);
    final double yMax = _clampToDouble(flowMax * 1.1, 1.0, double.infinity);

    final double xInterval = filteredData.isEmpty
        ? 1.0
        : _clampToDouble(filteredData.length / 6, 1.0, 6.0);

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
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: fetchChartData,
            icon: const Icon(Icons.refresh, color: Colors.black),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: fetchChartData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bagian Info Terbaru
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  latestFlow,
                                  style: const TextStyle(
                                      fontSize: 32, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                const Text("L/s", style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  latestPressure,
                                  style: const TextStyle(
                                      fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                const Text("Bar", style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("Update $latestTime",
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Grafik Line Chart
                      SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: LineChart(
                            LineChartData(
                              minX: 0.0,
                              maxX: maxX,
                              minY: yMin,
                              maxY: yMax,
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  axisNameWidget:
                                      const Text('Totalizer (dibagi 100k)'),
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 44,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  axisNameWidget: const Text('Flow (L/s)'),
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: xInterval,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx >= 0 && idx < filteredData.length) {
                                        final dt = filteredData[idx]['datetime'] ?? '';
                                        final time = dt.contains(' ')
                                            ? dt.split(' ').last
                                            : dt;
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            time,
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                // Flow
                                LineChartBarData(
                                  spots: flowSpots,
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 2,
                                  dotData: FlDotData(show: false),
                                ),
                                // Totalizer (dibagi 100k biar skala enak)
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
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          LegendItem(color: Colors.blue, text: 'Flow'),
                          SizedBox(width: 16),
                          LegendItem(color: Colors.purple, text: 'Totalizer / 100k'),
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
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
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
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tabel Data Grafik
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "DATA GRAFIK",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
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
                                  child: Text(
                                    "DateTime",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    "Flow",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    "Pressure",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    "Totalizer",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            for (var data in filteredData)
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      data["datetime"]!,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      data["flow"]!,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      data["pressure"]!,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      data["totalizer"]!,
                                      textAlign: TextAlign.center,
                                    ),
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
                                builder: (context) =>
                                    DataTablePage(zoneName: widget.zoneName),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
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
