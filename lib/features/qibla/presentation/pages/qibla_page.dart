import 'package:flutter/material.dart';
import 'package:smooth_compass/utils/src/compass_ui.dart';
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
          : Center(
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
                    child: SmoothCompass(
                      rotationSpeed: 200,
                      height: 300,
                      width: 300,
                      isQiblaCompass: false,
                      compassBuilder: (context, snapshot, child) {
                        // Adjust rotation so Qibla (0 degrees in UI terms) points up
                        // If _qiblaDirection is e.g. 295, we want the needle to point to 295.
                        // snapshot.data is the device heading.

                        // Simple Compass Logic:
                        // Needle should rotate to: Qibla Direction - Device Heading
                        return AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns:
                              (_qiblaDirection! -
                                  (snapshot?.data?.angle ?? 0)) /
                              360,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Compass Background
                              Container(
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
                              // Qibla Needle
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 50,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
