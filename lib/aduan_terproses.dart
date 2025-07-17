import 'package:flutter/material.dart';
import 'detail_cabang_slawi_page.dart'; // Import halaman detail

class AduanTerprosesPage extends StatelessWidget {
  const AduanTerprosesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dataAduan = [
      {"no": 1, "cabang": "Slawi / Pusat", "jumlah": 10},
      {"no": 2, "cabang": "Cabang Mejasem", "jumlah": 0},
      {"no": 3, "cabang": "Spam Pantura", "jumlah": 2},
      {"no": 4, "cabang": "Cabang Balapulang / Lebaksiu", "jumlah": 0},
      {"no": 5, "cabang": "Cabang Bojong", "jumlah": 0},
      {"no": 6, "cabang": "Cabang Jatinegara", "jumlah": 0},
      {"no": 7, "cabang": "Cabang Warureja", "jumlah": 0},
      {"no": 8, "cabang": "Cabang Pagerbarang", "jumlah": 1},
      {"no": 9, "cabang": "Cabang Margasari", "jumlah": 1},
      {"no": 10, "cabang": "Lain - lain", "jumlah": 0},
    ];

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
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade400),
                  columnWidths: const {
                    0: FixedColumnWidth(40),
                    1: FlexColumnWidth(),
                    2: FixedColumnWidth(100),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade800),
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.all(20),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item['cabang'],
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        Text("Jumlah Aduan : ${item['jumlah']}"),
                                        const SizedBox(height: 20),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.lightBlueAccent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            if (item['cabang'] == "Slawi / Pusat") {
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
                              child: Center(
                                child: Text(item['cabang'], style: const TextStyle(fontSize: 13)),
                              ),
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
                ),
              ),
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