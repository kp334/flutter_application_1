import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class DataTablePage extends StatelessWidget {
  final String zoneName;
  final List<Map<String, dynamic>> data; // ✅ data dari luar

  const DataTablePage({
    super.key,
    required this.zoneName,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
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
                      _printPdf(context, data); // ✅ Cetak PDF dari data
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
                          child: Text("Level", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("Satuan", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("Min / Max", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    for (var item in data)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(item['tanggal']?.toString() ?? '-', textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(item['level']?['nilai']?.toString() ?? '-', textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(item['level']?['satuan']?.toString() ?? '-', textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              "${item['level']?['min'] ?? '-'} / ${item['level']?['max'] ?? '-'}",
                              textAlign: TextAlign.center,
                            ),
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
                headers: ['DateTime', 'Level', 'Satuan', 'Min / Max'],
                data: data.map((item) {
                  return [
                    item['tanggal']?.toString() ?? '-',
                    item['level']?['nilai']?.toString() ?? '-',
                    item['level']?['satuan']?.toString() ?? '-',
                    "${item['level']?['min'] ?? '-'} / ${item['level']?['max'] ?? '-'}",
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
