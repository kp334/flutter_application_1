import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> allErrorMessages = [];
  List<Map<String, dynamic>> allAlarmMessages = [];
  List<Map<String, dynamic>> filteredErrorMessages = [];
  List<Map<String, dynamic>> filteredAlarmMessages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
    _searchController.addListener(_filterMessages);
  }

  void _loadMessages() {
    allErrorMessages = [
      {
        "title": "Sensor Flow Bermasalah",
        "subtitle": "Zona Dukuhsalam tidak terdeteksi sejak 2 jam lalu",
        "datetime": "03 Juli 2025 14:30 WIB",
        "selected": false
      },
      {
        "title": "Pengukuran Gagal",
        "subtitle": "Zona Dukuhsalam Error data analitik",
        "datetime": "03 Juli 2025 10:00 WIB",
        "selected": false
      },
    ];

    allAlarmMessages = [
      {
        "title": "Pressure Turun",
        "subtitle": "Zona Dukuhsalam",
        "datetime": "01 Juli 2025 06:30 WIB",
        "selected": false
      },
      {
        "title": "Tinggi Muka Air Naik",
        "subtitle": "Zona Dukuhsalam",
        "datetime": "03 Juli 2025 09:00 WIB",
        "selected": false
      },
    ];

    _filterMessages();
  }

  void _filterMessages() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredErrorMessages = allErrorMessages.where((msg) {
        return msg['title'].toLowerCase().contains(query) ||
            msg['subtitle'].toLowerCase().contains(query);
      }).toList();

      filteredAlarmMessages = allAlarmMessages.where((msg) {
        return msg['title'].toLowerCase().contains(query) ||
            msg['subtitle'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _deleteSelectedMessages(bool isError) {
    setState(() {
      if (isError) {
        allErrorMessages.removeWhere((msg) => msg['selected']);
      } else {
        allAlarmMessages.removeWhere((msg) => msg['selected']);
      }
      _filterMessages();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pesan berhasil dihapus")),
    );
  }

  void _confirmDelete(bool isError) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Apakah Anda yakin ingin menghapus pesan ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tidak")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedMessages(isError);
            },
            child: const Text("Ya"),
          ),
        ],
      ),
    );
  }

  void _markAsRead(bool isError) {
    setState(() {
      var list = isError ? allErrorMessages : allAlarmMessages;
      for (var msg in list) {
        msg['selected'] = false;
      }
      _filterMessages();
    });
  }

  Widget _buildMessageList(List<Map<String, dynamic>> list, bool isError) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        var msg = list[index];
        return ListTile(
          leading: Checkbox(
            value: msg['selected'],
            onChanged: (val) {
              setState(() {
                msg['selected'] = val!;
              });
            },
          ),
          title: Text(msg['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(msg['subtitle']),
              Text(msg['datetime'], style: const TextStyle(color: Colors.grey)),
            ],
          ),
          trailing: Icon(
            isError ? Icons.error : Icons.warning_amber,
            color: isError ? Colors.red : Colors.orange,
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(bool isError) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: () => _confirmDelete(isError), child: const Text("Hapus Pesan")),
        ElevatedButton(
            onPressed: () => _markAsRead(isError), child: const Text("Tandai sudah dibaca")),
        ElevatedButton(
            onPressed: () => _loadMessages(), child: const Text("Refresh")),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        // Simulasi navigasi antar halaman
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Navigasi ke halaman ke-$index")),
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.mail), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesan"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Search...'),
                ),
              ),
              TabBar(
                controller: _tabController,
                onTap: (_) => _filterMessages(),
                tabs: const [
                  Tab(text: "ERROR"),
                  Tab(text: "ALARM"),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Expanded(child: _buildMessageList(filteredErrorMessages, true)),
              _buildBottomActions(true),
            ],
          ),
          Column(
            children: [
              Expanded(child: _buildMessageList(filteredAlarmMessages, false)),
              _buildBottomActions(false),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
