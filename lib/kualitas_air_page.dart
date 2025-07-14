import 'package:flutter/material.dart';
import 'message_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class KualitasAirPage extends StatelessWidget {
  const KualitasAirPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
        title: const Text('Kualitas Air'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Tambahkan logika refresh jika menggunakan data dinamis
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data berhasil diperbarui')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2)),
            ],
          ),
          child: Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: const [
              TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('#', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Chlorine Analyzer Res.\nTimbangreja',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Chlorine Analyzer Bedug',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: Colors.black12),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('pH Air Baku', style: TextStyle(color: Colors.white)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('0.00', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('7.15', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Sisa Klor', style: TextStyle(color: Colors.white)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('0.00', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('0.45', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  ),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: Colors.black12),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Update Terakhir', style: TextStyle(color: Colors.white)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('24/05/2024\n13:34', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('10/07/2024\n11:11', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.lightBlue[100],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: 1, // Karena halaman ini di tengah
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MessagePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
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
