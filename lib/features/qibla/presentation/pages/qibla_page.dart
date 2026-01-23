import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double? _qiblaDirection;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndCalculateQibla();
  }

  Future<void> _checkPermissionAndCalculateQibla() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      final position = await Geolocator.getCurrentPosition();
      final coordinates = Coordinates(position.latitude, position.longitude);
      final qibla = Qibla(coordinates);
      setState(() {
        _qiblaDirection = qibla.direction;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi diperlukan untuk arah kiblat'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Arah Kiblat")),
      body: !_hasPermission
          ? Center(
              child: ElevatedButton(
                onPressed: _checkPermissionAndCalculateQibla,
                child: const Text('Izinkan Lokasi'),
              ),
            )
          : _qiblaDirection == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<CompassEvent>(
              stream: FlutterCompass.events,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error reading heading: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                double? direction = snapshot.data?.heading;

                    // if direction is null, then device does not support this sensor
                    if (direction == null) {
                      return const Center(child: Text("Device does not support sensors"));
                    }

                    return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Arah Ka'bah",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${_qiblaDirection!.toStringAsFixed(1)}°",
                        style: GoogleFonts.poppins(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 300,
                        width: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Static Compass Dial (Background) - Rotates with device
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns:
                                  -direction /
                                  360, // Rotate opposite to device heading to keep North up?
                              // No, typically dial moves. Let's make the needle move to Qibla relative to North.
                              // Approach: Rotate everything so North is UP (0), then show Qibla relative to North.
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).cardTheme.color,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.compass_calibration_outlined,
                                  size: 280,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                            ),

                            // Qibla Needle - Rotates to point to Qibla relative to device heading
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: (_qiblaDirection! - direction) / 360,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 50,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 100), // Pivot offset
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              "Akurasi Kompas: ${snapshot.data?.accuracy ?? 'Unknown'}",
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
