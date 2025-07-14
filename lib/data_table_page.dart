import 'package:flutter/material.dart';

class DataTablePage extends StatelessWidget {
  final String zoneName;
  const DataTablePage({super.key, required this.zoneName});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> data = [
      {"datetime": "2025-07-03", "flow": 3.89, "pressure": 0.0, "totalizer": 382345},
      {"datetime": "2025-07-03", "flow": 3.92, "pressure": 0.0, "totalizer": 382346},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(zoneName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Integrasi ekspor (PDF, CSV, PNG, XLS)
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Fitur $value belum diimplementasi")));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'print', child: Text("Print Chart")),
              const PopupMenuItem(value: 'pdf', child: Text("Download PDF")),
              const PopupMenuItem(value: 'img', child: Text("Download PNG, JPEG")),
              const PopupMenuItem(value: 'csv', child: Text("Download CSV, XLS")),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('DateTime')),
            DataColumn(label: Text('Flow')),
            DataColumn(label: Text('Pressure')),
            DataColumn(label: Text('Totalizer')),
          ],
          rows: data.map((e) {
            return DataRow(cells: [
              DataCell(Text(e['datetime'])),
              DataCell(Text(e['flow'].toString())),
              DataCell(Text(e['pressure'].toString())),
              DataCell(Text(e['totalizer'].toString())),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
