import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DetailCabangSlawiPage extends StatefulWidget {
  final String zoneId;
  final String zoneName;

  const DetailCabangSlawiPage({
    super.key,
    required this.zoneId,
    required this.zoneName,
  });

  @override
  State<DetailCabangSlawiPage> createState() => _DetailCabangSlawiPageState();
}

class _DetailCabangSlawiPageState extends State<DetailCabangSlawiPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _aduanList = [];
  List<Map<String, dynamic>> _filteredAduan = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAduan();
    _searchController.addListener(_onSearchChanged);
  }

  /// Panggil API sesuai zoneId
  Future<void> _fetchAduan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final url = Uri.parse(
        "https://app.tirtaayu.com/api/dataaduan/detail/${widget.zoneId}",
      );

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token.isNotEmpty) "Authorization": "Bearer $token",
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == "success" && decoded["data"] is List) {
          final List<dynamic> raw = decoded["data"];
          final list = raw
              .map<Map<String, dynamic>>((e) => {
                    // Normalisasi field sesuai API
                    "no_aduan": e["no_aduan"]?.toString() ?? "-",
                    "no_sr": e["no_sr"]?.toString() ?? "-",
                    "nama": e["nama"]?.toString() ?? "-",
                    "alamat": e["alamat"]?.toString() ?? "-",
                    "uraian": e["uraian"]?.toString() ?? "-",
                  })
              .toList();

          // Optional: urutkan berdasarkan no_aduan (desc)
          list.sort((a, b) => (b["no_aduan"] as String)
              .compareTo(a["no_aduan"] as String));

          setState(() {
            _aduanList = list;
            _filteredAduan = List.from(_aduanList);
          });
        } else {
          _showError("Data tidak ditemukan");
        }
      } else {
        _showError("Gagal memuat data dari server (${response.statusCode})");
      }
    } catch (e) {
      _showError("Terjadi kesalahan: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onSearchChanged() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      _filteredAduan = _aduanList.where((aduan) {
        final uraian = aduan["uraian"]?.toString().toLowerCase() ?? "";
        final nama = aduan["nama"]?.toString().toLowerCase() ?? "";
        final alamat = aduan["alamat"]?.toString().toLowerCase() ?? "";
        final noAduan = aduan["no_aduan"]?.toString().toLowerCase() ?? "";
        final noSr = aduan["no_sr"]?.toString().toLowerCase() ?? "";
        return uraian.contains(keyword) ||
            nama.contains(keyword) ||
            alamat.contains(keyword) ||
            noAduan.contains(keyword) ||
            noSr.contains(keyword);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final withSr = _aduanList.where((e) => (e['no_sr'] ?? '').toString().isNotEmpty && (e['no_sr'] ?? '-') != '-').length;
    final withoutSr = _aduanList.length - withSr;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Detail Cabang ${widget.zoneName}",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox("Total Aduan", _aduanList.length.toString()),
                      _buildStatBox("Dengan No SR", withSr.toString()),
                      _buildStatBox("Tanpa No SR", withoutSr.toString()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Cari nama/uraian/alamat/No Aduan/No SR...",
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
                              return _buildAduanCard(aduan);
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

Widget _buildAduanCard(Map<String, dynamic> aduan) {
  final uraian = aduan['uraian']?.toString() ?? '-';
  final nama = aduan['nama']?.toString() ?? '-';
  final alamat = aduan['alamat']?.toString() ?? '-';
  final noAduan = aduan['no_aduan']?.toString() ?? '-';
  final noSr = aduan['no_sr']?.toString() ?? '-';

  // Judul utama = No SR - Nama (kalau ada No SR)
  String judul = (noSr.isNotEmpty && noSr != '-')
      ? "$noSr - $nama"
      : nama;

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
          // Judul (No SR - Nama)
          Text(
            judul,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),

          // Lokasi (cabang) + No Aduan di kanan
          Row(
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.zoneName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(noAduan, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),

          // Uraian singkat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  uraian,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Alamat singkat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.home, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  alamat,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
                onPressed: () => _showDetailModal(aduan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                ),
                child: const Text("Lihat Detail"),
              ),
            ],
          ),
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

  void _showDetailModal(Map<String, dynamic> aduan) {
    final noAduan = aduan["no_aduan"]?.toString() ?? "-";
    final noSr = aduan["no_sr"]?.toString() ?? "-";
    final nama = aduan["nama"]?.toString() ?? "-";
    final alamat = aduan["alamat"]?.toString() ?? "-";
    final uraian = aduan["uraian"]?.toString() ?? "-";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Detail Aduan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),

                // Field yang diminta + disesuaikan ke respons API
                _buildRow("No. Aduan", noAduan),
                _buildRow("No. SR", noSr),
                _buildRow("Nama", nama),
                _buildRow("Alamat", alamat),
                _buildRow("Cabang", widget.zoneName),

                // Permintaan user: jenis aduan, tanggal, sumber, status, deskripsi/uraian
                _buildRow("Jenis Aduan", uraian),
                _buildRow("Tanggal", "-"), // tidak tersedia di API
                _buildRow("Sumber Aduan", "-"), // tidak tersedia di API
                _buildRow("Status", "-"), // tidak tersedia di API

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
                    uraian,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      "Tutup",
                      style: TextStyle(color: Colors.white),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
