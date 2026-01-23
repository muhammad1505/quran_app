import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final nextPrayer = prayerTimes.nextPrayer();
    final nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);

    return Scaffold(
      appBar: AppBar(title: const Text("Jadwal Sholat")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Highlight Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, const Color(0xFF0C4035)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            "Jakarta",
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Icon(Icons.location_on, color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Sholat Berikutnya",
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nextPrayer != Prayer.none 
                             ? DateFormat.Hm().format(nextPrayerTime!) 
                             : "Selesai",
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                        Text(
                           nextPrayer != Prayer.none 
                             ? _getPrayerName(nextPrayer)
                             : "Istirahat",
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // List Times
            _buildTimeRow("Subuh", prayerTimes.fajr, nextPrayer == Prayer.fajr),
            _buildTimeRow("Syuruq", prayerTimes.sunrise, nextPrayer == Prayer.sunrise),
            _buildTimeRow("Dzuhur", prayerTimes.dhuhr, nextPrayer == Prayer.dhuhr),
            _buildTimeRow("Ashar", prayerTimes.asr, nextPrayer == Prayer.asr),
            _buildTimeRow("Maghrib", prayerTimes.maghrib, nextPrayer == Prayer.maghrib),
            _buildTimeRow("Isya", prayerTimes.isha, nextPrayer == Prayer.isha),
          ],
        ),
      ),
    );
  }

  String _getPrayerName(Prayer p) {
    switch (p) {
      case Prayer.fajr: return "Subuh";
      case Prayer.sunrise: return "Syuruq";
      case Prayer.dhuhr: return "Dzuhur";
      case Prayer.asr: return "Ashar";
      case Prayer.maghrib: return "Maghrib";
      case Prayer.isha: return "Isya";
      default: return "-";
    }
  }

  Widget _buildTimeRow(String name, DateTime time, bool isNext) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isNext ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isNext ? Border.all(color: Theme.of(context).primaryColor, width: 1.5) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_filled, 
                size: 20, 
                color: isNext ? Theme.of(context).primaryColor : Colors.grey[400]
              ),
              const SizedBox(width: 16),
              Text(
                name, 
                style: GoogleFonts.poppins(
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                  color: isNext ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color
                )
              ),
            ],
          ),
          Text(
            DateFormat.Hm().format(time),
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isNext ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color
            ),
          ),
        ],
      ),
    );
  }
}
