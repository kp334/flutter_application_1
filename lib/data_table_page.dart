import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class DataTablePage extends StatelessWidget {
  final String zoneName;
  const DataTablePage({super.key, required this.zoneName});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> data = [
      {"datetime": "2025-07-02 00:12", "flow": 3.93, "pressure": 0.0, "totalizer": 382347},
      {"datetime": "2025-07-02 01:17", "flow": 3.89, "pressure": 0.0, "totalizer": 382351},
      {"datetime": "2025-07-02 03:23", "flow": 3.92, "pressure": 0.0, "totalizer": 382355},
      {"datetime": "2025-07-02 10:10", "flow": 3.75, "pressure": 0.0, "totalizer": 382360},
      {"datetime": "2025-07-02 22:00", "flow": 3.70, "pressure": 0.0, "totalizer": 382370},
      {"datetime": "2025-07-02 10:35", "flow": 3.77, "pressure": 0.0, "totalizer": 382362},
      {"datetime": "2025-07-02 13:58", "flow": 3.75, "pressure": 0.0, "totalizer": 382368},
      {"datetime": "2025-07-02 13:41", "flow": 3.62, "pressure": 0.0, "totalizer": 382370},
      {"datetime": "2025-07-02 13:54", "flow": 3.60, "pressure": 0.0, "totalizer": 382373},
      {"datetime": "2025-07-02 20:47", "flow": 3.58, "pressure": 0.0, "totalizer": 382376},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ZONA $zoneName".toUpperCase(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                const Text(
                  "DATA GRAFIK",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onSelected: (value) {
                    if (value == 'print') {
                      _printPdf(context, data); // ✅ Fungsi cetak dipanggil
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Fitur $value belum diimplementasi")),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'print', child: Text("Print Chart")),
                    PopupMenuItem(value: 'pdf', child: Text("Download PDF")),
                    PopupMenuItem(value: 'img', child: Text("Download PNG, JPEG")),
                    PopupMenuItem(value: 'csv', child: Text("Download CSV, XLS")),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
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
                    for (var item in data)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(item['datetime'], textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(item['flow'].toString(), textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(item['pressure'].toString(), textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(item['totalizer'].toString(), textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Fungsi Print PDF
  void _printPdf(BuildContext context, List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Data Grafik Zona $zoneName',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['DateTime', 'Flow', 'Pressure', 'Totalizer'],
                data: data.map((item) {
                  return [
                    item['datetime'],
                    item['flow'].toString(),
                    item['pressure'].toString(),
                    item['totalizer'].toString(),
                  ];
                }).toList(),
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0F2F1)),
                cellAlignment: pw.Alignment.center,
                cellPadding: const pw.EdgeInsets.all(6),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
