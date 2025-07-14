import 'package:flutter/material.dart';

class DetailCabangSlawiPage extends StatefulWidget {
  const DetailCabangSlawiPage({super.key});

  @override
  State<DetailCabangSlawiPage> createState() => _DetailCabangSlawiPageState();
}

class _DetailCabangSlawiPageState extends State<DetailCabangSlawiPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _aduanList = [
    {
      "judul": "Air Tidak Mengalir",
      "tanggal": "10 Juli 2025",
      "status": "Belum Dikerjakan",
      "sumber": "Langsung",
      "deskripsi":
          "Air tidak mengalir sejak tadi pagi di wilayah RT 04/RW 06. Mohon segera ditindaklanjuti karena berdampak ke seluruh rumah di lingkungan ini"
    },
    {
      "judul": "Perbaikan Stop Kran",
      "tanggal": "09 Juli 2025",
      "status": "Belum Dikerjakan",
      "sumber": "Langsung",
      "deskripsi":
          "Stop kran utama rusak dan tidak bisa ditutup. Air terus keluar dan menyebabkan pemborosan."
    },
    {
      "judul": "Kebocoran",
      "tanggal": "10 Juli 2025",
      "status": "Belum Dikerjakan",
      "sumber": "Langsung",
      "deskripsi":
          "Terdapat kebocoran pipa di belakang rumah warga. Air menyembur cukup deras."
    },
  ];

  List<Map<String, String>> _filteredAduan = [];

  @override
  void initState() {
    super.initState();
    _filteredAduan = List.from(_aduanList);
    _sortAduan();
    _searchController.addListener(_onSearchChanged);
  }

  void _sortAduan() {
    _filteredAduan.sort((a, b) {
      return (a['status'] == 'Sudah Dikerjakan' ? 1 : 0)
          .compareTo(b['status'] == 'Sudah Dikerjakan' ? 1 : 0);
    });
  }

  void _onSearchChanged() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      _filteredAduan = _aduanList.where((aduan) {
        final judul = aduan["judul"]?.toLowerCase() ?? "";
        return judul.contains(keyword);
      }).toList();
      _sortAduan(); // urutkan hasil pencarian juga
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail  Cabang Slawi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox("Total Aduan", _aduanList.length.toString()),
                _buildStatBox("Belum Dikerjakan",
                    _aduanList.where((e) => e['status'] == "Belum Dikerjakan").length.toString()),
                _buildStatBox("Sudah Dikerjakan",
                    _aduanList.where((e) => e['status'] == "Sudah Dikerjakan").length.toString()),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari Berdasarkan Jenis Aduan...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredAduan.isEmpty
                  ? const Center(child: Text("Tidak ada hasil ditemukan"))
                  : ListView.builder(
                      itemCount: _filteredAduan.length,
                      itemBuilder: (context, index) {
                        final aduan = _filteredAduan[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(aduan['judul']!,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 4),
                                    const Text("Slawi/Pusat"),
                                    const Spacer(),
                                    Text(aduan['tanggal']!),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text("Sumber : ${aduan['sumber']}"),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text("Status : "),
                                    Text(
                                      aduan["status"]!,
                                      style: TextStyle(
                                        color: aduan["status"] == "Belum Dikerjakan"
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () {
                                        _showDetailModal(aduan);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        side: const BorderSide(color: Colors.black),
                                      ),
                                      child: const Text("Lihat Detail"),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.teal[100],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.mail, size: 28, color: Colors.black),
            Icon(Icons.home, size: 28, color: Colors.black),
            Icon(Icons.person, size: 28, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showDetailModal(Map<String, String> aduan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final status = aduan["status"] ?? "";
        final isBelum = status == "Belum Dikerjakan";
        final statusColor = isBelum ? Colors.red : Colors.green;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Lihat Detail",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRow("Jenis Aduan", aduan["judul"]!),
                _buildRow("Tanggal", aduan["tanggal"]!),
                _buildRow("Cabang", "Slawi / Pusat"),
                _buildRow("Sumber Aduan", aduan["sumber"]!),
                _buildRow("Status", aduan["status"]!, statusColor),
                const SizedBox(height: 12),
                const Text(
                  "Deskripsi / Laporan Pengaduan",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    aduan["deskripsi"] ?? "-",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        aduan["status"] =
                            isBelum ? "Sudah Dikerjakan" : "Belum Dikerjakan";
                        _sortAduan(); // sortir ulang setelah perubahan status
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isBelum ? "Tandai Selesai" : "Tandai Belum Dikerjakan",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          const Text(" : "),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
