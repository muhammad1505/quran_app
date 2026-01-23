import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  String _locationName = "Mencari Lokasi...";
  PrayerTimes? _prayerTimes;
  Prayer? _nextPrayer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocationAndPrayers();
  }

  Future<void> _initLocationAndPrayers() async {
    try {
      // 1. Permission Check
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        setState(() {
          _locationName = "Izin Lokasi Ditolak";
          _isLoading = false;
        });
        return;
      }

      // 2. Get GPS Position (with distance filter for battery saving in future updates)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // 3. Reverse Geocoding (Get City Name)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          setState(() {
            _locationName = "${place.subAdministrativeArea ?? place.locality}, ${place.country}";
          });
        }
      } catch (e) {
        setState(() {
          _locationName = "Koordinat: ${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
        });
      }

      // 4. Calculate Prayer Times
      final myCoordinates = Coordinates(position.latitude, position.longitude);
      
      // Use Singapore method as base but customize for Indonesia (Kemenag-like)
      // Kemenag standard: Subuh 20 deg, Isya 18 deg. 
      // Singapore uses 20, 18. So it is very close.
      final params = CalculationMethod.singapore.getParameters();
      params.madhab = Madhab.shafi;
      
      final now = DateTime.now();
      final prayerTimes = PrayerTimes.today(myCoordinates, params);
      
      setState(() {
        _prayerTimes = prayerTimes;
        _nextPrayer = prayerTimes.nextPrayer();
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _locationName = "Gagal memuat lokasi";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If loading or error
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_prayerTimes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text("Gagal menghitung jadwal sholat", style: GoogleFonts.poppins()),
            TextButton(onPressed: _initLocationAndPrayers, child: const Text("Coba Lagi"))
          ],
        ),
      );
    }

    final nextPrayerTime = _prayerTimes!.timeForPrayer(_nextPrayer ?? Prayer.none);

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
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              _locationName,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
                          _nextPrayer != Prayer.none 
                             ? DateFormat.Hm().format(nextPrayerTime!) 
                             : "Selesai",
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                        Text(
                           _nextPrayer != Prayer.none 
                             ? _getPrayerName(_nextPrayer!)
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
            _buildTimeRow("Subuh", _prayerTimes!.fajr, _nextPrayer == Prayer.fajr),
            _buildTimeRow("Syuruq", _prayerTimes!.sunrise, _nextPrayer == Prayer.sunrise),
            _buildTimeRow("Dzuhur", _prayerTimes!.dhuhr, _nextPrayer == Prayer.dhuhr),
            _buildTimeRow("Ashar", _prayerTimes!.asr, _nextPrayer == Prayer.asr),
            _buildTimeRow("Maghrib", _prayerTimes!.maghrib, _nextPrayer == Prayer.maghrib),
            _buildTimeRow("Isya", _prayerTimes!.isha, _nextPrayer == Prayer.isha),
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
        color: isNext ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).cardTheme.color ?? Colors.white,
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