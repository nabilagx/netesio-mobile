import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dbRef = FirebaseDatabase.instance.ref();
  double suhu = 0.0;
  double kelembaban = 0.0;
  List<FlSpot> suhuData = [];
  List<FlSpot> kelembabanData = [];
  List<Map<String, dynamic>> riwayat = [];

  bool relay1 = false;
  bool relay2 = false;


  int durasiInkubasi = 0;
  int jadwalRotasi = 0;
  String jenisKelamin = '';

  final List<int> rotasiOptions = [1, 3, 4, 6, 8];
  final List<String> genderOptions = ['jantan', 'seimbang', 'betina'];

  @override
  void initState() {
    super.initState();
    // listen realtime changes
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          // update semua variabel dari data
          durasiInkubasi = data['durasi_inkubasi'] ?? 0;
          jadwalRotasi = data['jadwal_rotasi'] ?? 0;
          jenisKelamin = data['jenis_kelamin'] ?? '';

          relay1 = data['status_devices']?['relay1'] ?? false;

          relay2 = data['status']?['relay2'] ?? false;

          final rawRiwayat = data['riwayat'] as Map?;
          if (rawRiwayat != null) {
            riwayat = rawRiwayat.entries.map((e) {
              final val = Map<String, dynamic>.from(e.value);
              return {
                'timestamp': val['timestamp'] ?? 0, // ambil dari value, bukan key
                'suhu': (val['suhu'] ?? 0).toDouble(),
                'kelembaban': (val['kelembaban'] ?? 0).toDouble(),
              };
            }).toList();

            // Tampilkan data terbaru di atas
            riwayat.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

            if (riwayat.length > 20) riwayat = riwayat.sublist(0, 20);


            suhuData = [];
            kelembabanData = [];
            for (int i = 0; i < riwayat.length; i++) {
              suhuData.add(FlSpot(i.toDouble(), riwayat[riwayat.length - 1 - i]['suhu']));
              kelembabanData.add(FlSpot(i.toDouble(), riwayat[riwayat.length - 1 - i]['kelembaban']));
            }

            if (riwayat.isNotEmpty) {
              suhu = riwayat[0]['suhu'];
              kelembaban = riwayat[0]['kelembaban'];
            }
          }
        });
      }
    });
  }


  Future<void> fetchData() async {
    final snapshot = await dbRef.get();
    final data = snapshot.value as Map?;

    if (data == null) return;

    setState(() {
      durasiInkubasi = data['durasi_inkubasi'] ?? 0;
      jadwalRotasi = data['jadwal_rotasi'] ?? 0;
      jenisKelamin = data['jenis_kelamin'] ?? '';

      relay1 = data['status_devices']?['relay1'] ?? false;

      relay2 = data['status']?['relay2'] ?? false;

      final rawRiwayat = data['riwayat'] as Map?;
      if (rawRiwayat != null) {
        riwayat = rawRiwayat.entries.map((e) {
          final val = Map<String, dynamic>.from(e.value);
          return {
            'timestamp': int.tryParse(e.key.toString()) ?? 0,
            'suhu': (val['suhu'] ?? 0).toDouble(),
            'kelembaban': (val['kelembaban'] ?? 0).toDouble(),
          };
        }).toList();

        riwayat.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
        if (riwayat.length > 20) riwayat = riwayat.sublist(0, 20);

        suhuData = [];
        kelembabanData = [];
        for (int i = 0; i < riwayat.length; i++) {
          suhuData.add(FlSpot(i.toDouble(), riwayat[riwayat.length - 1 - i]['suhu']));
          kelembabanData.add(FlSpot(i.toDouble(), riwayat[riwayat.length - 1 - i]['kelembaban']));
        }

        if (riwayat.isNotEmpty) {
          suhu = riwayat[0]['suhu'];
          kelembaban = riwayat[0]['kelembaban'];
        }
      }
    });
  }

  void updateFirebase(String key, dynamic value) {
    dbRef.update({key: value});
    // Setelah update, refresh data
    fetchData();
  }

  Widget buildDeviceStatusCard(String title, bool isOn, IconData icon) {
    return Card(
      color: isOn ? Colors.green[100] : Colors.red[100],
      child: ListTile(
        leading: Icon(icon, color: isOn ? Colors.green : Colors.red),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOn ? Colors.green[900] : Colors.red[900],
          ),
        ),
        trailing: Text(
          isOn ? 'ON' : 'OFF',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOn ? Colors.green[900] : Colors.red[900],
          ),
        ),
      ),
    );
  }

  Widget buildGraphCard(String title, List<FlSpot> data, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 150,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data,
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOptionChips<T>({
    required String title,
    required List<T> options,
    required T selectedValue,
    required Function(T) onSelected,
    required String Function(T) label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return ChoiceChip(
              label: Text(label(option)),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              selectedColor: Colors.blueAccent,
              backgroundColor: Colors.grey[300],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void hapusRiwayat() {
    dbRef.child('riwayat').remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat berhasil dihapus')),
      );
      fetchData();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus riwayat: $error')),
      );
    });
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void showInputDialog(BuildContext context, String title, String key, int initial) {
    TextEditingController controller = TextEditingController(text: initial.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Atur $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Masukkan angka'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              int? val = int.tryParse(controller.text);
              if (val != null) {
                updateFirebase(key, val);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NETES.IO Monitoring')),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            const DrawerHeader(
              child: Text('Pengaturan Inkubasi', style: TextStyle(fontSize: 20)),
            ),
            ListTile(
              title: const Text('Durasi Inkubasi'),
              subtitle: Text('$durasiInkubasi hari'),
              onTap: () => showInputDialog(context, 'Durasi Inkubasi', 'durasi_inkubasi', durasiInkubasi),
            ),
            buildOptionChips<int>(
              title: 'Jadwal Rotasi (Jam)',
              options: rotasiOptions,
              selectedValue: jadwalRotasi,
              onSelected: (val) => updateFirebase('jadwal_rotasi', val),
              label: (val) => val == 1 ? '3 menit' : '$val jam',

            ),
            buildOptionChips<String>(
              title: 'Jenis Kelamin Target',
              options: genderOptions,
              selectedValue: jenisKelamin,
              onSelected: (val) => updateFirebase('jenis_kelamin', val),
              label: (val) => val.toUpperCase(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.blue[50],
              child: ListTile(
                title: const Text('Suhu Saat Ini'),
                subtitle: Text('${suhu.toStringAsFixed(1)} °C', style: const TextStyle(fontSize: 20)),
              ),
            ),
            Card(
              color: Colors.teal[50],
              child: ListTile(
                title: const Text('Kelembaban Saat Ini'),
                subtitle: Text('${kelembaban.toStringAsFixed(1)} %', style: const TextStyle(fontSize: 20)),
              ),
            ),
            buildGraphCard('Grafik Suhu', suhuData, Colors.red),
            buildGraphCard('Grafik Kelembaban', kelembabanData, Colors.blue),
            ElevatedButton.icon(
              onPressed: hapusRiwayat,
              icon: const Icon(Icons.delete),
              label: const Text('Hapus Riwayat'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            ),
            const Divider(),
            buildDeviceStatusCard('Status Relay 1 (Rotasi)', relay1, Icons.autorenew),
            buildDeviceStatusCard('Status Relay 2 (Lampu)', relay2, Icons.lightbulb),

            const Divider(),
            const Text('Riwayat Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...riwayat.map((entry) {
              return Card(
                child: ListTile(
                  title: Text('Suhu: ${entry['suhu']} °C, Kelembaban: ${entry['kelembaban']} %'),
                  subtitle: Text('Waktu: ${DateTime.fromMillisecondsSinceEpoch(entry['timestamp']).toLocal()}'),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }
}
