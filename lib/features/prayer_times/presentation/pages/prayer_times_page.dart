import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  @override
  Widget build(BuildContext context) {
    // Jakarta Coordinates
    final myCoordinates = Coordinates(-6.2088, 106.8456); 
    final params = CalculationMethod.singapore.getParameters();
    params.madhab = Madhab.shafi;
    final prayerTimes = PrayerTimes.today(myCoordinates, params);

    return Scaffold(
      appBar: AppBar(title: const Text("Jadwal Sholat (Jakarta)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Hari Ini", style: Theme.of(context).textTheme.titleLarge),
                    Text(DateFormat('EEEE, d MMMM y').format(DateTime.now())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTimeTile("Subuh", prayerTimes.fajr, Icons.wb_twilight),
            _buildTimeTile("Syuruq", prayerTimes.sunrise, Icons.wb_sunny_outlined),
            _buildTimeTile("Dzuhur", prayerTimes.dhuhr, Icons.wb_sunny),
            _buildTimeTile("Ashar", prayerTimes.asr, Icons.wb_cloudy),
            _buildTimeTile("Maghrib", prayerTimes.maghrib, Icons.nights_stay_outlined),
            _buildTimeTile("Isya", prayerTimes.isha, Icons.nights_stay),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(String name, DateTime time, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          DateFormat.Hm().format(time),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
