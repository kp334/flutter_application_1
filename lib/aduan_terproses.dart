import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'detail_cabang_slawi_page.dart';

class AduanTerprosesPage extends StatefulWidget {
  const AduanTerprosesPage({super.key});

  @override
  State<AduanTerprosesPage> createState() => _AduanTerprosesPageState();
}

class _AduanTerprosesPageState extends State<AduanTerprosesPage> {
  List<Map<String, dynamic>> dataAduan = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAduanData();
  }

  Future<void> fetchAduanData() async {
    const url = 'https://app.tirtaayu.com/api/dataaduan';
    try {
      final response = await http.get(Uri.parse(url));
      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'success') {
        final Map<String, dynamic> data = responseData['data'];
        final List<Map<String, dynamic>> aduanList = [];

        int index = 1;
        data.forEach((key, value) {
          aduanList.add({
            "no": index++,
            "cabang": value['nama_unit'],
            "jumlah": value['total'],
          });
        });

        setState(() {
          dataAduan = aduanList;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching data: $e');
    }
  }

  Widget buildTable() {
    return ListView(
      scrollDirection: Axis.vertical,
      children: [
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FlexColumnWidth(),
            2: FixedColumnWidth(110),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Colors.teal),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: Text("No", style: TextStyle(color: Colors.white))),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: Text("Cabang", style: TextStyle(color: Colors.white))),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: Text("Jumlah Aduan", style: TextStyle(color: Colors.white))),
                ),
              ],
            ),
            ...dataAduan.map((item) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Center(child: Text(item['no'].toString())),
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.all(20),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item['cabang'],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text("Jumlah Aduan: ${item['jumlah']}"),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (item['cabang'].toString().toLowerCase().contains("slawi")) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const DetailCabangSlawiPage(),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text("Detail", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(item['cabang'], style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Center(child: Text(item['jumlah'].toString())),
                  ),
                ],
              );
            }).toList(),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Aduan Pelanggan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Aduan Pelanggan Cabang (3 Bulan Berjalan)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : buildTable(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.teal[100],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Icon(Icons.mail, size: 28, color: Colors.black),
              Icon(Icons.home, size: 28, color: Colors.black),
              Icon(Icons.person, size: 28, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
