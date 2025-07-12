import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'flow_logger_page.dart';
import 'message_page.dart';
import 'profile_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 1;
  late Timer _timer;
  DateTime _now = DateTime.now();

  final List<String> _reservoirNames = [
    'Reservoir Bag. Wangon',
    'Reservoir Pacul',
    'Reservoir Cilongok',
    'Reservoir Ajibarang',
    'Reservoir Kalibagor',
    'Reservoir Rawalo',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isCompact = size.width <= 412;
    final double vSpacing = isCompact ? 8 : 12;
    final double levelCardWidth = isCompact ? 100 : 120;

    final String dateStr = DateFormat('d/M/yyyy').format(_now);
    final String timeStr = DateFormat('HH:mm:ss').format(_now);

    return Scaffold(
      drawer: const _SideDrawer(),
      appBar: AppBar(
        title: const Text('Monitoring - SCADA', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Expanded(
                  child: _InfoCard(
                    color: Colors.blue,
                    icon: Icons.location_on,
                    label: 'Zona',
                    value: '20',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _InfoCard(
                    color: Colors.blue,
                    icon: Icons.speed,
                    label: 'SR',
                    value: '60.213',
                  ),
                ),
              ]),
              SizedBox(height: vSpacing),
              Row(children: [
                const Expanded(
                  child: _InfoCard(
                    color: Colors.amber,
                    icon: Icons.report,
                    label: 'Total Aduan',
                    value: '12',
                    textColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoCard(
                    color: Colors.redAccent,
                    icon: Icons.access_time,
                    label: dateStr,
                    value: timeStr,
                  ),
                ),
              ]),
              SizedBox(height: vSpacing * 2),
              const Text('Level Air', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: vSpacing),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _reservoirNames.length,
                  itemBuilder: (_, index) => _LevelCard(
                    title: _reservoirNames[index],
                    width: levelCardWidth,
                    value: (index + 1) / (_reservoirNames.length + 1),
                  ),
                ),
              ),
              SizedBox(height: vSpacing * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Flow Logger', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 140,
                    height: 30,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: vSpacing),
              const _FlowLoggerCard(),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const FlowLoggerScreen()),
                    );
                  },
                  child: const Text('Lihat Semua'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: _navIndex,
  onTap: (i) {
    setState(() => _navIndex = i);
    switch (i) {
      case 0:
        // Navigasi ke halaman pesan
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessagePage()),
        );
        break;
      case 1:
        // Halaman utama
        break;
      case 2:
        // Navigasi ke halaman profil
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  },
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.mail), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
  ],
),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final Color? textColor;

  const _InfoCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: fg, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String title;
  final double width;
  final double value;

  const _LevelCard({
    required this.title,
    required this.width,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          Expanded(child: Center(child: _VerticalGauge(value: value))),
          const SizedBox(height: 4),
          const Text('No. Indicator', style: TextStyle(fontSize: 10)),
          const SizedBox(height: 2),
          Container(
            height: 18,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Timestamp', style: TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }
}

class _VerticalGauge extends StatelessWidget {
  final double value;
  const _VerticalGauge({required this.value});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: -1,
      child: LinearProgressIndicator(
        value: value,
        minHeight: 14,
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
      ),
    );
  }
}

class _FlowLoggerCard extends StatelessWidget {
  const _FlowLoggerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.place, size: 14, color: Colors.blue),
              SizedBox(width: 4),
              Text('ZONA DUKUHSALAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          SizedBox(height: 6),
          _FlowLoggerInfo(label: 'Flow', value: '2.57 L/s (< Min 3.5)'),
          _FlowLoggerInfo(label: 'Bar', value: '0.00'),
          _FlowLoggerInfo(label: 'Update Terakhir', value: '02/07/2025, 11:45'),
          SizedBox(height: 4),
          Chip(label: Text('Normal', style: TextStyle(fontSize: 10)), backgroundColor: Colors.greenAccent),
        ],
      ),
    );
  }
}

class _FlowLoggerInfo extends StatelessWidget {
  final String label;
  final String value;

  const _FlowLoggerInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Text('$label : ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }
}

class _SideDrawer extends StatelessWidget {
  const _SideDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Row(
              children: const [
                CircleAvatar(radius: 30, child: Icon(Icons.person)),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Admin SCADA', style: TextStyle(color: Colors.white)),
                    Text('admin@email.com', style: TextStyle(color: Colors.white70)),
                  ],
                )
              ],
            ),
          ),
          const ListTile(leading: Icon(Icons.dashboard), title: Text('Dashboard')),
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text('Flow Logger'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FlowLoggerScreen()),
              );
            },
          ),
          const ListTile(leading: Icon(Icons.science), title: Text('Kualitas Air')),
          const ListTile(leading: Icon(Icons.speed), title: Text('Pressure Logger')),
          const ListTile(leading: Icon(Icons.water), title: Text('Level Air')),
          const ListTile(leading: Icon(Icons.report), title: Text('Aduan Terproses')),
          const Divider(),
          const ListTile(leading: Icon(Icons.logout), title: Text('Logout')),
        ],
      ),
    );
  }
}
