import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'data_grafik_page.dart';

class DetailZonePage extends StatefulWidget {
  final String zoneName;
  final String serialId; // tiap zona ada serial unik

  const DetailZonePage({
    super.key,
    required this.zoneName,
    required this.serialId,
  });

  @override
  State<DetailZonePage> createState() => _DetailZonePageState();
}

class _DetailZonePageState extends State<DetailZonePage> {
  List<dynamic> logData = [];
  String? title;
  String? tanggalAwal;
  String? tanggalAkhir;
  bool isLoading = false;
  final awalController = TextEditingController();
  final akhirController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // default tanggal (hari ini)
    final now = DateTime.now();
    awalController.text = DateFormat("dd-MM-yyyy HH:mm").format(now.subtract(const Duration(hours: 12)));
    akhirController.text = DateFormat("dd-MM-yyyy HH:mm").format(now);

    fetchLoggerData();
  }

  Future<void> fetchLoggerData() async {
    setState(() => isLoading = true);

    try {
      final url =
          "https://dev.tirtaayu.my.id/api/tekniks/detail/${widget.serialId}?awal=${awalController.text}&akhir=${akhirController.text}";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        setState(() {
          logData = jsonData["data"]["log"];
          title = jsonData["data"]["title"];
          tanggalAwal = jsonData["data"]["tanggal"][0];
          tanggalAkhir = jsonData["data"]["tanggal"][1];
        });
      }
    } catch (e) {
      debugPrint("Error fetch: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> pickDateTime(TextEditingController controller) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        final fullDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        controller.text = DateFormat("dd-MM-yyyy HH:mm").format(fullDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe0f6f4),
      appBar: AppBar(
        backgroundColor: const Color(0xffd0f0ec),
        title: Text(widget.zoneName, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FLOW terakhir
                  if (logData.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              logData.first["data"].last[1],
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            const Text("L/s", style: TextStyle(fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text("0.00", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            SizedBox(width: 6),
                            Text("Bar", style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),
                  if (tanggalAwal != null && tanggalAkhir != null)
                    Text("Update $tanggalAkhir",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

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
                    child: GrafikPage(zoneName: widget.zoneName),
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
                    children: [
                      Expanded(
                        child: TextField(
                          controller: awalController,
                          readOnly: true,
                          onTap: () => pickDateTime(awalController),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: akhirController,
                          readOnly: true,
                          onTap: () => pickDateTime(akhirController),
                          decoration: const InputDecoration(
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
                      onPressed: fetchLoggerData,
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
                      ],
                      rows: logData.isNotEmpty
                          ? logData.expand((log) => log["data"]).map<DataRow>((row) {
                              final timestamp = DateTime.fromMillisecondsSinceEpoch(row[0]);
                              final formatted = DateFormat("yyyy-MM-dd HH:mm").format(timestamp);
                              return DataRow(cells: [
                                DataCell(Text(formatted)),
                                DataCell(Text(row[1].toString())),
                              ]);
                            }).toList()
                          : [],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigasi ke halaman tabel penuh
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullDataPage(
                              zoneName: widget.zoneName,
                              serialId: widget.serialId,
                              awal: awalController.text,
                              akhir: akhirController.text,
                            ),
                          ),
                        );
                      },
                      child: const Text("Tampilkan Semua"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Contoh halaman data penuh
class FullDataPage extends StatelessWidget {
  final String zoneName;
  final String serialId;
  final String awal;
  final String akhir;

  const FullDataPage({
    super.key,
    required this.zoneName,
    required this.serialId,
    required this.awal,
    required this.akhir,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Data Lengkap $zoneName")),
      body: Center(child: Text("Load tabel lengkap dari API serial $serialId\n$awal - $akhir")),
    );
  }
}
