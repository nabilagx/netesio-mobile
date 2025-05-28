import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getRiwayatStream() {
    return _dbRef.child('riwayat_suhu_kelembaban').orderByChild('timestamp').limitToLast(50).onValue;
  }

  Future<void> updateDurasiInkubasi(int hari) async {
    await _dbRef.child('durasi_inkubasi').set(hari);
  }

  Future<void> updateJadwalRotasi(int jam) async {
    await _dbRef.child('jadwal_rotasi').set(jam);
  }

  Future<void> updateJenisKelamin(String jenis) async {
    await _dbRef.child('jenis_kelamin').set(jenis);
  }

  Future<Map<String, dynamic>?> getSettingsOnce() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }
}
